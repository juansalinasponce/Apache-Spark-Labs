# %% [markdown]
# # ETL Bronze a Silver con PySpark
#
# Este es el único notebook de transformación del laboratorio. El código está
# dividido en pasos cortos para mostrar limpieza, tipificación, deduplicación y
# conservación del historial del cliente.

# %%
from datetime import datetime, timezone

from delta.tables import DeltaTable
from pyspark.sql import functions as F
from pyspark.sql.window import Window


fecha_proceso = datetime.now(timezone.utc).replace(tzinfo=None)
vigencia_abierta = datetime(9999, 12, 31, 23, 59, 59, 999999)


# %% [markdown]
# ## 1. Limpiar y tipificar clientes

# %%
cliente_bronze = spark.table("brz.banco_cliente")

cliente_limpio = cliente_bronze.select(
    F.col("id_cliente").cast("int").alias("id_cliente"),
    F.upper(F.trim("tipo_documento")).alias("tipo_documento"),
    F.trim("nro_documento").alias("nro_documento"),
    F.trim("nombre_completo").alias("nombre_completo"),
    F.upper(F.trim("tipo_cliente")).alias("tipo_cliente"),
    F.upper(F.trim("segmento")).alias("segmento"),
    F.col("fecha_registro").cast("date").alias("fecha_registro"),
    F.lower(F.trim("email")).alias("email"),
    F.trim("telefono").alias("telefono"),
    F.upper(F.trim("estado")).alias("estado"),
    F.col("creado_en").cast("timestamp").alias("creado_en"),
)

# Si una clave viene repetida, conserva el registro más reciente.
ventana_cliente = Window.partitionBy("id_cliente").orderBy(
    F.col("creado_en").desc_nulls_last()
)

cliente_limpio = (
    cliente_limpio
    .filter(F.col("id_cliente").isNotNull())
    .withColumn("fila", F.row_number().over(ventana_cliente))
    .filter(F.col("fila") == 1)
    .drop("fila")
)


# %% [markdown]
# ## 2. Calcular un hash para detectar cambios

# %%
cliente_limpio = cliente_limpio.withColumn(
    "hash_atributos",
    F.sha2(
        F.concat_ws(
            "||",
            F.coalesce(F.col("tipo_documento"), F.lit("")),
            F.coalesce(F.col("nro_documento"), F.lit("")),
            F.coalesce(F.col("nombre_completo"), F.lit("")),
            F.coalesce(F.col("tipo_cliente"), F.lit("")),
            F.coalesce(F.col("segmento"), F.lit("")),
            F.coalesce(F.col("fecha_registro").cast("string"), F.lit("")),
            F.coalesce(F.col("email"), F.lit("")),
            F.coalesce(F.col("telefono"), F.lit("")),
            F.coalesce(F.col("estado"), F.lit("")),
            F.coalesce(F.col("creado_en").cast("string"), F.lit("")),
        ),
        256,
    ),
)


# %% [markdown]
# ## 3. Identificar clientes nuevos y clientes modificados

# %%
cliente_actual = (
    spark.table("slv.cliente")
    .filter(F.col("es_actual") == True)
    .select(
        F.col("id_cliente").alias("id_cliente_actual"),
        F.col("hash_atributos").alias("hash_actual"),
    )
)

comparacion = cliente_limpio.join(
    cliente_actual,
    cliente_limpio.id_cliente == cliente_actual.id_cliente_actual,
    "left",
)

clientes_cambiados = (
    comparacion
    .filter(
        F.col("id_cliente_actual").isNotNull()
        & (F.col("hash_atributos") != F.col("hash_actual"))
    )
    .select("id_cliente")
    .cache()
)

nuevas_versiones = (
    comparacion
    .filter(
        F.col("id_cliente_actual").isNull()
        | (F.col("hash_atributos") != F.col("hash_actual"))
    )
    .select(*cliente_limpio.columns)
    .cache()
)

cantidad_cambios = clientes_cambiados.count()
cantidad_versiones = nuevas_versiones.count()


