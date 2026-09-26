-- Conteos de staging y Gold.
SELECT 'stg.cliente' AS tabla, COUNT(*) AS filas
FROM stg.cliente
UNION ALL
SELECT 'stg.prestamo', COUNT(*)
FROM stg.prestamo
UNION ALL
SELECT 'gld.dim_cliente', COUNT(*)
FROM gld.dim_cliente
UNION ALL
SELECT 'gld.fct_prestamo', COUNT(*)
FROM gld.fct_prestamo;

-- Debe devolver cero clientes con una cantidad distinta de una versión actual.
SELECT
    id_cliente,
    SUM(CASE WHEN es_actual = 1 THEN 1 ELSE 0 END) AS versiones_actuales
FROM gld.dim_cliente
GROUP BY id_cliente
HAVING SUM(CASE WHEN es_actual = 1 THEN 1 ELSE 0 END) <> 1;

-- Debe devolver cero préstamos sin dimensión de cliente.
SELECT COUNT(*) AS prestamos_sin_cliente
FROM gld.fct_prestamo AS prestamo
LEFT JOIN gld.dim_cliente AS cliente
    ON cliente.cliente_sk = prestamo.cliente_sk
WHERE cliente.cliente_sk IS NULL;

-- Historial de clientes con más de una versión.
SELECT
    id_cliente,
    nombre_completo,
    segmento,
    estado,
    vigente_desde,
    vigente_hasta,
    es_actual
FROM gld.dim_cliente
WHERE id_cliente IN (
    SELECT id_cliente
    FROM gld.dim_cliente
    GROUP BY id_cliente
    HAVING COUNT(*) > 1
)
ORDER BY id_cliente, vigente_desde;
