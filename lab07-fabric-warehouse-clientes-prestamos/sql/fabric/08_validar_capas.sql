-- Conteos por capa. Deben conservarse entre Bronze, Silver y Gold.

SELECT 'brz.banco_cliente' AS tabla, COUNT(*) AS filas FROM brz.banco_cliente
UNION ALL
SELECT 'slv.cliente', COUNT(*) FROM slv.cliente
UNION ALL
SELECT 'gld.dim_cliente', COUNT(*) FROM gld.dim_cliente
UNION ALL
SELECT 'brz.banco_prestamo', COUNT(*) FROM brz.banco_prestamo
UNION ALL
SELECT 'slv.prestamo', COUNT(*) FROM slv.prestamo
UNION ALL
SELECT 'gld.fct_prestamo', COUNT(*) FROM gld.fct_prestamo;

-- Debe devolver 0.
SELECT COUNT(*) AS prestamos_sin_cliente
FROM gld.fct_prestamo AS prestamo
LEFT JOIN gld.dim_cliente AS cliente
  ON cliente.id_cliente = prestamo.id_cliente
WHERE cliente.id_cliente IS NULL;

-- Validación rápida del resultado comercial.
SELECT
    cliente.segmento,
    COUNT(DISTINCT cliente.id_cliente) AS clientes_con_prestamo,
    COUNT(*) AS prestamos,
    SUM(prestamo.monto_desembolso) AS monto_desembolsado,
    SUM(prestamo.saldo_pendiente) AS saldo_pendiente,
    SUM(prestamo.monto_pagado) AS monto_pagado
FROM gld.dim_cliente AS cliente
INNER JOIN gld.fct_prestamo AS prestamo
  ON prestamo.id_cliente = cliente.id_cliente
GROUP BY cliente.segmento
ORDER BY monto_desembolsado DESC;
