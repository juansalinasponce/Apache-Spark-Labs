# Databricks notebook source
# MAGIC %md
# MAGIC # Paso 4 — DDL de Gold
# MAGIC Registra las tablas externas del producto de datos `peru-flight-tracking`.

# COMMAND ----------

# MAGIC %run ./00_config

# COMMAND ----------

spark.sql(f"CREATE CATALOG IF NOT EXISTS {GOLD_CATALOG}")
spark.sql(
    f"CREATE SCHEMA IF NOT EXISTS {GOLD_CATALOG}.{GOLD_SCHEMA}"
)

# COMMAND ----------

spark.sql(
    f"""
    CREATE TABLE IF NOT EXISTS {GOLD_CATALOG}.{GOLD_SCHEMA}.current_status (
        flight_instance_id STRING NOT NULL,
        flight_date DATE,
        monitored_airport_iata STRING NOT NULL,
        movement_type STRING NOT NULL,
        flight_iata STRING,
        flight_number STRING,
        airline_name STRING,
        aircraft_registration STRING,
        origin_airport_iata STRING,
        origin_airport_name STRING,
        destination_airport_iata STRING,
        destination_airport_name STRING,
        flight_status STRING,
        scheduled_at_utc TIMESTAMP,
        scheduled_at_lima TIMESTAMP_NTZ,
        estimated_at_utc TIMESTAMP,
        estimated_at_lima TIMESTAMP_NTZ,
        actual_at_utc TIMESTAMP,
        actual_at_lima TIMESTAMP_NTZ,
        delay_minutes INT,
        latitude DOUBLE,
        longitude DOUBLE,
        altitude_meters DOUBLE,
        horizontal_speed_kmh DOUBLE,
        is_ground BOOLEAN,
        last_observed_at_utc TIMESTAMP NOT NULL,
        last_observed_at_lima TIMESTAMP_NTZ NOT NULL,
        updated_at_utc TIMESTAMP NOT NULL
    )
    USING DELTA
    LOCATION '{GOLD_CURRENT_FLIGHT_STATUS_LOCATION}'
    COMMENT 'Current Peru flight tracking dataset for reports and applications'
    TBLPROPERTIES (
        'quality' = 'gold',
        'domain' = 'aviation',
        'data_product' = 'peru-flight-tracking'
    )
    """
)

# COMMAND ----------

spark.sql(
    f"""
    CREATE TABLE IF NOT EXISTS {GOLD_CATALOG}.{GOLD_SCHEMA}.airport_movements (
        metric_date_lima DATE NOT NULL,
        window_start_lima TIMESTAMP_NTZ NOT NULL,
        monitored_airport_iata STRING NOT NULL,
        movement_type STRING NOT NULL,
        total_flights BIGINT NOT NULL,
        scheduled_flights BIGINT NOT NULL,
        active_flights BIGINT NOT NULL,
        landed_flights BIGINT NOT NULL,
        cancelled_flights BIGINT NOT NULL,
        delayed_flights BIGINT NOT NULL,
        average_delay_minutes DOUBLE,
        updated_at_utc TIMESTAMP NOT NULL
    )
    USING DELTA
    LOCATION '{GOLD_AIRPORT_MOVEMENTS_LOCATION}'
    COMMENT 'Hourly airport movement indicators for the Peru flight tracking data product'
    TBLPROPERTIES (
        'quality' = 'gold',
        'domain' = 'aviation',
        'data_product' = 'peru-flight-tracking',
        'dataset_type' = 'aggregate'
    )
    """
)

# COMMAND ----------

print("Gold DDL completed")
print(
    "Current status: "
    f"{GOLD_CATALOG}.{GOLD_SCHEMA}.current_status"
)
print(
    "Airport movements: "
    f"{GOLD_CATALOG}.{GOLD_SCHEMA}.airport_movements"
)
print(f"Current location: {GOLD_CURRENT_FLIGHT_STATUS_LOCATION}")
print(f"Movements location: {GOLD_AIRPORT_MOVEMENTS_LOCATION}")
