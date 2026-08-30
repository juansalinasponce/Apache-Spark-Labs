# Databricks notebook source
# MAGIC %run ./lab_config

# COMMAND ----------

from pyspark.sql import functions as F

use_catalog()
ensure_schema(SCHEMA_BRONZE)


def bronze_table_name(source_system, table):
    return f"{source_system}_{table}"


def read_landing_csv(path):
    return (
        spark.read.format("csv")
        .option("header", "true")
        .option("inferSchema", "false")
        .option("mode", "PERMISSIVE")
        .option("encoding", "UTF-8")
        .load(path)
    )


def load_bronze(item):
    target_table = bronze_table_name(item["source_system"], item["table"])
    target_name = fqtn(SCHEMA_BRONZE, target_table)

    df = (
        read_landing_csv(item["landing_path"])
        .withColumn("_ingestion_timestamp", F.current_timestamp())
        .withColumn("_source_file", F.input_file_name())
        .withColumn("_source_system", F.lit(item["source_system"].upper()))
        .withColumn("_batch_id", F.lit(BATCH_ID))
    )

    (
        df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(target_name)
    )

    print(f"Loaded {target_name}: {df.count()} rows")


for source_table in SOURCE_TABLES:
    load_bronze(source_table)

