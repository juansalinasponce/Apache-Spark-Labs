# Databricks notebook source
# MAGIC %md
# MAGIC # Paso 5 — Redpanda a Bronze
# MAGIC Lee los mensajes pendientes de `viation-peru` y los conserva sin transformar.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

from pyspark.sql import functions as F


BRONZE_TABLE = f"{BRONZE_CATALOG}.{BRONZE_SCHEMA}.flights"


def escape_jaas(value):
    """Escape a secret for a quoted JAAS configuration value."""
    return value.replace("\\", "\\\\").replace('"', '\\"')


redpanda_username = dbutils.secrets.get(
    REDPANDA_SECRET_SCOPE,
    REDPANDA_USERNAME_SECRET,
)
redpanda_password = dbutils.secrets.get(
    REDPANDA_SECRET_SCOPE,
    REDPANDA_PASSWORD_SECRET,
)

jaas_config = (
    "kafkashaded.org.apache.kafka.common.security.scram."
    "ScramLoginModule required "
    f'username="{escape_jaas(redpanda_username)}" '
    f'password="{escape_jaas(redpanda_password)}";'
)

kafka_options = {
    "kafka.bootstrap.servers": REDPANDA_BOOTSTRAP_SERVERS,
    "subscribe": REDPANDA_TOPIC,
    "startingOffsets": "earliest",
    "failOnDataLoss": "false",
    "maxOffsetsPerTrigger": "1000",
    "kafka.security.protocol": "SASL_SSL",
    "kafka.sasl.mechanism": "SCRAM-SHA-256",
    "kafka.sasl.jaas.config": jaas_config,
}

# COMMAND ----------

kafka_stream = (
    spark.readStream
    .format("kafka")
    .options(**kafka_options)
    .load()
)

bronze_stream = kafka_stream.select(
    F.sha2(
        F.concat_ws(
            ":",
            F.col("topic"),
            F.col("partition").cast("string"),
            F.col("offset").cast("string"),
        ),
        256,
    ).alias("record_id"),
    F.col("key").cast("string").alias("message_key"),
    F.col("value").cast("string").alias("raw_payload"),
    F.col("topic").alias("kafka_topic"),
    F.col("partition").alias("kafka_partition"),
    F.col("offset").alias("kafka_offset"),
    F.col("timestamp").alias("kafka_timestamp"),
    F.col("value").isNull().alias("is_tombstone"),
    F.current_timestamp().alias("ingested_at_utc"),
    F.current_date().alias("ingestion_date"),
)

# COMMAND ----------

query = (
    bronze_stream.writeStream
    .queryName("redpanda_to_bronze_flights")
    .outputMode("append")
    .option("checkpointLocation", BRONZE_CHECKPOINT_LOCATION)
    .trigger(availableNow=True)
    .toTable(BRONZE_TABLE)
)

query.awaitTermination()

print(f"Bronze ingestion completed: {BRONZE_TABLE}")
print(f"Checkpoint: {BRONZE_CHECKPOINT_LOCATION}")
