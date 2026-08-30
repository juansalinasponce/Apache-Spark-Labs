# Databricks notebook source
# MAGIC %run ./lab_config

# COMMAND ----------

from pyspark.sql import functions as F

use_catalog()
ensure_schema(SCHEMA_SILVER)


def read_bronze(table):
    return spark.table(fqtn(SCHEMA_BRONZE, table))


def write_silver(df, table):
    target_name = fqtn(SCHEMA_SILVER, table)
    (
        df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_name)
    )
    print(f"Loaded {target_name}: {df.count()} rows")


def clean_text(column_name):
    return F.trim(F.col(column_name))


def clean_upper(column_name):
    return F.upper(F.trim(F.col(column_name)))


# COMMAND ----------
# CRM: clientes CDC

clientes = (
    read_bronze("crm_clientes")
    .select(
        F.col("cliente_id").cast("int").alias("cliente_id"),
        clean_text("nombres").alias("nombres"),
        clean_text("apellidos").alias("apellidos"),
        F.lower(clean_text("email")).alias("email"),
        clean_text("telefono").alias("telefono"),
        clean_text("ciudad").alias("ciudad"),
        clean_text("departamento").alias("departamento"),
        clean_text("pais").alias("pais"),
        clean_text("segmento").alias("segmento"),
        F.to_date("fecha_actualizacion").alias("fecha_actualizacion"),
        clean_upper("operacion").alias("operacion"),
        F.col("_ingestion_timestamp"),
        F.col("_source_file"),
        F.col("_batch_id"),
    )
    .filter(F.col("cliente_id").isNotNull())
    .filter(F.col("fecha_actualizacion").isNotNull())
    .dropDuplicates(["cliente_id", "fecha_actualizacion", "operacion"])
)

write_silver(clientes, "crm_clientes")

# COMMAND ----------
# ERP: categorias

categorias = (
    read_bronze("erp_categorias")
    .select(
        F.col("categoria_id").cast("int").alias("categoria_id"),
        clean_text("nombre_categoria").alias("nombre_categoria"),
        clean_upper("estado").alias("estado"),
        F.to_date("fecha_creacion").alias("fecha_creacion"),
        F.to_date("fecha_actualizacion").alias("fecha_actualizacion"),
        F.col("_ingestion_timestamp"),
        F.col("_source_file"),
        F.col("_batch_id"),
    )
    .filter(F.col("categoria_id").isNotNull())
    .dropDuplicates(["categoria_id"])
)

write_silver(categorias, "erp_categorias")

# COMMAND ----------
# ERP: productos CDC

productos = (
    read_bronze("erp_productos")
    .select(
        F.col("producto_id").cast("int").alias("producto_id"),
        F.col("categoria_id").cast("int").alias("categoria_id"),
        clean_upper("sku").alias("sku"),
        clean_text("nombre_producto").alias("nombre_producto"),
        clean_text("marca").alias("marca"),
        F.col("precio_lista").cast("decimal(12,2)").alias("precio_lista"),
        clean_upper("estado").alias("estado"),
        F.to_date("fecha_actualizacion").alias("fecha_actualizacion"),
        clean_upper("operacion").alias("operacion"),
        F.col("_ingestion_timestamp"),
        F.col("_source_file"),
        F.col("_batch_id"),
    )
    .filter(F.col("producto_id").isNotNull())
    .filter(F.col("fecha_actualizacion").isNotNull())
    .filter(F.col("precio_lista").isNull() | (F.col("precio_lista") >= 0))
    .dropDuplicates(["producto_id", "fecha_actualizacion", "operacion"])
)

write_silver(productos, "erp_productos")

# COMMAND ----------
# POS: tiendas

tiendas = (
    read_bronze("pos_tiendas")
    .select(
        F.col("tienda_id").cast("int").alias("tienda_id"),
        clean_text("nombre_tienda").alias("nombre_tienda"),
        clean_text("canal").alias("canal"),
        clean_text("ciudad").alias("ciudad"),
        clean_text("region").alias("region"),
        clean_upper("estado").alias("estado"),
        F.to_date("fecha_creacion").alias("fecha_creacion"),
        F.col("_ingestion_timestamp"),
        F.col("_source_file"),
        F.col("_batch_id"),
    )
    .filter(F.col("tienda_id").isNotNull())
    .dropDuplicates(["tienda_id"])
)