# %% [markdown]
# ## 4. Cerrar la versión anterior de los clientes modificados

# %%
tabla_cliente = DeltaTable.forName(spark, "slv.cliente")

if cantidad_cambios > 0:
    (
        tabla_cliente.alias("destino")
        .merge(
            clientes_cambiados.alias("cambio"),
            "destino.id_cliente = cambio.id_cliente "
            "AND destino.es_actual = true",
        )
        .whenMatchedUpdate(
            set={
                "vigente_hasta": F.lit(fecha_proceso),
                "es_actual": F.lit(False),
                "fecha_proceso": F.lit(fecha_proceso),
            }
        )
        .execute()
    )


# %% [markdown]
# ## 5. Insertar la primera o la nueva versión del cliente

# %%
if cantidad_versiones > 0:
    versiones_para_insertar = (
        nuevas_versiones
        .withColumn(
            "cliente_sk",
            F.sha2(
                F.concat_ws(
                    "||",
                    F.col("id_cliente").cast("string"),
                    F.col("hash_atributos"),
                    F.lit(fecha_proceso).cast("string"),
                ),
                256,
            ),
        )
        .withColumn("vigente_desde", F.lit(fecha_proceso))
        .withColumn("vigente_hasta", F.lit(vigencia_abierta))
        .withColumn("es_actual", F.lit(True))
        .withColumn("fecha_proceso", F.lit(fecha_proceso))
        .select(*spark.table("slv.cliente").columns)
    )

    versiones_para_insertar.write.format("delta").mode("append").saveAsTable(
        "slv.cliente"
    )

clientes_cambiados.unpersist()
nuevas_versiones.unpersist()


# %% [markdown]
# ## 6. Limpiar y tipificar préstamos

# %%
prestamo_bronze = spark.table("brz.banco_prestamo")

prestamo_limpio = prestamo_bronze.select(
    F.col("id_prestamo").cast("int").alias("id_prestamo"),
    F.col("id_cliente").cast("int").alias("id_cliente"),
    F.col("id_sucursal").cast("smallint").alias("id_sucursal"),
    F.upper(F.trim("tipo_prestamo")).alias("tipo_prestamo"),
    F.col("monto_desembolso").cast("decimal(16,2)").alias(
        "monto_desembolso"
    ),
    F.col("saldo_pendiente").cast("decimal(16,2)").alias(
        "saldo_pendiente"
    ),
    F.col("tasa_interes_anual").cast("decimal(7,4)").alias(
        "tasa_interes_anual"
    ),
    F.col("numero_cuotas").cast("smallint").alias("numero_cuotas"),
    F.col("fecha_desembolso").cast("date").alias("fecha_desembolso"),
    F.upper(F.trim("estado")).alias("estado"),
)

ventana_prestamo = Window.partitionBy("id_prestamo").orderBy(
    F.col("fecha_desembolso").desc_nulls_last()
)

prestamo_limpio = (
    prestamo_limpio
    .filter(
        F.col("id_prestamo").isNotNull()
        & F.col("id_cliente").isNotNull()
    )
    .withColumn("fila", F.row_number().over(ventana_prestamo))
    .filter(F.col("fila") == 1)
    .drop("fila")
    .withColumn("fecha_proceso", F.lit(fecha_proceso))
)


# %% [markdown]
# ## 7. Actualizar o insertar préstamos

# %%
tabla_prestamo = DeltaTable.forName(spark, "slv.prestamo")

(
    tabla_prestamo.alias("destino")
    .merge(
        prestamo_limpio.alias("fuente"),
        "destino.id_prestamo = fuente.id_prestamo",
    )
    .whenMatchedUpdateAll()
    .whenNotMatchedInsertAll()
    .execute()
)

print(f"Clientes modificados: {cantidad_cambios}")
print(f"Versiones insertadas: {cantidad_versiones}")
print(f"Préstamos procesados: {prestamo_limpio.count()}")
