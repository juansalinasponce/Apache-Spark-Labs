# Databricks notebook source
# MAGIC %md
# MAGIC # Paso 1 — Configuración de Databricks
# MAGIC Este notebook contiene parámetros no secretos. Todavía no crea tablas
# MAGIC ni se conecta con Redpanda.

# COMMAND ----------

# El entorno forma parte del nombre de cada catálogo Medallion.
dbutils.widgets.text("environment", "dev", "Environment")
dbutils.widgets.text("s3_bucket", "atokongo-labs", "S3 bucket")
dbutils.widgets.text(
    "s3_lab_prefix",
    "lab03-spark-streaming-redpanda-and-spark",
    "S3 lab prefix",
)

dbutils.widgets.text(
    "redpanda_bootstrap_servers",
    "replace-me:9092",
    "Redpanda bootstrap servers",
)
dbutils.widgets.text("redpanda_topic", "viation-peru", "Redpanda topic")
dbutils.widgets.text(
    "redpanda_secret_scope",
    "redpanda-viation-peru",
    "Databricks secret scope",
)

# COMMAND ----------

# Valores seleccionados en los widgets.
ENVIRONMENT = dbutils.widgets.get("environment").strip().lower()
S3_BUCKET = dbutils.widgets.get("s3_bucket").strip()
S3_LAB_PREFIX = dbutils.widgets.get("s3_lab_prefix").strip().strip("/")

REDPANDA_BOOTSTRAP_SERVERS = dbutils.widgets.get(
    "redpanda_bootstrap_servers"
).strip()
REDPANDA_TOPIC = dbutils.widgets.get("redpanda_topic").strip()
REDPANDA_SECRET_SCOPE = dbutils.widgets.get("redpanda_secret_scope").strip()

# Los nombres de las claves no son secretos.
REDPANDA_USERNAME_SECRET = "username"
REDPANDA_PASSWORD_SECRET = "password"

# Catálogo = capa + entorno. Schema = fuente, dominio o producto de datos.
BRONZE_CATALOG = f"bronze_{ENVIRONMENT}"
SILVER_CATALOG = f"silver_{ENVIRONMENT}"
GOLD_CATALOG = f"gold_{ENVIRONMENT}"

BRONZE_SCHEMA = "aviationstack"
SILVER_SCHEMA = "aviation"
GOLD_SCHEMA = "peru_flight_tracking"

# Taxonomía física de S3.
# Bronze: fuente / objeto de origen.
SOURCE_SYSTEM = "aviationstack"
INGESTION_CHANNEL = "redpanda"
SOURCE_OBJECT = "flights"

# Silver: dominio / entidad / dataset.
DOMAIN = "aviation"
ENTITY = "flights"

# Gold: dominio / producto de datos / dataset de consumo.
DATA_PRODUCT = "peru-flight-tracking"

if ENVIRONMENT not in {"dev", "stg", "prd"}:
    raise ValueError("environment must be one of: dev, stg, prd")

S3_LAB_ROOT = f"s3://{S3_BUCKET}/{S3_LAB_PREFIX}"
S3_ENV_ROOT = f"{S3_LAB_ROOT}/{ENVIRONMENT}"
BRONZE_AVIATIONSTACK_FLIGHTS_LOCATION = (
    f"{S3_ENV_ROOT}/bronze/{SOURCE_SYSTEM}/{SOURCE_OBJECT}"
)
BRONZE_CHECKPOINT_LOCATION = (
    f"{S3_ENV_ROOT}/operations/checkpoints/"
    f"redpanda-to-bronze-{SOURCE_SYSTEM}-{SOURCE_OBJECT}"
)
SILVER_FLIGHT_STATUS_HISTORY_LOCATION = (
    f"{S3_ENV_ROOT}/silver/{DOMAIN}/{ENTITY}/flight-status-history"
)
SILVER_CURRENT_FLIGHT_STATUS_LOCATION = (
    f"{S3_ENV_ROOT}/silver/{DOMAIN}/{ENTITY}/current-flight-status"
)
GOLD_CURRENT_FLIGHT_STATUS_LOCATION = (
    f"{S3_ENV_ROOT}/gold/{DOMAIN}/{DATA_PRODUCT}/current-status"
)
GOLD_AIRPORT_MOVEMENTS_LOCATION = (
    f"{S3_ENV_ROOT}/gold/{DOMAIN}/{DATA_PRODUCT}/airport-movements"
)
SILVER_CHECKPOINT_LOCATION = (
    f"{S3_ENV_ROOT}/operations/checkpoints/bronze-to-silver-flights"
)

# Interpretar timestamps de forma consistente.
spark.conf.set("spark.sql.session.timeZone", "UTC")

# COMMAND ----------

if REDPANDA_BOOTSTRAP_SERVERS.startswith("replace-me"):
    print("PENDING: configure redpanda_bootstrap_servers")
else:
    print("OK: Redpanda bootstrap servers configured")

print(f"Topic: {REDPANDA_TOPIC}")
print(f"Environment: {ENVIRONMENT}")
print(f"Bronze: {BRONZE_CATALOG}.{BRONZE_SCHEMA}")
print(f"Silver: {SILVER_CATALOG}.{SILVER_SCHEMA}")
print(f"Gold: {GOLD_CATALOG}.{GOLD_SCHEMA}")
print(f"Secret scope: {REDPANDA_SECRET_SCOPE}")
print(f"S3 lab root: {S3_LAB_ROOT}")
print(f"S3 environment root: {S3_ENV_ROOT}")
print(f"Bronze data: {BRONZE_AVIATIONSTACK_FLIGHTS_LOCATION}")
print(f"Bronze checkpoint: {BRONZE_CHECKPOINT_LOCATION}")
print(f"Silver history: {SILVER_FLIGHT_STATUS_HISTORY_LOCATION}")
print(f"Silver current: {SILVER_CURRENT_FLIGHT_STATUS_LOCATION}")
print(f"Gold current: {GOLD_CURRENT_FLIGHT_STATUS_LOCATION}")
print(f"Gold movements: {GOLD_AIRPORT_MOVEMENTS_LOCATION}")

# No se leen ni imprimen secretos en este paso.
