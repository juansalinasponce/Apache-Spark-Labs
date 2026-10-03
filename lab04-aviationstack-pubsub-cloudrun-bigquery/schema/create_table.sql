CREATE TABLE IF NOT EXISTS
  `{{PROJECT_ID}}.{{BIGQUERY_DATASET}}.{{BIGQUERY_TABLE}}`
(
  event_id STRING NOT NULL OPTIONS(description = 'SHA-256 determinista del evento'),
  collected_at TIMESTAMP NOT NULL OPTIONS(description = 'Momento de consulta a Aviationstack'),
  ingested_at TIMESTAMP NOT NULL OPTIONS(description = 'Momento de inserción en BigQuery'),
  pubsub_message_id STRING OPTIONS(description = 'Identificador asignado por Pub/Sub'),
  airport_iata STRING,
  movement_type STRING,
  flight_date DATE,
  flight_status STRING,
  flight_iata STRING,
  airline_name STRING,
  departure_airport STRING,
  departure_iata STRING,
  arrival_airport STRING,
  arrival_iata STRING,
  latitude FLOAT64,
  longitude FLOAT64,
  altitude_meters FLOAT64,
  speed_kmh FLOAT64,
  position_updated_at TIMESTAMP,
  payload JSON OPTIONS(description = 'Evento completo recibido desde Pub/Sub')
)
PARTITION BY flight_date
CLUSTER BY airport_iata, flight_status, flight_iata
OPTIONS (
  description = 'Observaciones near real time obtenidas desde Aviationstack',
  require_partition_filter = FALSE
);
