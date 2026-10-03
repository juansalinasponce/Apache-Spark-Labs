-- 1. Conteo de filas por tabla.
SELECT 'aseguradora_ubicacion' AS tabla, COUNT(*) AS filas FROM aseguradora_ubicacion
UNION ALL SELECT 'aseguradora_producto', COUNT(*) FROM aseguradora_producto
UNION ALL SELECT 'aseguradora_broker', COUNT(*) FROM aseguradora_broker
UNION ALL SELECT 'aseguradora_canal_venta', COUNT(*) FROM aseguradora_canal_venta
UNION ALL SELECT 'aseguradora_medio_pago', COUNT(*) FROM aseguradora_medio_pago
UNION ALL SELECT 'aseguradora_cliente', COUNT(*) FROM aseguradora_cliente
UNION ALL SELECT 'aseguradora_cotizacion', COUNT(*) FROM aseguradora_cotizacion
UNION ALL SELECT 'aseguradora_poliza', COUNT(*) FROM aseguradora_poliza
UNION ALL SELECT 'aseguradora_cuota', COUNT(*) FROM aseguradora_cuota
UNION ALL SELECT 'aseguradora_pago', COUNT(*) FROM aseguradora_pago
UNION ALL SELECT 'aseguradora_tipo_siniestro', COUNT(*) FROM aseguradora_tipo_siniestro
UNION ALL SELECT 'aseguradora_siniestro', COUNT(*) FROM aseguradora_siniestro
ORDER BY tabla;

-- 2. La historia de cotizaciones debe cubrir 24 meses y los 730 días.
SELECT
  MIN(fecha_cotizacion) AS primera_cotizacion,
  MAX(fecha_cotizacion) AS ultima_cotizacion,
  COUNT(DISTINCT DATE_FORMAT(fecha_cotizacion, '%Y-%m')) AS meses,
  COUNT(DISTINCT DATE(fecha_cotizacion)) AS dias
FROM aseguradora_cotizacion;

-- 3. Distribución mensual de los procesos comerciales y transaccionales.
WITH meses AS (
  SELECT DISTINCT DATE_FORMAT(fecha_cotizacion, '%Y-%m') AS mes
  FROM aseguradora_cotizacion
),
cotizaciones AS (
  SELECT DATE_FORMAT(fecha_cotizacion, '%Y-%m') AS mes, COUNT(*) AS cantidad
  FROM aseguradora_cotizacion
  GROUP BY DATE_FORMAT(fecha_cotizacion, '%Y-%m')
),
polizas AS (
  SELECT DATE_FORMAT(fecha_emision, '%Y-%m') AS mes, COUNT(*) AS cantidad
  FROM aseguradora_poliza
  GROUP BY DATE_FORMAT(fecha_emision, '%Y-%m')
),
pagos AS (
  SELECT DATE_FORMAT(fecha_pago, '%Y-%m') AS mes, COUNT(*) AS cantidad
  FROM aseguradora_pago
  GROUP BY DATE_FORMAT(fecha_pago, '%Y-%m')
),
siniestros AS (
  SELECT DATE_FORMAT(fecha_reporte, '%Y-%m') AS mes, COUNT(*) AS cantidad
  FROM aseguradora_siniestro
  GROUP BY DATE_FORMAT(fecha_reporte, '%Y-%m')
)
SELECT
  meses.mes,
  COALESCE(cotizaciones.cantidad, 0) AS cotizaciones,
  COALESCE(polizas.cantidad, 0) AS polizas,
  COALESCE(pagos.cantidad, 0) AS pagos,
  COALESCE(siniestros.cantidad, 0) AS siniestros
FROM meses
LEFT JOIN cotizaciones USING (mes)
LEFT JOIN polizas USING (mes)
LEFT JOIN pagos USING (mes)
LEFT JOIN siniestros USING (mes)
ORDER BY meses.mes;

-- 4. Todas las cotizaciones convertidas deben tener una póliza.
SELECT COUNT(*) AS convertidas_sin_poliza
FROM aseguradora_cotizacion AS cotizacion
LEFT JOIN aseguradora_poliza AS poliza
  ON poliza.id_cotizacion = cotizacion.id_cotizacion
WHERE cotizacion.estado = 'CONVERTIDA'
  AND poliza.id_poliza IS NULL;

