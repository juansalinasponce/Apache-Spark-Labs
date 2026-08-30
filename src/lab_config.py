# Databricks notebook source
# Central configuration for the S3 + Databricks Free Edition medallion lab.

DEFAULT_CATALOG = "workspace"
SCHEMA_BRONZE = "brz"
SCHEMA_SILVER = "slv"
SCHEMA_GOLD = "gld"

DEFAULT_S3_BUCKET = "s3://<bucket>"
DEFAULT_BATCH_ID = "manual_001"


def _create_widget(name, default_value, label):
    try:
        dbutils.widgets.text(name, default_value, label)
    except NameError:
        pass
    except Exception:
        pass


def _get_parameter(name, default_value):
    try:
        value = dbutils.widgets.get(name)
        return value.strip() or default_value
    except NameError:
        return default_value
    except Exception:
        return default_value


_create_widget("catalog", DEFAULT_CATALOG, "Unity Catalog catalog")
_create_widget("s3_bucket", DEFAULT_S3_BUCKET, "S3 bucket, for example s3://my-bucket")
_create_widget("batch_id", DEFAULT_BATCH_ID, "Manual batch id")

CATALOG = _get_parameter("catalog", DEFAULT_CATALOG)
S3_BUCKET = _get_parameter("s3_bucket", DEFAULT_S3_BUCKET).rstrip("/")
BATCH_ID = _get_parameter("batch_id", DEFAULT_BATCH_ID)

LANDING_BASE_PATH = f"{S3_BUCKET}/lakehouse/landing"

SOURCE_TABLES = [
    {
        "source_system": "crm",
        "table": "clientes",
        "file_name": "clientes_cdc.csv",
        "landing_path": f"{LANDING_BASE_PATH}/crm/clientes/clientes_cdc.csv",
    },
    {
        "source_system": "erp",
        "table": "categorias",
        "file_name": "categorias.csv",
        "landing_path": f"{LANDING_BASE_PATH}/erp/categorias/categorias.csv",
    },
    {
        "source_system": "erp",
        "table": "productos",
        "file_name": "productos_cdc.csv",
        "landing_path": f"{LANDING_BASE_PATH}/erp/productos/productos_cdc.csv",
    },
    {
        "source_system": "pos",
        "table": "tiendas",
        "file_name": "tiendas.csv",
        "landing_path": f"{LANDING_BASE_PATH}/pos/tiendas/tiendas.csv",
    },
    {
        "source_system": "pos",
        "table": "vendedores",
        "file_name": "vendedores.csv",
        "landing_path": f"{LANDING_BASE_PATH}/pos/vendedores/vendedores.csv",
    },
    {
        "source_system": "pos",
        "table": "ordenes",
        "file_name": "ordenes.csv",
        "landing_path": f"{LANDING_BASE_PATH}/pos/ordenes/ordenes.csv",
    },
    {
        "source_system": "pos",
        "table": "detalle_ordenes",
        "file_name": "detalle_ordenes.csv",
        "landing_path": f"{LANDING_BASE_PATH}/pos/detalle_ordenes/detalle_ordenes.csv",
    },
]


def q(identifier):
    return f"`{identifier.replace('`', '``')}`"


def fqtn(schema, table):
    if CATALOG:
        return f"{q(CATALOG)}.{q(schema)}.{q(table)}"
    return f"{q(schema)}.{q(table)}"


def ensure_schema(schema):
    if CATALOG:
        spark.sql(f"CREATE SCHEMA IF NOT EXISTS {q(CATALOG)}.{q(schema)}")
    else:
        spark.sql(f"CREATE SCHEMA IF NOT EXISTS {q(schema)}")


def use_catalog():
    if CATALOG:
        spark.sql(f"USE CATALOG {q(CATALOG)}")

