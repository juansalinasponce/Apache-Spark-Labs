# Databricks notebook source
# MAGIC %run ./lab_config

# COMMAND ----------

from pyspark.sql import functions as F
from pyspark.sql import Window

use_catalog()
ensure_schema(SCHEMA_GOLD)


def read_silver(table):
    return spark.table(fqtn(SCHEMA_SILVER, table))


def write_gold(df, table):
    target_name = fqtn(SCHEMA_GOLD, table)
    (
        df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_name)
    )
    print(f"Loaded {target_name}: {df.count()} rows")


def positive_sk(*columns):
    return F.abs(F.xxhash64(*[F.col(column_name) for column_name in columns]))


def latest_by_key(df, key_columns, order_column):
    window_spec = Window.partitionBy(*key_columns).orderBy(F.col(order_column).desc())
    return (
        df.withColumn("_rn", F.row_number().over(window_spec))
        .filter(F.col("_rn") == 1)
        .drop("_rn")
    )


# COMMAND ----------
# Dimension: dim_cliente, SCD Type 2 from CRM CDC.

clientes_base = (
    read_silver("crm_clientes")
    .filter(F.col("operacion") != "DELETE")
    .withColumn(
        "hash_diff",
        F.sha2(
            F.concat_ws(
                "||",
                F.coalesce(F.col("nombres"), F.lit("")),
                F.coalesce(F.col("apellidos"), F.lit("")),
                F.coalesce(F.col("email"), F.lit("")),
                F.coalesce(F.col("telefono"), F.lit("")),
                F.coalesce(F.col("ciudad"), F.lit("")),
                F.coalesce(F.col("departamento"), F.lit("")),
                F.coalesce(F.col("pais"), F.lit("")),
                F.coalesce(F.col("segmento"), F.lit("")),
            ),
            256,
        ),
    )
)

cliente_order = Window.partitionBy("cliente_id").orderBy("fecha_actualizacion")
cliente_versions = (
    clientes_base.withColumn("_prev_hash", F.lag("hash_diff").over(cliente_order))
    .filter(F.col("_prev_hash").isNull() | (F.col("_prev_hash") != F.col("hash_diff")))
    .drop("_prev_hash")
    .withColumn("fecha_inicio_vigencia", F.col("fecha_actualizacion"))
    .withColumn(
        "fecha_fin_vigencia",
        F.date_sub(F.lead("fecha_actualizacion").over(cliente_order), 1),
    )
    .withColumn("es_actual", F.col("fecha_fin_vigencia").isNull())
)

dim_cliente = cliente_versions.select(
    positive_sk("cliente_id", "fecha_inicio_vigencia").alias("cliente_sk"),
    "cliente_id",
    "nombres",
    "apellidos",
    F.concat_ws(" ", F.col("nombres"), F.col("apellidos")).alias("nombre_completo"),
    "email",
    "telefono",
    "ciudad",
    "departamento",
    "pais",
    "segmento",
    "fecha_inicio_vigencia",
    "fecha_fin_vigencia",
    "es_actual",
    "hash_diff",
)

write_gold(dim_cliente, "dim_cliente")

# COMMAND ----------
# Dimension: dim_producto, SCD Type 1 using the latest product CDC row.

productos_actuales = latest_by_key(
    read_silver("erp_productos").filter(F.col("operacion") != "DELETE"),
    ["producto_id"],
    "fecha_actualizacion",
)

categorias = read_silver("erp_categorias").select(
    "categoria_id", "nombre_categoria", F.col("estado").alias("estado_categoria")
)

dim_producto = (
    productos_actuales.join(categorias, "categoria_id", "left")
    .select(
        positive_sk("producto_id").alias("producto_sk"),
        "producto_id",
        "categoria_id",
        "nombre_categoria",
        "sku",
        "nombre_producto",
        "marca",
        "precio_lista",
        "estado",
        "fecha_actualizacion",
    )
)

write_gold(dim_producto, "dim_producto")

# COMMAND ----------
# Dimensions: tienda and vendedor, SCD Type 1.

dim_tienda = read_silver("pos_tiendas").select(
    positive_sk("tienda_id").alias("tienda_sk"),
    "tienda_id",
    "nombre_tienda",
    "canal",
    "ciudad",
    "region",
    "estado",
    "fecha_creacion",
)

write_gold(dim_tienda, "dim_tienda")

dim_vendedor = read_silver("pos_vendedores").select(
    positive_sk("vendedor_id").alias("vendedor_sk"),
    "vendedor_id",
    "tienda_id",
    "nombre_vendedor",
    "estado",
    "fecha_ingreso",
)

write_gold(dim_vendedor, "dim_vendedor")

# COMMAND ----------
# Dimension: dim_fecha, generated from POS order dates.

ordenes = read_silver("pos_ordenes")
date_limits = ordenes.select(
    F.min("fecha_orden").alias("fecha_min"), F.max("fecha_orden").alias("fecha_max")
).first()

