USE u845286110_labs;

-- Debe devolver los volúmenes esperados después de la carga histórica.
SELECT 'banco_canal' AS tabla, COUNT(*) AS filas FROM banco_canal
UNION ALL
SELECT 'banco_cliente', COUNT(*) FROM banco_cliente
UNION ALL
SELECT 'banco_cuenta', COUNT(*) FROM banco_cuenta
UNION ALL
SELECT 'banco_prestamo', COUNT(*) FROM banco_prestamo
UNION ALL
SELECT 'banco_sucursal', COUNT(*) FROM banco_sucursal
UNION ALL
SELECT 'banco_tarjeta', COUNT(*) FROM banco_tarjeta
UNION ALL
SELECT 'banco_transaccion', COUNT(*) FROM banco_transaccion
ORDER BY tabla;

-- Todas estas cantidades deben ser cero.
SELECT
  (
    SELECT COUNT(*)
    FROM banco_cuenta AS cu
    LEFT JOIN banco_cliente AS c ON c.id_cliente = cu.id_cliente
    WHERE c.id_cliente IS NULL
  ) AS cuentas_sin_cliente,
  (
    SELECT COUNT(*)
    FROM banco_tarjeta AS ta
    LEFT JOIN banco_cliente AS c ON c.id_cliente = ta.id_cliente
    WHERE c.id_cliente IS NULL
  ) AS tarjetas_sin_cliente,
  (
    SELECT COUNT(*)
    FROM banco_prestamo AS p
    LEFT JOIN banco_cliente AS c ON c.id_cliente = p.id_cliente
    WHERE c.id_cliente IS NULL
  ) AS prestamos_sin_cliente,
  (
    SELECT COUNT(*)
    FROM banco_prestamo AS p
    LEFT JOIN banco_sucursal AS s ON s.id_sucursal = p.id_sucursal
    WHERE s.id_sucursal IS NULL
  ) AS prestamos_sin_sucursal,
  (
    SELECT COUNT(*)
    FROM banco_transaccion AS t
    LEFT JOIN banco_cuenta AS cu ON cu.id_cuenta = t.id_cuenta
    WHERE cu.id_cuenta IS NULL
  ) AS transacciones_sin_cuenta,
  (
    SELECT COUNT(*)
    FROM banco_transaccion AS t
    LEFT JOIN banco_canal AS ca ON ca.id_canal = t.id_canal
    WHERE ca.id_canal IS NULL
  ) AS transacciones_sin_canal;

-- Reglas básicas de calidad; todos los resultados deben ser cero.
SELECT
  SUM(saldo_actual < 0) AS cuentas_con_saldo_negativo
FROM banco_cuenta;

SELECT
  SUM(saldo_pendiente > monto_desembolso) AS prestamos_inconsistentes,
  SUM(saldo_pendiente < 0) AS prestamos_con_saldo_negativo
FROM banco_prestamo;

SELECT
  SUM(tipo_tarjeta = 'DEBITO' AND linea_credito <> 0) AS debito_con_linea,
  SUM(tipo_tarjeta = 'CREDITO' AND linea_credito <= 0) AS credito_sin_linea
FROM banco_tarjeta;

-- Resumen inicial para comprobar que los datos son analizables.
SELECT
  moneda,
  COUNT(*) AS cuentas,
  ROUND(SUM(saldo_actual), 2) AS saldo_total
FROM banco_cuenta
GROUP BY moneda
ORDER BY moneda;

-- La historia generada debe cubrir 24 meses completos y 730 días sin vacíos.
SELECT
  MIN(fecha_transaccion) AS primera_operacion,
  MAX(fecha_transaccion) AS ultima_operacion,
  COUNT(*) AS transacciones_historicas,
  COUNT(DISTINCT DATE_FORMAT(fecha_transaccion, '%Y-%m')) AS meses_cubiertos,
  COUNT(DISTINCT DATE(fecha_transaccion)) AS dias_cubiertos
FROM banco_transaccion
WHERE codigo_operacion LIKE 'H-%';

-- Cada mes debe contener operaciones de todos los canales y tipos.
SELECT
  DATE_FORMAT(fecha_transaccion, '%Y-%m') AS mes,
  COUNT(*) AS transacciones,
  COUNT(DISTINCT id_canal) AS canales,
  COUNT(DISTINCT tipo_transaccion) AS tipos_transaccion,
  ROUND(SUM(CASE WHEN estado = 'APROBADA' THEN monto ELSE 0 END), 2)
    AS monto_aprobado
FROM banco_transaccion
WHERE codigo_operacion LIKE 'H-%'
GROUP BY DATE_FORMAT(fecha_transaccion, '%Y-%m')
ORDER BY mes;

-- Distribución de estados para probar reglas de rechazo y reversa.
SELECT
  estado,
  COUNT(*) AS transacciones,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS porcentaje
FROM banco_transaccion
WHERE codigo_operacion LIKE 'H-%'
GROUP BY estado
ORDER BY estado;
