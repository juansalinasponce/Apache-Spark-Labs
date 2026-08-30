# Databricks notebook source
# MAGIC %md
# MAGIC # Paso 7 — Silver a Gold
# MAGIC Actualiza el producto de datos que consumirá Power BI.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

from delta.tables import DeltaTable
from pyspark.sql import functions as F


SILVER_CURRENT_TABLE = (
    f"{SILVER_CATALOG}.{SILVER_SCHEMA}.current_flight_status"
)
GOLD_CURRENT_TABLE = f"{GOLD_CATALOG}.{GOLD_SCHEMA}.current_status"
GOLD_MOVEMENTS_TABLE = f"{GOLD_CATALOG}.{GOLD_SCHEMA}.airport_movements"
LIMA_TIME_ZONE = "America/Lima"


def lima_timestamp(column):
    return F.from_utc_timestamp(column, LIMA_TIME_ZONE).cast("timestamp_ntz")


def build_gold_current(silver_df):
    is_departure = F.col("movement_type") == "DEPARTURE"

    scheduled_at_utc = F.when(
        is_departure,
        F.col("departure_scheduled_at_utc"),
    ).otherwise(F.col("arrival_scheduled_at_utc"))
    estimated_at_utc = F.when(
        is_departure,
        F.col("departure_estimated_at_utc"),
    ).otherwise(F.col("arrival_estimated_at_utc"))
    actual_at_utc = F.when(
        is_departure,
        F.col("departure_actual_at_utc"),
    ).otherwise(F.col("arrival_actual_at_utc"))
    delay_minutes = F.when(
        is_departure,
        F.col("departure_delay_minutes"),
    ).otherwise(F.col("arrival_delay_minutes"))

    return silver_df.select(
        "flight_instance_id",
        "flight_date",
        "monitored_airport_iata",
        "movement_type",
        "flight_iata",
        "flight_number",
        "airline_name",
        "aircraft_registration",
        F.col("departure_iata").alias("origin_airport_iata"),
        F.col("departure_airport").alias("origin_airport_name"),
        F.col("arrival_iata").alias("destination_airport_iata"),
        F.col("arrival_airport").alias("destination_airport_name"),
        "flight_status",
        scheduled_at_utc.alias("scheduled_at_utc"),
        lima_timestamp(scheduled_at_utc).alias("scheduled_at_lima"),
        estimated_at_utc.alias("estimated_at_utc"),
        lima_timestamp(estimated_at_utc).alias("estimated_at_lima"),
        actual_at_utc.alias("actual_at_utc"),
        lima_timestamp(actual_at_utc).alias("actual_at_lima"),
        delay_minutes.cast("int").alias("delay_minutes"),
        "latitude",
        "longitude",
        "altitude_meters",
        "horizontal_speed_kmh",
        "is_ground",
        "last_observed_at_utc",
        lima_timestamp(F.col("last_observed_at_utc")).alias(
            "last_observed_at_lima"
        ),
        F.current_timestamp().alias("updated_at_utc"),
    )


def build_airport_movements(gold_current_df):
    return (
        gold_current_df
        .filter(F.col("scheduled_at_lima").isNotNull())
        .withColumn(
            "window_start_lima",
            F.date_trunc("hour", "scheduled_at_lima").cast("timestamp_ntz"),
        )
        .withColumn("metric_date_lima", F.to_date("window_start_lima"))
        .groupBy(
            "metric_date_lima",
            "window_start_lima",
            "monitored_airport_iata",
            "movement_type",
        )
        .agg(
            F.countDistinct("flight_instance_id").cast("long").alias(
                "total_flights"
            ),
            F.sum(
                F.when(F.col("flight_status") == "scheduled", 1).otherwise(0)
            ).cast("long").alias("scheduled_flights"),
            F.sum(
                F.when(F.col("flight_status") == "active", 1).otherwise(0)
            ).cast("long").alias("active_flights"),
            F.sum(
                F.when(F.col("flight_status") == "landed", 1).otherwise(0)
            ).cast("long").alias("landed_flights"),
            F.sum(
                F.when(F.col("flight_status") == "cancelled", 1).otherwise(0)
            ).cast("long").alias("cancelled_flights"),
            F.sum(
                F.when(F.col("delay_minutes") > 0, 1).otherwise(0)
            ).cast("long").alias("delayed_flights"),
            F.avg(
                F.when(F.col("delay_minutes") > 0, F.col("delay_minutes"))
            ).alias("average_delay_minutes"),
        )
        .withColumn("updated_at_utc", F.current_timestamp())
    )


def merge_gold_current(gold_current_df):
    target = DeltaTable.forName(spark, GOLD_CURRENT_TABLE)
    (
        target.alias("target")
        .merge(
            gold_current_df.alias("source"),
            "target.flight_instance_id = source.flight_instance_id",
        )
        .whenMatchedUpdateAll(
            condition=(
                "source.last_observed_at_utc >= "
                "target.last_observed_at_utc"
            )
        )
        .whenNotMatchedInsertAll()
        .execute()
    )


def merge_airport_movements(movements_df):
    target = DeltaTable.forName(spark, GOLD_MOVEMENTS_TABLE)
    merge_condition = """
        target.metric_date_lima = source.metric_date_lima
        AND target.window_start_lima = source.window_start_lima
        AND target.monitored_airport_iata = source.monitored_airport_iata
        AND target.movement_type = source.movement_type
    """
    (
        target.alias("target")
        .merge(movements_df.alias("source"), merge_condition)
        .whenMatchedUpdateAll()
        .whenNotMatchedInsertAll()
        .execute()
    )


silver_current = spark.table(SILVER_CURRENT_TABLE)

if silver_current.isEmpty():
    print("No Silver rows are available. Gold was not modified.")
else:
    gold_current = build_gold_current(silver_current).cache()
    airport_movements = build_airport_movements(gold_current)

    merge_gold_current(gold_current)
    merge_airport_movements(airport_movements)

    gold_current.unpersist()
    print(f"Gold current status updated: {GOLD_CURRENT_TABLE}")
    print(f"Gold airport movements updated: {GOLD_MOVEMENTS_TABLE}")