dim_fecha = (
    spark.sql(
        f"""
        SELECT explode(sequence(
            to_date('{date_limits.fecha_min}'),
            to_date('{date_limits.fecha_max}'),
            interval 1 day
        )) AS fecha
        """
    )
    .select(
        F.date_format("fecha", "yyyyMMdd").cast("int").alias("fecha_sk"),
        F.col("fecha"),
        F.year("fecha").alias("anio"),
        F.quarter("fecha").alias("trimestre"),
        F.month("fecha").alias("mes"),
        F.date_format("fecha", "MMMM").alias("nombre_mes"),
        F.dayofmonth("fecha").alias("dia_mes"),
        F.dayofweek("fecha").alias("dia_semana"),
        F.date_format("fecha", "EEEE").alias("nombre_dia"),
        F.weekofyear("fecha").alias("semana_anio"),
    )
)

write_gold(dim_fecha, "dim_fecha")

# COMMAND ----------
# Fact: fact_ventas, grain one completed order line.

detalle = read_silver("pos_detalle_ordenes")
ordenes_completadas = ordenes.filter(F.col("estado_orden") == "COMPLETADA")

dc = spark.table(fqtn(SCHEMA_GOLD, "dim_cliente")).alias("dc")
dp = spark.table(fqtn(SCHEMA_GOLD, "dim_producto")).alias("dp")
dt = spark.table(fqtn(SCHEMA_GOLD, "dim_tienda")).alias("dt")
dv = spark.table(fqtn(SCHEMA_GOLD, "dim_vendedor")).alias("dv")

fact_ventas = (
    detalle.alias("d")
    .join(ordenes_completadas.alias("o"), "orden_id", "inner")
    .join(
        dc,
        (F.col("o.cliente_id") == F.col("dc.cliente_id"))
        & (F.col("o.fecha_orden") >= F.col("dc.fecha_inicio_vigencia"))
        & (
            F.col("dc.fecha_fin_vigencia").isNull()
            | (F.col("o.fecha_orden") <= F.col("dc.fecha_fin_vigencia"))
        ),
        "left",
    )
    .join(dp, F.col("d.producto_id") == F.col("dp.producto_id"), "left")
    .join(dt, F.col("o.tienda_id") == F.col("dt.tienda_id"), "left")
    .join(dv, F.col("o.vendedor_id") == F.col("dv.vendedor_id"), "left")
    .select(
        positive_sk("d.orden_detalle_id").alias("venta_sk"),
        F.col("d.orden_detalle_id"),
        F.col("o.orden_id"),
        F.date_format("o.fecha_orden", "yyyyMMdd").cast("int").alias("fecha_sk"),
        F.col("dc.cliente_sk"),
        F.col("dp.producto_sk"),
        F.col("dt.tienda_sk"),
        F.col("dv.vendedor_sk"),
        F.col("o.cliente_id"),
        F.col("d.producto_id"),
        F.col("o.tienda_id"),
        F.col("o.vendedor_id"),
        F.col("o.fecha_orden"),
        F.col("o.metodo_pago"),
        F.col("o.moneda"),
        F.col("d.cantidad"),
        F.col("d.precio_unitario"),
        F.col("d.descuento_linea"),
        F.col("d.impuesto_linea"),
        F.col("d.total_linea"),
        (F.col("d.cantidad") * F.col("d.precio_unitario")).cast("decimal(12,2)").alias("venta_bruta"),
        F.col("d.total_linea").alias("venta_neta"),
    )
)

write_gold(fact_ventas, "fact_ventas")

# COMMAND ----------
# Reporting tables in Gold.

rpt_ventas_mensual = (
    fact_ventas.alias("fv")
    .join(dim_fecha.alias("df"), "fecha_sk", "inner")
    .groupBy("df.anio", "df.mes", "df.nombre_mes")
    .agg(
        F.countDistinct("fv.orden_id").alias("ordenes"),
        F.sum("fv.cantidad").alias("unidades"),
        F.sum("fv.venta_bruta").cast("decimal(14,2)").alias("venta_bruta"),
        F.sum("fv.descuento_linea").cast("decimal(14,2)").alias("descuento"),
        F.sum("fv.impuesto_linea").cast("decimal(14,2)").alias("impuesto"),
        F.sum("fv.venta_neta").cast("decimal(14,2)").alias("venta_neta"),
    )
    .orderBy("anio", "mes")
)

write_gold(rpt_ventas_mensual, "rpt_ventas_mensual")

rpt_ventas_por_categoria = (
    fact_ventas.alias("fv")
    .join(dim_producto.alias("dp"), "producto_sk", "left")
    .groupBy("dp.categoria_id", "dp.nombre_categoria")
    .agg(
        F.countDistinct("fv.orden_id").alias("ordenes"),
        F.sum("fv.cantidad").alias("unidades"),
        F.sum("fv.venta_neta").cast("decimal(14,2)").alias("venta_neta"),
    )
    .orderBy(F.col("venta_neta").desc())
)

write_gold(rpt_ventas_por_categoria, "rpt_ventas_por_categoria")

rpt_top_clientes = (
    fact_ventas.alias("fv")
    .join(dim_cliente.alias("dc"), "cliente_sk", "left")
    .groupBy("dc.cliente_id", "dc.nombre_completo", "dc.segmento", "dc.ciudad")
    .agg(
        F.countDistinct("fv.orden_id").alias("ordenes"),
        F.sum("fv.cantidad").alias("unidades"),
        F.sum("fv.venta_neta").cast("decimal(14,2)").alias("venta_neta"),
    )
    .orderBy(F.col("venta_neta").desc())
)

write_gold(rpt_top_clientes, "rpt_top_clientes")

