-- Reemplaza your-project-id antes de ejecutar.
SELECT
  flight_date,
  airport_iata,
  movement_type,
  flight_status,
  COUNT(DISTINCT flight_iata) AS flights,
  ROUND(AVG(altitude_meters), 1) AS average_altitude_meters,
  ROUND(AVG(speed_kmh), 1) AS average_speed_kmh
FROM `your-project-id.aviation_realtime.flight_events`
WHERE flight_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY flight_date, airport_iata, movement_type, flight_status
ORDER BY flight_date DESC, airport_iata;
