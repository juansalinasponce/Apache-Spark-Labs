-- 1. Cotizaciones, ventas, conversión y prima emitida por mes.
WITH cotizaciones AS (
  SELECT
    DATE_FORMAT(fecha_cotizacion, '%Y-%m') AS mes,
    COUNT(*) AS cotizaciones
  FROM aseguradora_cotizacion
  GROUP BY DATE_FORMAT(fecha_cotizacion, '%Y-%m')
),
ventas AS (
  SELECT
    DATE_FORMAT(fecha_emision, '%Y-%m') AS mes,
    COUNT(*) AS polizas,
    SUM(prima_total) AS prima_emitida
  FROM aseguradora_poliza
  GROUP BY DATE_FORMAT(fecha_emision, '%Y-%m')
)
SELECT
  cotizaciones.mes,
  cotizaciones.cotizaciones,
  COALESCE(ventas.polizas, 0) AS polizas,
  ROUND(100 * COALESCE(ventas.polizas, 0) / cotizaciones.cotizaciones, 2) AS conversion_pct,
  ROUND(COALESCE(ventas.prima_emitida, 0), 2) AS prima_emitida
FROM cotizaciones
LEFT JOIN ventas USING (mes)
ORDER BY cotizaciones.mes;

-- 2. Conversión por canal.
SELECT
  canal.nombre_canal,
  COUNT(*) AS cotizaciones,
  SUM(cotizacion.estado = 'CONVERTIDA') AS convertidas,
  ROUND(100 * SUM(cotizacion.estado = 'CONVERTIDA') / COUNT(*), 2) AS conversion_pct
FROM aseguradora_cotizacion AS cotizacion
INNER JOIN aseguradora_canal_venta AS canal
  ON canal.id_canal = cotizacion.id_canal
GROUP BY canal.id_canal, canal.nombre_canal
ORDER BY conversion_pct DESC;

-- 3. Productos con mayor venta y prima emitida.
SELECT
  producto.familia,
  producto.nombre_producto,
  COUNT(*) AS polizas,
  ROUND(SUM(poliza.prima_total), 2) AS prima_emitida,
  ROUND(AVG(poliza.prima_total), 2) AS prima_promedio
FROM aseguradora_poliza AS poliza
INNER JOIN aseguradora_producto AS producto
  ON producto.id_producto = poliza.id_producto
GROUP BY producto.id_producto, producto.familia, producto.nombre_producto
ORDER BY prima_emitida DESC;

-- 4. Ranking de brokers por ventas, prima y comisión.
SELECT
  broker.codigo_broker,
  broker.nombre_broker,
  COUNT(*) AS polizas,
  ROUND(SUM(poliza.prima_total), 2) AS prima_emitida,
  ROUND(SUM(poliza.monto_comision), 2) AS comision_generada,
  DENSE_RANK() OVER (ORDER BY SUM(poliza.prima_total) DESC) AS ranking_prima
FROM aseguradora_poliza AS poliza
INNER JOIN aseguradora_broker AS broker
  ON broker.id_broker = poliza.id_broker
GROUP BY broker.id_broker, broker.codigo_broker, broker.nombre_broker
ORDER BY ranking_prima, broker.codigo_broker;

