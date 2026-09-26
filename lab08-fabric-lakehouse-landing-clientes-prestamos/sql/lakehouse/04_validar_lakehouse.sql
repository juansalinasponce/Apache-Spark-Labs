-- Ejecutar con Spark SQL sobre lh_banca_dev_medallion.

SHOW TABLES IN brz;
SHOW TABLES IN slv;

SELECT 'brz.banco_cliente' AS tabla, COUNT(*) AS filas
FROM brz.banco_cliente
UNION ALL
SELECT 'brz.banco_prestamo', COUNT(*)
FROM brz.banco_prestamo
UNION ALL
SELECT 'slv.cliente', COUNT(*)
FROM slv.cliente
UNION ALL
SELECT 'slv.prestamo', COUNT(*)
FROM slv.prestamo;

-- Debe devolver cero clientes con más de una versión actual.
SELECT
    id_cliente,
    SUM(CASE WHEN es_actual THEN 1 ELSE 0 END) AS versiones_actuales
FROM slv.cliente
GROUP BY id_cliente
HAVING SUM(CASE WHEN es_actual THEN 1 ELSE 0 END) <> 1;

-- Muestra el historial completo de los clientes que cambiaron.
SELECT
    id_cliente,
    nombre_completo,
    segmento,
    estado,
    vigente_desde,
    vigente_hasta,
    es_actual
FROM slv.cliente
WHERE id_cliente IN (
    SELECT id_cliente
    FROM slv.cliente
    GROUP BY id_cliente
    HAVING COUNT(*) > 1
)
ORDER BY id_cliente, vigente_desde;

DESCRIBE HISTORY slv.cliente;
