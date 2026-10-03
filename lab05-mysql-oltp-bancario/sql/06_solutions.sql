USE u845286110_labs;

-- 1. Clientes activos por segmento y tipo de cliente.
SELECT
  segmento,
  tipo_cliente,
  COUNT(*) AS clientes_activos
FROM banco_cliente
WHERE estado = 'ACTIVO'
GROUP BY segmento, tipo_cliente
ORDER BY segmento, tipo_cliente;

-- 2. Saldos por tipo de cuenta y moneda. No se mezclan PEN con USD.
SELECT
  tipo_cuenta,
  moneda,
  COUNT(*) AS cuentas,
  ROUND(SUM(saldo_actual), 2) AS saldo_total,
  ROUND(AVG(saldo_actual), 2) AS saldo_promedio
FROM banco_cuenta
WHERE estado = 'ACTIVA'
GROUP BY tipo_cuenta, moneda
ORDER BY tipo_cuenta, moneda;

-- 3. Cantidad y monto aprobado por canal durante agosto de 2026.
SELECT
  ca.nombre_canal,
  ca.tipo_canal,
  COUNT(*) AS transacciones,
  ROUND(SUM(t.monto), 2) AS monto_movido
FROM banco_transaccion AS t
INNER JOIN banco_canal AS ca
  ON ca.id_canal = t.id_canal
WHERE t.estado = 'APROBADA'
  AND t.fecha_transaccion >= '2026-08-01'
  AND t.fecha_transaccion < '2026-09-01'
GROUP BY ca.id_canal, ca.nombre_canal, ca.tipo_canal
ORDER BY monto_movido DESC;

-- 4. Clientes sin transacciones en los 15 días anteriores al último dato.
WITH fecha_corte AS (
  SELECT MAX(fecha_transaccion) AS ultima_fecha
  FROM banco_transaccion
),
ultima_operacion AS (
  SELECT
    cu.id_cliente,
    MAX(t.fecha_transaccion) AS ultima_transaccion
  FROM banco_cuenta AS cu
  LEFT JOIN banco_transaccion AS t
    ON t.id_cuenta = cu.id_cuenta
  GROUP BY cu.id_cliente
)
SELECT
  c.id_cliente,
  c.nombre_completo,
  u.ultima_transaccion
FROM banco_cliente AS c
LEFT JOIN ultima_operacion AS u
  ON u.id_cliente = c.id_cliente
CROSS JOIN fecha_corte AS f
WHERE c.estado = 'ACTIVO'
  AND (
    u.ultima_transaccion IS NULL
    OR u.ultima_transaccion < f.ultima_fecha - INTERVAL 15 DAY
  )
ORDER BY u.ultima_transaccion;

-- 5. Movimiento neto aprobado por cuenta.
SELECT
  cu.numero_cuenta,
  cu.moneda,
  ROUND(SUM(
    CASE t.naturaleza
      WHEN 'CREDITO' THEN t.monto
      ELSE -t.monto
    END
  ), 2) AS movimiento_neto
FROM banco_cuenta AS cu
INNER JOIN banco_transaccion AS t
  ON t.id_cuenta = cu.id_cuenta
WHERE t.estado = 'APROBADA'
GROUP BY cu.id_cuenta, cu.numero_cuenta, cu.moneda
ORDER BY cu.moneda, movimiento_neto DESC;

-- 6. Cinco clientes con mayor saldo por moneda.
WITH saldo_cliente AS (
  SELECT
    c.id_cliente,
    c.nombre_completo,
    cu.moneda,
    SUM(cu.saldo_actual) AS saldo_total
  FROM banco_cliente AS c
  INNER JOIN banco_cuenta AS cu
    ON cu.id_cliente = c.id_cliente
  WHERE cu.estado = 'ACTIVA'
  GROUP BY c.id_cliente, c.nombre_completo, cu.moneda
),
ranking AS (
  SELECT
    saldo_cliente.*,
    DENSE_RANK() OVER (
      PARTITION BY moneda
      ORDER BY saldo_total DESC
    ) AS posicion
  FROM saldo_cliente
)
SELECT *
FROM ranking
WHERE posicion <= 5
ORDER BY moneda, posicion, id_cliente;

-- 7. Cartera de préstamos y porcentaje pendiente por sucursal.
SELECT
  s.nombre_sucursal,
  COUNT(*) AS prestamos,
  ROUND(SUM(p.monto_desembolso), 2) AS monto_desembolsado,
  ROUND(SUM(p.saldo_pendiente), 2) AS saldo_pendiente,
  ROUND(
    100 * SUM(p.saldo_pendiente) / SUM(p.monto_desembolso),
    2
  ) AS porcentaje_pendiente
FROM banco_prestamo AS p
INNER JOIN banco_sucursal AS s
  ON s.id_sucursal = p.id_sucursal
WHERE p.estado IN ('VIGENTE', 'VENCIDO')
GROUP BY s.id_sucursal, s.nombre_sucursal
ORDER BY saldo_pendiente DESC;

