# Databricks notebook source
# MAGIC %md
# MAGIC # Paso 2 — DDL inicial de Bronze en S3
# MAGIC Crea los schemas Medallion y registra la tabla Delta externa.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

# En Free Edition escribimos únicamente en el catálogo workspace.
if CATALOG != "workspace":
    raise ValueError("For this Free Edition lab, catalog must be workspace")

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{BRONZE_SCHEMA}")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{SILVER_SCHEMA}")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{GOLD_SCHEMA}")
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{OPERATIONS_SCHEMA}")

# COMMAND ----------

spark.sql(
    f"""
    CREATE TABLE IF NOT EXISTS {CATALOG}.{BRONZE_SCHEMA}.aviationstack_flights (
        record_id STRING NOT NULL COMMENT 'Hash of topic, partition and offset',
        message_key STRING COMMENT 'Kafka message key',
        raw_payload STRING COMMENT 'Original JSON received from Redpanda',
        kafka_topic STRING NOT NULL,
        kafka_partition INT NOT NULL,
        kafka_offset BIGINT NOT NULL,
        kafka_timestamp TIMESTAMP,
        is_tombstone BOOLEAN NOT NULL,
        ingested_at_utc TIMESTAMP NOT NULL,
        ingestion_date DATE NOT NULL
    )
    USING DELTA
    LOCATION '{BRONZE_AVIATIONSTACK_FLIGHTS_LOCATION}'
    COMMENT 'Raw append-only events from the viation-peru Redpanda topic'
    TBLPROPERTIES (
        'quality' = 'bronze',
        'source_system' = 'aviationstack',
        'ingestion_channel' = 'redpanda'
    )
    """
)

# COMMAND ----------

print("DDL completed")
print(f"Table: {CATALOG}.{BRONZE_SCHEMA}.aviationstack_flights")
print(f"Table location: {BRONZE_AVIATIONSTACK_FLIGHTS_LOCATION}")
print(f"Checkpoint: {BRONZE_CHECKPOINT_LOCATION}")
