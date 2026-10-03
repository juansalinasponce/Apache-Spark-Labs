SELECT 'gld.dim_cliente' AS tabla, COUNT(*) AS filas
FROM gld.dim_cliente
UNION ALL
SELECT 'gld.dim_tipo_prestamo', COUNT(*)
FROM gld.dim_tipo_prestamo
UNION ALL
SELECT 'gld.fct_prestamo', COUNT(*)
FROM gld.fct_prestamo;

-- Debe devolver cero filas.
SELECT
    id_cliente,
    SUM(CASE WHEN es_actual = 1 THEN 1 ELSE 0 END) AS versiones_actuales
FROM gld.dim_cliente
GROUP BY id_cliente
HAVING SUM(CASE WHEN es_actual = 1 THEN 1 ELSE 0 END) <> 1;

-- Debe devolver cero préstamos sin dimensiones relacionadas.
SELECT COUNT(*) AS prestamos_sin_dimensiones
FROM gld.fct_prestamo AS prestamo
LEFT JOIN gld.dim_cliente AS cliente
    ON cliente.cliente_sk = prestamo.cliente_sk
LEFT JOIN gld.dim_tipo_prestamo AS tipo
    ON tipo.tipo_prestamo_sk = prestamo.tipo_prestamo_sk
WHERE cliente.cliente_sk IS NULL
   OR tipo.tipo_prestamo_sk IS NULL;

SELECT
    tipo.tipo_prestamo,
    COUNT(*) AS cantidad_prestamos,
    SUM(prestamo.monto_desembolso) AS monto_desembolsado,
    SUM(prestamo.saldo_pendiente) AS saldo_pendiente
FROM gld.fct_prestamo AS prestamo
INNER JOIN gld.dim_tipo_prestamo AS tipo
    ON tipo.tipo_prestamo_sk = prestamo.tipo_prestamo_sk
GROUP BY tipo.tipo_prestamo
ORDER BY monto_desembolsado DESC;