write_silver(tiendas, "pos_tiendas")

# COMMAND ----------
# POS: vendedores

vendedores = (
    read_bronze("pos_vendedores")
    .select(
        F.col("vendedor_id").cast("int").alias("vendedor_id"),
        F.col("tienda_id").cast("int").alias("tienda_id"),
        clean_text("nombre_vendedor").alias("nombre_vendedor"),
        clean_upper("estado").alias("estado"),
        F.to_date("fecha_ingreso").alias("fecha_ingreso"),
        F.col("_ingestion_timestamp"),
        F.col("_source_file"),
        F.col("_batch_id"),
    )
    .filter(F.col("vendedor_id").isNotNull())
    .filter(F.col("tienda_id").isNotNull())
    .dropDuplicates(["vendedor_id"])
)

write_silver(vendedores, "pos_vendedores")

# COMMAND ----------
# POS: ordenes

ordenes = (
    read_bronze("pos_ordenes")
    .select(
        F.col("orden_id").cast("int").alias("orden_id"),
        F.col("cliente_id").cast("int").alias("cliente_id"),
        F.col("tienda_id").cast("int").alias("tienda_id"),
        F.col("vendedor_id").cast("int").alias("vendedor_id"),
        F.to_date("fecha_orden").alias("fecha_orden"),
        clean_upper("estado_orden").alias("estado_orden"),
        clean_text("metodo_pago").alias("metodo_pago"),
        clean_upper("moneda").alias("moneda"),
        F.col("total_bruto").cast("decimal(12,2)").alias("total_bruto"),
        F.col("descuento_total").cast("decimal(12,2)").alias("descuento_total"),
        F.col("impuesto_total").cast("decimal(12,2)").alias("impuesto_total"),
        F.col("total_neto").cast("decimal(12,2)").alias("total_neto"),
        F.col("_ingestion_timestamp"),
        F.col("_source_file"),
        F.col("_batch_id"),
    )
    .filter(F.col("orden_id").isNotNull())
    .filter(F.col("cliente_id").isNotNull())
    .filter(F.col("fecha_orden").isNotNull())
    .filter(F.col("total_bruto").isNull() | (F.col("total_bruto") >= 0))
    .filter(F.col("total_neto").isNull() | (F.col("total_neto") >= 0))
    .dropDuplicates(["orden_id"])
)

write_silver(ordenes, "pos_ordenes")

# COMMAND ----------
# POS: detalle ordenes

detalle_ordenes = (
    read_bronze("pos_detalle_ordenes")
    .select(
        F.col("orden_detalle_id").cast("int").alias("orden_detalle_id"),
        F.col("orden_id").cast("int").alias("orden_id"),
        F.col("producto_id").cast("int").alias("producto_id"),
        F.col("cantidad").cast("int").alias("cantidad"),
        F.col("precio_unitario").cast("decimal(12,2)").alias("precio_unitario"),
        F.col("descuento_linea").cast("decimal(12,2)").alias("descuento_linea"),
        F.col("impuesto_linea").cast("decimal(12,2)").alias("impuesto_linea"),
        F.col("total_linea").cast("decimal(12,2)").alias("total_linea"),
        F.col("_ingestion_timestamp"),
        F.col("_source_file"),
        F.col("_batch_id"),
    )
    .filter(F.col("orden_detalle_id").isNotNull())
    .filter(F.col("orden_id").isNotNull())
    .filter(F.col("producto_id").isNotNull())
    .filter(F.col("cantidad") > 0)
    .filter(F.col("precio_unitario").isNull() | (F.col("precio_unitario") >= 0))
    .filter(F.col("total_linea").isNull() | (F.col("total_linea") >= 0))
    .dropDuplicates(["orden_detalle_id"])
)

write_silver(detalle_ordenes, "pos_detalle_ordenes")

