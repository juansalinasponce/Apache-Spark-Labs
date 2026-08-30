# Databricks notebook source
# MAGIC %md
# MAGIC # Paso 6 — Bronze a Silver
# MAGIC Valida el contrato JSON, conserva el histórico y actualiza el último estado.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

from delta.tables import DeltaTable
from pyspark.sql import functions as F
from pyspark.sql import types as T
from pyspark.sql.window import Window


BRONZE_TABLE = f"{CATALOG}.{BRONZE_SCHEMA}.aviationstack_flights"
SILVER_HISTORY_TABLE = f"{CATALOG}.{SILVER_SCHEMA}.flight_status_history"
SILVER_CURRENT_TABLE = f"{CATALOG}.{SILVER_SCHEMA}.current_flight_status"

# Explicit schemas prevent silent type inference changes between micro-batches.
airport_scope_schema = T.StructType([
    T.StructField("airport_iata", T.StringType()),
    T.StructField("movement_type", T.StringType()),
])
airline_schema = T.StructType([
    T.StructField("name", T.StringType()),
    T.StructField("iata", T.StringType()),
    T.StructField("icao", T.StringType()),
])
flight_schema = T.StructType([
    T.StructField("key", T.StringType()),
    T.StructField("number", T.StringType()),
    T.StructField("iata", T.StringType()),
    T.StructField("icao", T.StringType()),
])
aircraft_schema = T.StructType([
    T.StructField("registration", T.StringType()),
    T.StructField("iata", T.StringType()),
    T.StructField("icao", T.StringType()),
    T.StructField("icao24", T.StringType()),
])
departure_schema = T.StructType([
    T.StructField("airport", T.StringType()),
    T.StructField("iata", T.StringType()),
    T.StructField("timezone", T.StringType()),
    T.StructField("terminal", T.StringType()),
    T.StructField("gate", T.StringType()),
    T.StructField("delay_minutes", T.DoubleType()),
    T.StructField("scheduled_at", T.StringType()),
    T.StructField("estimated_at", T.StringType()),
    T.StructField("actual_at", T.StringType()),
])
arrival_schema = T.StructType([
    T.StructField("airport", T.StringType()),
    T.StructField("iata", T.StringType()),
    T.StructField("timezone", T.StringType()),
    T.StructField("terminal", T.StringType()),
    T.StructField("gate", T.StringType()),
    T.StructField("baggage", T.StringType()),
    T.StructField("delay_minutes", T.DoubleType()),
    T.StructField("scheduled_at", T.StringType()),
    T.StructField("estimated_at", T.StringType()),
    T.StructField("actual_at", T.StringType()),
])
position_schema = T.StructType([
    T.StructField("updated_at", T.StringType()),
    T.StructField("latitude", T.DoubleType()),
    T.StructField("longitude", T.DoubleType()),
    T.StructField("altitude_meters", T.DoubleType()),
    T.StructField("direction_degrees", T.DoubleType()),
    T.StructField("horizontal_speed_kmh", T.DoubleType()),
    T.StructField("vertical_speed_kmh", T.DoubleType()),
    T.StructField("is_ground", T.BooleanType()),
])
event_schema = T.StructType([
    T.StructField("event_id", T.StringType()),
    T.StructField("schema_version", T.IntegerType()),
    T.StructField("event_type", T.StringType()),
    T.StructField("collected_at", T.StringType()),
    T.StructField("source", T.StringType()),
    T.StructField("airport_scope", airport_scope_schema),
    T.StructField("flight_date", T.StringType()),
    T.StructField("flight_status", T.StringType()),
    T.StructField("airline", airline_schema),
    T.StructField("flight", flight_schema),
    T.StructField("aircraft", aircraft_schema),
    T.StructField("departure", departure_schema),
    T.StructField("arrival", arrival_schema),
    T.StructField("position", position_schema),
])

# COMMAND ----------

bronze_stream = spark.readStream.table(BRONZE_TABLE)

parsed_stream = (
    bronze_stream
    .filter(~F.col("is_tombstone"))
    .withColumn("event", F.from_json("raw_payload", event_schema))
    .filter(
        F.col("event.event_id").isNotNull()
        & (F.col("event.event_type") == "flight_observed")
        & F.to_timestamp("event.collected_at").isNotNull()
        & F.col("event.source").isNotNull()
        & F.col("event.schema_version").isNotNull()
        & F.col("event.flight.key").isNotNull()
        & F.col("event.airport_scope.airport_iata").isNotNull()
        & F.col("event.airport_scope.movement_type").isNotNull()
    )
)

flight_instance_parts = [
    F.coalesce(F.col("event.flight_date"), F.lit("")),
    F.coalesce(F.col("event.flight.key"), F.lit("")),
    F.coalesce(F.col("event.departure.iata"), F.lit("")),
    F.coalesce(F.col("event.arrival.iata"), F.lit("")),
    F.coalesce(F.col("event.departure.scheduled_at"), F.lit("")),
    F.coalesce(F.col("event.airport_scope.airport_iata"), F.lit("")),
    F.coalesce(F.col("event.airport_scope.movement_type"), F.lit("")),
]