-- 8. Vista 360 sin duplicar métricas por joins de uno a muchos.
WITH cuentas AS (
  SELECT
    id_cliente,
    COUNT(*) AS cantidad_cuentas,
    SUM(moneda = 'PEN' AND estado = 'ACTIVA') AS cuentas_activas_pen,
    SUM(moneda = 'USD' AND estado = 'ACTIVA') AS cuentas_activas_usd
  FROM banco_cuenta
  GROUP BY id_cliente
),
tarjetas AS (
  SELECT
    id_cliente,
    COUNT(*) AS cantidad_tarjetas,
    SUM(estado = 'ACTIVA') AS tarjetas_activas
  FROM banco_tarjeta
  GROUP BY id_cliente
),
prestamos AS (
  SELECT
    id_cliente,
    COUNT(*) AS cantidad_prestamos,
    SUM(saldo_pendiente) AS deuda_total
  FROM banco_prestamo
  WHERE estado IN ('VIGENTE', 'VENCIDO')
  GROUP BY id_cliente
)
SELECT
  c.id_cliente,
  c.nombre_completo,
  c.segmento,
  COALESCE(cu.cantidad_cuentas, 0) AS cantidad_cuentas,
  COALESCE(cu.cuentas_activas_pen, 0) AS cuentas_activas_pen,
  COALESCE(cu.cuentas_activas_usd, 0) AS cuentas_activas_usd,
  COALESCE(t.cantidad_tarjetas, 0) AS cantidad_tarjetas,
  COALESCE(t.tarjetas_activas, 0) AS tarjetas_activas,
  COALESCE(p.cantidad_prestamos, 0) AS cantidad_prestamos,
  COALESCE(p.deuda_total, 0) AS deuda_total
FROM banco_cliente AS c
LEFT JOIN cuentas AS cu
  ON cu.id_cliente = c.id_cliente
LEFT JOIN tarjetas AS t
  ON t.id_cliente = c.id_cliente
LEFT JOIN prestamos AS p
  ON p.id_cliente = c.id_cliente
ORDER BY c.id_cliente;

-- 9. Operaciones de importe alto para revisión.
SELECT
  t.codigo_operacion,
  t.fecha_transaccion,
  c.nombre_completo,
  cu.moneda,
  t.tipo_transaccion,
  t.naturaleza,
  t.monto,
  ca.nombre_canal,
  t.estado
FROM banco_transaccion AS t
INNER JOIN banco_cuenta AS cu
  ON cu.id_cuenta = t.id_cuenta
INNER JOIN banco_cliente AS c
  ON c.id_cliente = cu.id_cliente
INNER JOIN banco_canal AS ca
  ON ca.id_canal = t.id_canal
WHERE t.monto >= 50000
ORDER BY t.monto DESC;

-- 10. Acumulado de movimientos por cuenta con una función de ventana.
SELECT
  cu.numero_cuenta,
  t.fecha_transaccion,
  t.codigo_operacion,
  t.naturaleza,
  t.monto,
  SUM(
    CASE t.naturaleza
      WHEN 'CREDITO' THEN t.monto
      ELSE -t.monto
    END
  ) OVER (
    PARTITION BY t.id_cuenta
    ORDER BY t.fecha_transaccion, t.id_transaccion
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS movimiento_acumulado
FROM banco_transaccion AS t
INNER JOIN banco_cuenta AS cu
  ON cu.id_cuenta = t.id_cuenta
WHERE t.estado = 'APROBADA'
ORDER BY t.id_cuenta, t.fecha_transaccion, t.id_transaccion;

-- 11. Indicadores mensuales sin mezclar monedas.
SELECT
  DATE_FORMAT(t.fecha_transaccion, '%Y-%m-01') AS mes,
  cu.moneda,
  COUNT(*) AS transacciones_aprobadas,
  COUNT(DISTINCT t.id_cuenta) AS cuentas_activas,
  ROUND(SUM(t.monto), 2) AS monto_movido,
  ROUND(AVG(t.monto), 2) AS ticket_promedio
FROM banco_transaccion AS t
INNER JOIN banco_cuenta AS cu
  ON cu.id_cuenta = t.id_cuenta
WHERE t.estado = 'APROBADA'
GROUP BY DATE_FORMAT(t.fecha_transaccion, '%Y-%m-01'), cu.moneda
ORDER BY mes, cu.moneda;

-- 12. Variación mensual del número de transacciones aprobadas.
WITH mensual AS (
  SELECT
    DATE_FORMAT(fecha_transaccion, '%Y-%m-01') AS mes,
    COUNT(*) AS transacciones
  FROM banco_transaccion
  WHERE estado = 'APROBADA'
  GROUP BY DATE_FORMAT(fecha_transaccion, '%Y-%m-01')
),
comparativo AS (
  SELECT
    mes,
    transacciones,
    LAG(transacciones) OVER (ORDER BY mes) AS transacciones_mes_anterior
  FROM mensual
)
SELECT
  mes,
  transacciones,
  transacciones_mes_anterior,
  ROUND(
    100 * (transacciones - transacciones_mes_anterior)
      / NULLIF(transacciones_mes_anterior, 0),
    2
  ) AS variacion_porcentual
FROM comparativo
ORDER BY mes;

-- 13. Clientes transaccionalmente activos por mes y segmento.
SELECT
  DATE_FORMAT(t.fecha_transaccion, '%Y-%m-01') AS mes,
  c.segmento,
  COUNT(DISTINCT c.id_cliente) AS clientes_activos,
  COUNT(*) AS transacciones_aprobadas
FROM banco_transaccion AS t
INNER JOIN banco_cuenta AS cu
  ON cu.id_cuenta = t.id_cuenta
INNER JOIN banco_cliente AS c
  ON c.id_cliente = cu.id_cliente
WHERE t.estado = 'APROBADA'
GROUP BY DATE_FORMAT(t.fecha_transaccion, '%Y-%m-01'), c.segmento
ORDER BY mes, c.segmento;