-- 5. Ninguna póliza debe proceder de una cotización no convertida.
SELECT COUNT(*) AS polizas_de_cotizacion_no_convertida
FROM aseguradora_poliza AS poliza
INNER JOIN aseguradora_cotizacion AS cotizacion
  ON cotizacion.id_cotizacion = poliza.id_cotizacion
WHERE cotizacion.estado <> 'CONVERTIDA';

-- 6. Las dimensiones de una póliza deben coincidir con su cotización.
SELECT COUNT(*) AS polizas_con_dimensiones_inconsistentes
FROM aseguradora_poliza AS poliza
INNER JOIN aseguradora_cotizacion AS cotizacion
  ON cotizacion.id_cotizacion = poliza.id_cotizacion
WHERE poliza.id_cliente <> cotizacion.id_cliente
   OR poliza.id_producto <> cotizacion.id_producto
   OR poliza.id_canal <> cotizacion.id_canal
   OR NOT (poliza.id_broker <=> cotizacion.id_broker);

-- 7. La suma de cuotas debe ser igual a la prima total de la póliza.
SELECT COUNT(*) AS polizas_con_cronograma_desbalanceado
FROM (
  SELECT
    poliza.id_poliza
  FROM aseguradora_poliza AS poliza
  INNER JOIN aseguradora_cuota AS cuota
    ON cuota.id_poliza = poliza.id_poliza
  GROUP BY poliza.id_poliza, poliza.prima_total, poliza.numero_cuotas
  HAVING COUNT(*) <> poliza.numero_cuotas
     OR ABS(SUM(cuota.importe_cuota) - poliza.prima_total) > 0.01
) AS diferencias;

-- 8. El importe procesado por cuota debe explicar lo pagado y el saldo.
SELECT COUNT(*) AS cuotas_con_pago_inconsistente
FROM (
  SELECT
    cuota.id_cuota
  FROM aseguradora_cuota AS cuota
  LEFT JOIN aseguradora_pago AS pago
    ON pago.id_cuota = cuota.id_cuota
  GROUP BY cuota.id_cuota, cuota.importe_cuota, cuota.saldo_pendiente
  HAVING ABS(
    COALESCE(SUM(CASE WHEN pago.estado = 'PROCESADO' THEN pago.importe_pagado ELSE 0 END), 0)
    - (cuota.importe_cuota - cuota.saldo_pendiente)
  ) > 0.01
) AS diferencias;

-- 9. El tipo de siniestro debe corresponder al producto de la póliza.
SELECT COUNT(*) AS siniestros_con_tipo_incompatible
FROM aseguradora_siniestro AS siniestro
INNER JOIN aseguradora_poliza AS poliza
  ON poliza.id_poliza = siniestro.id_poliza
INNER JOIN aseguradora_tipo_siniestro AS tipo
  ON tipo.id_tipo_siniestro = siniestro.id_tipo_siniestro
WHERE poliza.id_producto <> tipo.id_producto;

-- 10. El evento debe ocurrir dentro de la vigencia de la póliza.
SELECT COUNT(*) AS siniestros_fuera_de_vigencia
FROM aseguradora_siniestro AS siniestro
INNER JOIN aseguradora_poliza AS poliza
  ON poliza.id_poliza = siniestro.id_poliza
WHERE DATE(siniestro.fecha_ocurrencia) < poliza.fecha_inicio_vigencia
   OR DATE(siniestro.fecha_ocurrencia) > poliza.fecha_fin_vigencia;

-- 11. Control adicional de importes de siniestros.
SELECT COUNT(*) AS siniestros_con_importes_invalidos
FROM aseguradora_siniestro
WHERE monto_reclamado <= 0
   OR monto_deducible < 0
   OR monto_reserva < 0
   OR monto_aprobado < 0
   OR monto_pagado < 0
   OR monto_aprobado > monto_reclamado
   OR monto_pagado > monto_aprobado;

-- 12. Cada mes debe contener los 10 productos y los 6 canales.
SELECT
  DATE_FORMAT(fecha_cotizacion, '%Y-%m') AS mes,
  COUNT(DISTINCT id_producto) AS productos,
  COUNT(DISTINCT id_canal) AS canales
FROM aseguradora_cotizacion
GROUP BY DATE_FORMAT(fecha_cotizacion, '%Y-%m')
HAVING productos <> 10 OR canales <> 6;