silver_history_stream = parsed_stream.select(
    F.sha2(F.concat_ws("|", *flight_instance_parts), 256).alias(
        "flight_instance_id"
    ),
    F.col("event.event_id").alias("event_id"),
    F.to_timestamp("event.collected_at").alias("observed_at_utc"),
    F.col("event.source").alias("source_system"),
    F.col("event.schema_version").alias("schema_version"),
    F.to_date("event.flight_date").alias("flight_date"),
    F.lower("event.flight_status").alias("flight_status"),
    F.upper("event.airport_scope.airport_iata").alias(
        "monitored_airport_iata"
    ),
    F.upper("event.airport_scope.movement_type").alias("movement_type"),
    F.col("event.airline.name").alias("airline_name"),
    F.upper("event.airline.iata").alias("airline_iata"),
    F.upper("event.airline.icao").alias("airline_icao"),
    F.col("event.flight.key").alias("flight_key"),
    F.col("event.flight.number").alias("flight_number"),
    F.upper("event.flight.iata").alias("flight_iata"),
    F.upper("event.flight.icao").alias("flight_icao"),
    F.upper("event.aircraft.registration").alias("aircraft_registration"),
    F.upper("event.aircraft.icao24").alias("aircraft_icao24"),
    F.col("event.departure.airport").alias("departure_airport"),
    F.upper("event.departure.iata").alias("departure_iata"),
    F.to_timestamp("event.departure.scheduled_at").alias(
        "departure_scheduled_at_utc"
    ),
    F.to_timestamp("event.departure.estimated_at").alias(
        "departure_estimated_at_utc"
    ),
    F.to_timestamp("event.departure.actual_at").alias(
        "departure_actual_at_utc"
    ),
    F.col("event.departure.delay_minutes").cast("int").alias(
        "departure_delay_minutes"
    ),
    F.col("event.arrival.airport").alias("arrival_airport"),
    F.upper("event.arrival.iata").alias("arrival_iata"),
    F.to_timestamp("event.arrival.scheduled_at").alias(
        "arrival_scheduled_at_utc"
    ),
    F.to_timestamp("event.arrival.estimated_at").alias(
        "arrival_estimated_at_utc"
    ),
    F.to_timestamp("event.arrival.actual_at").alias(
        "arrival_actual_at_utc"
    ),
    F.col("event.arrival.delay_minutes").cast("int").alias(
        "arrival_delay_minutes"
    ),
    F.to_timestamp("event.position.updated_at").alias(
        "position_updated_at_utc"
    ),
    F.col("event.position.latitude").alias("latitude"),
    F.col("event.position.longitude").alias("longitude"),
    F.col("event.position.altitude_meters").alias("altitude_meters"),
    F.col("event.position.direction_degrees").alias("direction_degrees"),
    F.col("event.position.horizontal_speed_kmh").alias(
        "horizontal_speed_kmh"
    ),
    F.col("event.position.vertical_speed_kmh").alias("vertical_speed_kmh"),
    F.col("event.position.is_ground").alias("is_ground"),
    F.col("record_id").alias("bronze_record_id"),
    F.current_timestamp().alias("processed_at_utc"),
)

# COMMAND ----------

def upsert_silver(batch_df, batch_id):
    if batch_df.isEmpty():
        return

    history_batch = batch_df.dropDuplicates(["event_id"]).cache()

    history_target = DeltaTable.forName(spark, SILVER_HISTORY_TABLE)
    (
        history_target.alias("target")
        .merge(
            history_batch.alias("source"),
            "target.event_id = source.event_id",
        )
        .whenNotMatchedInsertAll()
        .execute()
    )

    latest_window = Window.partitionBy("flight_instance_id").orderBy(
        F.col("observed_at_utc").desc(),
        F.col("event_id").desc(),
    )
    latest_batch = (
        history_batch
        .withColumn("row_number", F.row_number().over(latest_window))
        .filter(F.col("row_number") == 1)
        .select(
            "flight_instance_id",
            F.col("event_id").alias("last_event_id"),
            "flight_date",
            F.col("observed_at_utc").alias("last_observed_at_utc"),
            "flight_status",
            "monitored_airport_iata",
            "movement_type",
            "airline_name",
            "airline_iata",
            "flight_key",
            "flight_number",
            "flight_iata",
            "aircraft_registration",
            "departure_airport",
            "departure_iata",
            "departure_scheduled_at_utc",
            "departure_estimated_at_utc",
            "departure_actual_at_utc",
            "departure_delay_minutes",
            "arrival_airport",
            "arrival_iata",
            "arrival_scheduled_at_utc",
            "arrival_estimated_at_utc",
            "arrival_actual_at_utc",
            "arrival_delay_minutes",
            "position_updated_at_utc",
            "latitude",
            "longitude",
            "altitude_meters",
            "horizontal_speed_kmh",
            "is_ground",
            F.current_timestamp().alias("updated_at_utc"),
        )
    )

    current_target = DeltaTable.forName(spark, SILVER_CURRENT_TABLE)
    (
        current_target.alias("target")
        .merge(
            latest_batch.alias("source"),
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

    history_batch.unpersist()
    print(f"Silver batch completed: {batch_id}")


query = (
    silver_history_stream.writeStream
    .queryName("bronze_to_silver_flights")
    .foreachBatch(upsert_silver)
    .option("checkpointLocation", SILVER_CHECKPOINT_LOCATION)
    .trigger(availableNow=True)
    .start()
)

query.awaitTermination()

print(f"Silver history updated: {SILVER_HISTORY_TABLE}")
print(f"Silver current state updated: {SILVER_CURRENT_TABLE}")