-- 5. Calidad comercial de la cartera por broker.
WITH ventas AS (
  SELECT
    id_broker,
    COUNT(*) AS polizas,
    SUM(prima_total) AS prima_emitida
  FROM aseguradora_poliza
  WHERE id_broker IS NOT NULL
  GROUP BY id_broker
),
cobranza AS (
  SELECT
    poliza.id_broker,
    SUM(CASE WHEN pago.estado = 'PROCESADO' THEN pago.importe_pagado ELSE 0 END) AS prima_cobrada,
    SUM(CASE WHEN cuota.estado = 'VENCIDA' THEN cuota.saldo_pendiente ELSE 0 END) AS deuda_vencida
  FROM aseguradora_poliza AS poliza
  INNER JOIN aseguradora_cuota AS cuota
    ON cuota.id_poliza = poliza.id_poliza
  LEFT JOIN aseguradora_pago AS pago
    ON pago.id_cuota = cuota.id_cuota
  WHERE poliza.id_broker IS NOT NULL
  GROUP BY poliza.id_broker
),
siniestralidad AS (
  SELECT
    poliza.id_broker,
    COUNT(*) AS siniestros,
    SUM(siniestro.monto_pagado + siniestro.monto_reserva) AS monto_incorrido
  FROM aseguradora_poliza AS poliza
  INNER JOIN aseguradora_siniestro AS siniestro
    ON siniestro.id_poliza = poliza.id_poliza
  WHERE poliza.id_broker IS NOT NULL
  GROUP BY poliza.id_broker
)
SELECT
  broker.nombre_broker,
  ventas.polizas,
  ROUND(ventas.prima_emitida, 2) AS prima_emitida,
  ROUND(COALESCE(cobranza.prima_cobrada, 0), 2) AS prima_cobrada,
  ROUND(COALESCE(cobranza.deuda_vencida, 0), 2) AS deuda_vencida,
  COALESCE(siniestralidad.siniestros, 0) AS siniestros,
  ROUND(COALESCE(siniestralidad.monto_incorrido, 0), 2) AS monto_incorrido,
  ROUND(
    100 * COALESCE(siniestralidad.monto_incorrido, 0) / NULLIF(ventas.prima_emitida, 0),
    2
  ) AS siniestralidad_simplificada_pct
FROM ventas
INNER JOIN aseguradora_broker AS broker
  ON broker.id_broker = ventas.id_broker
LEFT JOIN cobranza
  ON cobranza.id_broker = ventas.id_broker
LEFT JOIN siniestralidad
  ON siniestralidad.id_broker = ventas.id_broker
ORDER BY ventas.prima_emitida DESC;

-- 6. Clientes y ventas por departamento.
SELECT
  ubicacion.departamento,
  COUNT(DISTINCT cliente.id_cliente) AS clientes,
  COUNT(DISTINCT poliza.id_poliza) AS polizas,
  ROUND(COALESCE(SUM(poliza.prima_total), 0), 2) AS prima_emitida
FROM aseguradora_ubicacion AS ubicacion
INNER JOIN aseguradora_cliente AS cliente
  ON cliente.id_ubicacion = ubicacion.id_ubicacion
LEFT JOIN aseguradora_poliza AS poliza
  ON poliza.id_cliente = cliente.id_cliente
GROUP BY ubicacion.departamento
ORDER BY prima_emitida DESC;

-- 7. Cartera de cuotas y morosidad.
SELECT
  DATE_FORMAT(fecha_vencimiento, '%Y-%m') AS mes_vencimiento,
  COUNT(*) AS cuotas,
  ROUND(SUM(importe_cuota), 2) AS importe_programado,
  ROUND(SUM(importe_cuota - saldo_pendiente), 2) AS importe_cobrado,
  ROUND(SUM(CASE WHEN estado = 'VENCIDA' THEN saldo_pendiente ELSE 0 END), 2) AS deuda_vencida,
  ROUND(
    100 * SUM(CASE WHEN estado = 'VENCIDA' THEN saldo_pendiente ELSE 0 END)
      / NULLIF(SUM(importe_cuota), 0),
    2
  ) AS morosidad_pct
FROM aseguradora_cuota
WHERE fecha_vencimiento <= '2026-08-31'
GROUP BY DATE_FORMAT(fecha_vencimiento, '%Y-%m')
ORDER BY mes_vencimiento;

-- 8. Cobranza por medio de pago. Solo cuentan operaciones procesadas.
SELECT
  medio.nombre_medio_pago,
  COUNT(*) AS operaciones,
  ROUND(SUM(pago.importe_pagado), 2) AS importe_cobrado,
  ROUND(AVG(pago.importe_pagado), 2) AS ticket_promedio
FROM aseguradora_pago AS pago
INNER JOIN aseguradora_medio_pago AS medio
  ON medio.id_medio_pago = pago.id_medio_pago
WHERE pago.estado = 'PROCESADO'
GROUP BY medio.id_medio_pago, medio.nombre_medio_pago
ORDER BY importe_cobrado DESC;

