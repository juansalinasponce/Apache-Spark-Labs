-- Ejecutar en la base MySQL/MariaDB configurada para el Lab 05.

SELECT
  table_name
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN ('banco_cliente', 'banco_prestamo')
ORDER BY table_name;

SELECT 'banco_cliente' AS tabla, COUNT(*) AS filas
FROM banco_cliente
UNION ALL
SELECT 'banco_prestamo', COUNT(*)
FROM banco_prestamo;

-- Debe devolver cero préstamos sin cliente.
SELECT COUNT(*) AS prestamos_sin_cliente
FROM banco_prestamo AS prestamo
LEFT JOIN banco_cliente AS cliente
  ON cliente.id_cliente = prestamo.id_cliente
WHERE cliente.id_cliente IS NULL;

-- Muestra rápida del caso comercial.
SELECT
  cliente.id_cliente,
  cliente.nombre_completo,
  cliente.segmento,
  prestamo.tipo_prestamo,
  prestamo.monto_desembolso,
  prestamo.saldo_pendiente,
  prestamo.fecha_desembolso,
  prestamo.estado
FROM banco_cliente AS cliente
INNER JOIN banco_prestamo AS prestamo
  ON prestamo.id_cliente = cliente.id_cliente
ORDER BY prestamo.fecha_desembolso DESC
LIMIT 20;