-- 9. Frecuencia, severidad y siniestralidad comercial simplificada.
-- En un modelo actuarial se usaría prima devengada y exposición exacta.
WITH cartera AS (
  SELECT
    id_producto,
    COUNT(*) AS polizas,
    SUM(prima_total) AS prima_emitida
  FROM aseguradora_poliza
  GROUP BY id_producto
),
siniestros AS (
  SELECT
    poliza.id_producto,
    COUNT(*) AS siniestros,
    SUM(siniestro.monto_pagado + siniestro.monto_reserva) AS monto_incorrido
  FROM aseguradora_siniestro AS siniestro
  INNER JOIN aseguradora_poliza AS poliza
    ON poliza.id_poliza = siniestro.id_poliza
  GROUP BY poliza.id_producto
)
SELECT
  producto.nombre_producto,
  cartera.polizas,
  COALESCE(siniestros.siniestros, 0) AS siniestros,
  ROUND(100 * COALESCE(siniestros.siniestros, 0) / cartera.polizas, 2) AS frecuencia_pct,
  ROUND(
    COALESCE(siniestros.monto_incorrido, 0) / NULLIF(siniestros.siniestros, 0),
    2
  ) AS severidad_promedio,
  ROUND(
    100 * COALESCE(siniestros.monto_incorrido, 0) / NULLIF(cartera.prima_emitida, 0),
    2
  ) AS siniestralidad_simplificada_pct
FROM cartera
INNER JOIN aseguradora_producto AS producto
  ON producto.id_producto = cartera.id_producto
LEFT JOIN siniestros
  ON siniestros.id_producto = cartera.id_producto
ORDER BY siniestralidad_simplificada_pct DESC;

-- 10. Geografía de los siniestros.
SELECT
  ubicacion.departamento,
  COUNT(*) AS siniestros,
  ROUND(SUM(siniestro.monto_reclamado), 2) AS monto_reclamado,
  ROUND(SUM(siniestro.monto_pagado + siniestro.monto_reserva), 2) AS monto_incorrido
FROM aseguradora_siniestro AS siniestro
INNER JOIN aseguradora_ubicacion AS ubicacion
  ON ubicacion.id_ubicacion = siniestro.id_ubicacion
GROUP BY ubicacion.departamento
ORDER BY monto_incorrido DESC;

-- 11. Clientes con venta cruzada: más de un producto contratado.
SELECT
  cliente.id_cliente,
  cliente.nombre_completo,
  cliente.segmento,
  COUNT(DISTINCT poliza.id_producto) AS productos_distintos,
  COUNT(*) AS polizas,
  ROUND(SUM(poliza.prima_total), 2) AS prima_total
FROM aseguradora_cliente AS cliente
INNER JOIN aseguradora_poliza AS poliza
  ON poliza.id_cliente = cliente.id_cliente
GROUP BY cliente.id_cliente, cliente.nombre_completo, cliente.segmento
HAVING COUNT(DISTINCT poliza.id_producto) > 1
ORDER BY productos_distintos DESC, prima_total DESC
LIMIT 100;

-- 12. Ventas nuevas y renovaciones por mes.
SELECT
  DATE_FORMAT(fecha_emision, '%Y-%m') AS mes,
  SUM(es_renovacion = FALSE) AS ventas_nuevas,
  SUM(es_renovacion = TRUE) AS renovaciones,
  ROUND(100 * SUM(es_renovacion = TRUE) / COUNT(*), 2) AS renovaciones_pct
FROM aseguradora_poliza
GROUP BY DATE_FORMAT(fecha_emision, '%Y-%m')
ORDER BY mes;

-- 13. Watermarks para una ingesta incremental.
SELECT
  'aseguradora_cotizacion' AS tabla,
  MAX(fecha_cotizacion) AS ultima_fecha,
  MAX(id_cotizacion) AS ultimo_id
FROM aseguradora_cotizacion
UNION ALL
SELECT 'aseguradora_poliza', MAX(fecha_emision), MAX(id_poliza)
FROM aseguradora_poliza
UNION ALL
SELECT 'aseguradora_pago', MAX(fecha_pago), MAX(id_pago)
FROM aseguradora_pago
UNION ALL
SELECT 'aseguradora_siniestro', MAX(fecha_reporte), MAX(id_siniestro)
FROM aseguradora_siniestro;
