-- Genera los enteros 1..36000 sin depender de tablas del sistema.
DROP TEMPORARY TABLE IF EXISTS lab06_sequence;

CREATE TEMPORARY TABLE lab06_sequence (
  n INT UNSIGNED NOT NULL,
  PRIMARY KEY (n)
) ENGINE = InnoDB;

INSERT INTO lab06_sequence (n)
SELECT
  1
  + units.d
  + tens.d * 10
  + hundreds.d * 100
  + thousands.d * 1000
  + ten_thousands.d * 10000 AS n
FROM
  (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9
  ) AS units
CROSS JOIN
  (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9
  ) AS tens
CROSS JOIN
  (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9
  ) AS hundreds
CROSS JOIN
  (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9
  ) AS thousands
CROSS JOIN
  (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9
  ) AS ten_thousands
WHERE
  1
  + units.d
  + tens.d * 10
  + hundreds.d * 100
  + thousands.d * 1000
  + ten_thousands.d * 10000 <= 36000;

START TRANSACTION;

-- 120 brokers sintéticos. Aproximadamente la mitad opera en Lima y Callao.
INSERT INTO aseguradora_broker (
  id_broker,
  id_ubicacion,
  codigo_broker,
  nombre_broker,
  tipo_broker,
  fecha_afiliacion,
  porcentaje_comision,
  meta_prima_mensual,
  estado
)
SELECT
  n,
  CASE
    WHEN MOD(n, 100) < 55 THEN 1 + MOD(n * 7, 14)
    ELSE 15 + MOD(n * 11, 16)
  END,
  CONCAT('BRK-', LPAD(n, 5, '0')),
  CONCAT(
    CASE MOD(n, 4)
      WHEN 0 THEN 'Corredora Proteccion '
      WHEN 1 THEN 'Broker Confianza '
      WHEN 2 THEN 'Agencia Futuro '
      ELSE 'Asesores Integrales '
    END,
    LPAD(n, 3, '0')
  ),
  CASE MOD(n, 4)
    WHEN 0 THEN 'CORREDOR'
    WHEN 1 THEN 'AGENCIA'
    WHEN 2 THEN 'ASESOR'
    ELSE 'ALIANZA_COMERCIAL'
  END,
  DATE_ADD('2017-01-01', INTERVAL MOD(n * 37, 2555) DAY),
  ROUND(5 + MOD(n * 17, 1001) / 100, 2),
  ROUND(12000 + MOD(n * 7919, 68001), 2),
  CASE WHEN MOD(n, 29) = 0 THEN 'INACTIVO' ELSE 'ACTIVO' END
FROM lab06_sequence
WHERE n <= 120;

-- 12 mil clientes sintéticos distribuidos en 30 ubicaciones.
INSERT INTO aseguradora_cliente (
  id_cliente,
  id_ubicacion,
  tipo_documento,
  numero_documento,
  nombre_completo,
  fecha_nacimiento,
  sexo,
  email,
  telefono,
  segmento,
  fecha_registro,
  estado
)
SELECT
  n,
  CASE
    WHEN MOD(n * 13, 100) < 48 THEN 1 + MOD(n * 7, 14)
    ELSE 15 + MOD(n * 11, 16)
  END,
  CASE
    WHEN MOD(n, 31) = 0 THEN 'CE'
    WHEN MOD(n, 97) = 0 THEN 'PASAPORTE'
    ELSE 'DNI'
  END,
  CASE
    WHEN MOD(n, 31) = 0 THEN CONCAT('CE', LPAD(n, 10, '0'))
    WHEN MOD(n, 97) = 0 THEN CONCAT('P', LPAD(n, 9, '0'))
    ELSE LPAD(30000000 + n, 8, '0')
  END,
  CONCAT('Cliente Seguros ', LPAD(n, 5, '0')),
  DATE_ADD('1955-01-01', INTERVAL MOD(n * 97, 17520) DAY),
  CASE MOD(n, 10)
    WHEN 0 THEN 'NO_ESPECIFICA'
    WHEN 1 THEN 'F'
    WHEN 2 THEN 'F'
    WHEN 3 THEN 'F'
    WHEN 4 THEN 'F'
    ELSE 'M'
  END,
  CONCAT('cliente', LPAD(n, 5, '0'), '@seguroslab.example'),
  CONCAT('9', LPAD(10000000 + n, 8, '0')),
  CASE
    WHEN MOD(n * 19, 100) < 20 THEN 'JOVEN'
    WHEN MOD(n * 19, 100) < 50 THEN 'FAMILIA'
    WHEN MOD(n * 19, 100) < 75 THEN 'PROFESIONAL'
    WHEN MOD(n * 19, 100) < 92 THEN 'EMPRENDEDOR'
    ELSE 'PREMIUM'
  END,
  DATE_ADD('2018-01-01', INTERVAL MOD(n * 23, 2435) DAY),
  CASE WHEN MOD(n, 157) = 0 THEN 'INACTIVO' ELSE 'ACTIVO' END
FROM lab06_sequence
WHERE n <= 12000;

-- 36 mil cotizaciones entre 2024-09-01 y 2026-08-31.
-- La tasa de conversión depende del canal para producir un embudo útil.
INSERT INTO aseguradora_cotizacion (
  id_cliente,
  id_producto,
  id_broker,
  id_canal,
  numero_cotizacion,
  fecha_cotizacion,
  prima_cotizada,
  suma_asegurada,
  moneda,
  estado,
  motivo_no_conversion
)
SELECT
  1 + MOD(base.n * 29, 12000),
  base.id_producto,
  CASE WHEN base.id_canal = 1 THEN 1 + MOD(base.n * 17, 120) ELSE NULL END,
  base.id_canal,
  CONCAT('COT-', DATE_FORMAT(base.fecha_cotizacion, '%Y%m'), '-', LPAD(base.n, 8, '0')),
  base.fecha_cotizacion,
  ROUND(producto.prima_base_simulada * (85 + MOD(base.n * 23, 41)) / 100, 2),
  CASE producto.familia
    WHEN 'VEHICULAR' THEN 25000 + MOD(base.n * 7919, 175001)
    WHEN 'HOGAR' THEN 80000 + MOD(base.n * 7919, 420001)
    WHEN 'ACCIDENTES' THEN 20000 + MOD(base.n * 7919, 80001)
    WHEN 'ONCOLOGICO' THEN 8000 + MOD(base.n * 7919, 42001)
    WHEN 'VIDA_AHORRO' THEN 50000 + MOD(base.n * 7919, 450001)
    ELSE 15000 + MOD(base.n * 7919, 85001)
  END,
  'PEN',
  CASE
    WHEN base.conversion_score <
      CASE base.id_canal
        WHEN 1 THEN 72
        WHEN 2 THEN 56
        WHEN 3 THEN 63
        WHEN 4 THEN 46
        WHEN 5 THEN 68
        ELSE 52
      END
    THEN 'CONVERTIDA'
    WHEN MOD(base.n, 4) = 0 THEN 'RECHAZADA'
    ELSE 'EXPIRADA'
  END,
  CASE
    WHEN base.conversion_score <
      CASE base.id_canal
        WHEN 1 THEN 72
        WHEN 2 THEN 56
        WHEN 3 THEN 63
        WHEN 4 THEN 46
        WHEN 5 THEN 68
        ELSE 52
      END
    THEN NULL
    ELSE CASE MOD(base.n, 4)
      WHEN 0 THEN 'RIESGO_NO_ACEPTADO'
      WHEN 1 THEN 'PRECIO'
      WHEN 2 THEN 'SIN_RESPUESTA'
      ELSE 'PREFIERE_COMPETENCIA'
    END
  END
FROM (
  SELECT
    n,
    CASE
      WHEN MOD(n * 7, 100) < 20 THEN 1
      WHEN MOD(n * 7, 100) < 30 THEN 2
      WHEN MOD(n * 7, 100) < 40 THEN 3
      WHEN MOD(n * 7, 100) < 50 THEN 4
      WHEN MOD(n * 7, 100) < 62 THEN 5
      WHEN MOD(n * 7, 100) < 72 THEN 6
      WHEN MOD(n * 7, 100) < 82 THEN 7
      WHEN MOD(n * 7, 100) < 90 THEN 8
      WHEN MOD(n * 7, 100) < 97 THEN 9
      ELSE 10
    END AS id_producto,
    CASE
      WHEN MOD(n * 17, 100) < 40 THEN 1
      WHEN MOD(n * 17, 100) < 60 THEN 2
      WHEN MOD(n * 17, 100) < 75 THEN 3
      WHEN MOD(n * 17, 100) < 85 THEN 4
      WHEN MOD(n * 17, 100) < 95 THEN 5
      ELSE 6
    END AS id_canal,
    MOD(n * 31 + 7, 100) AS conversion_score,
    TIMESTAMP(
      DATE_ADD('2024-09-01', INTERVAL MOD((n - 1) * 37, 730) DAY),
      MAKETIME(MOD(n * 7, 24), MOD(n * 11, 60), MOD(n * 13, 60))
    ) AS fecha_cotizacion
  FROM lab06_sequence
  WHERE n <= 36000
) AS base
INNER JOIN aseguradora_producto AS producto
  ON producto.id_producto = base.id_producto;

-- Cada cotización convertida produce exactamente una póliza anual.
INSERT INTO aseguradora_poliza (
  id_cotizacion,
  id_cliente,
  id_producto,
  id_broker,
  id_canal,
  numero_poliza,
  referencia_riesgo,
  fecha_emision,
  fecha_inicio_vigencia,
  fecha_fin_vigencia,
  prima_neta,
  impuestos,
  prima_total,
  suma_asegurada,
  moneda,
  numero_cuotas,
  porcentaje_comision,
  monto_comision,
  es_renovacion,
  estado
)
SELECT
  emitida.id_cotizacion,
  emitida.id_cliente,
  emitida.id_producto,
  emitida.id_broker,
  emitida.id_canal,
  CONCAT('POL-', DATE_FORMAT(emitida.fecha_emision, '%Y%m'), '-', LPAD(emitida.id_cotizacion, 8, '0')),
  CASE emitida.familia
    WHEN 'VEHICULAR' THEN CONCAT('PLACA-', LPAD(MOD(emitida.id_cliente * 97, 999999), 6, '0'))
    WHEN 'HOGAR' THEN CONCAT('INMUEBLE-', LPAD(emitida.id_cliente, 8, '0'))
    WHEN 'VIAJES' THEN CONCAT('VIAJE-', LPAD(emitida.id_cotizacion, 8, '0'))
    ELSE CONCAT('PERSONA-', LPAD(emitida.id_cliente, 8, '0'))
  END,
  emitida.fecha_emision,
  DATE(emitida.fecha_emision),
  DATE_SUB(DATE_ADD(DATE(emitida.fecha_emision), INTERVAL 1 YEAR), INTERVAL 1 DAY),
  ROUND(emitida.prima_cotizada / 1.18, 2),
  emitida.prima_cotizada - ROUND(emitida.prima_cotizada / 1.18, 2),
  emitida.prima_cotizada,
  emitida.suma_asegurada,
  emitida.moneda,
  CASE
    WHEN MOD(emitida.id_cotizacion, 100) < 15 THEN 1
    WHEN MOD(emitida.id_cotizacion, 100) < 30 THEN 4
    WHEN MOD(emitida.id_cotizacion, 100) < 50 THEN 6
    ELSE 12
  END,
  COALESCE(emitida.porcentaje_comision, 0),
  ROUND(emitida.prima_cotizada * COALESCE(emitida.porcentaje_comision, 0) / 100, 2),
  MOD(emitida.id_cotizacion, 7) = 0,
  CASE
    WHEN DATE_SUB(DATE_ADD(DATE(emitida.fecha_emision), INTERVAL 1 YEAR), INTERVAL 1 DAY) < '2026-08-31'
      THEN CASE WHEN MOD(emitida.id_cotizacion, 100) < 36 THEN 'RENOVADA' ELSE 'VENCIDA' END
    WHEN MOD(emitida.id_cotizacion, 101) = 0 THEN 'CANCELADA'
    WHEN MOD(emitida.id_cotizacion, 97) = 0 THEN 'SUSPENDIDA'
    ELSE 'VIGENTE'
  END
FROM (
  SELECT
    cotizacion.*,
    producto.familia,
    LEAST(
      DATE_ADD(cotizacion.fecha_cotizacion, INTERVAL MOD(cotizacion.id_cotizacion, 4) DAY),
      TIMESTAMP('2026-08-31 23:59:59')
    ) AS fecha_emision,
    broker.porcentaje_comision
  FROM aseguradora_cotizacion AS cotizacion
  INNER JOIN aseguradora_producto AS producto
    ON producto.id_producto = cotizacion.id_producto
  LEFT JOIN aseguradora_broker AS broker
    ON broker.id_broker = cotizacion.id_broker
  WHERE cotizacion.estado = 'CONVERTIDA'
) AS emitida;

-- Cronograma: corte operativo al 2026-08-31.
INSERT INTO aseguradora_cuota (
  id_poliza,
  numero_cuota,
  fecha_emision,
  fecha_vencimiento,
  importe_cuota,
  saldo_pendiente,
  fecha_pago_completo,
  dias_mora,
  estado
)
SELECT
  programada.id_poliza,
  programada.numero_cuota,
  programada.fecha_inicio_vigencia,
  programada.fecha_vencimiento,
  programada.importe_cuota,
  CASE
    WHEN programada.fecha_vencimiento > '2026-08-31' THEN programada.importe_cuota
    WHEN programada.score_pago < 8 THEN programada.importe_cuota
    WHEN programada.score_pago < 12 THEN ROUND(programada.importe_cuota / 2, 2)
    ELSE 0
  END,
  CASE
    WHEN programada.fecha_vencimiento <= '2026-08-31' AND programada.score_pago >= 12
      THEN LEAST(
        '2026-08-31',
        DATE_ADD(
          programada.fecha_vencimiento,
          INTERVAL (CAST(MOD(programada.id_poliza * 3 + programada.numero_cuota * 5, 21) AS SIGNED) - 3) DAY
        )
      )
    ELSE NULL
  END,
  CASE
    WHEN programada.fecha_vencimiento > '2026-08-31' THEN 0
    WHEN programada.score_pago < 12 THEN DATEDIFF('2026-08-31', programada.fecha_vencimiento)
    ELSE GREATEST(
      0,
      DATEDIFF(
        LEAST(
          '2026-08-31',
          DATE_ADD(
            programada.fecha_vencimiento,
            INTERVAL (CAST(MOD(programada.id_poliza * 3 + programada.numero_cuota * 5, 21) AS SIGNED) - 3) DAY
          )
        ),
        programada.fecha_vencimiento
      )
    )
  END,
  CASE
    WHEN programada.fecha_vencimiento > '2026-08-31' THEN 'PENDIENTE'
    WHEN programada.score_pago < 8 THEN 'VENCIDA'
    WHEN programada.score_pago < 12 THEN 'PAGADA_PARCIAL'
    ELSE 'PAGADA'
  END
FROM (
  SELECT
    poliza.id_poliza,
    secuencia.n AS numero_cuota,
    poliza.fecha_inicio_vigencia,
    DATE_ADD(poliza.fecha_inicio_vigencia, INTERVAL (secuencia.n - 1) MONTH) AS fecha_vencimiento,
    CASE
      WHEN secuencia.n < poliza.numero_cuotas THEN ROUND(poliza.prima_total / poliza.numero_cuotas, 2)
      ELSE poliza.prima_total
        - ROUND(poliza.prima_total / poliza.numero_cuotas, 2) * (poliza.numero_cuotas - 1)
    END AS importe_cuota,
    MOD(poliza.id_poliza * 13 + secuencia.n * 7, 100) AS score_pago
  FROM aseguradora_poliza AS poliza
  INNER JOIN lab06_sequence AS secuencia
    ON secuencia.n <= poliza.numero_cuotas
) AS programada;

-- Cobros procesados para cuotas pagadas total o parcialmente.
INSERT INTO aseguradora_pago (
  id_cuota,
  id_medio_pago,
  numero_operacion,
  fecha_pago,
  importe_pagado,
  moneda,
  estado
)
SELECT
  cuota.id_cuota,
  1 + MOD(cuota.id_cuota * 11, 6),
  CONCAT('PAGO-', LPAD(cuota.id_cuota, 12, '0')),
  TIMESTAMP(
    CASE
      WHEN cuota.estado = 'PAGADA' THEN cuota.fecha_pago_completo
      ELSE LEAST('2026-08-31', DATE_ADD(cuota.fecha_vencimiento, INTERVAL 2 DAY))
    END,
    MAKETIME(MOD(cuota.id_cuota * 7, 24), MOD(cuota.id_cuota * 13, 60), 0)
  ),
  cuota.importe_cuota - cuota.saldo_pendiente,
  poliza.moneda,
  'PROCESADO'
FROM aseguradora_cuota AS cuota
INNER JOIN aseguradora_poliza AS poliza
  ON poliza.id_poliza = cuota.id_poliza
WHERE cuota.estado IN ('PAGADA', 'PAGADA_PARCIAL');

-- Algunos intentos rechazados permanecen como actividad transaccional, pero no
-- reducen el saldo de la cuota.
INSERT INTO aseguradora_pago (
  id_cuota,
  id_medio_pago,
  numero_operacion,
  fecha_pago,
  importe_pagado,
  moneda,
  estado
)
SELECT
  cuota.id_cuota,
  1 + MOD(cuota.id_cuota * 5, 6),
  CONCAT('RECH-', LPAD(cuota.id_cuota, 12, '0')),
  TIMESTAMP(
    LEAST('2026-08-31', DATE_ADD(cuota.fecha_vencimiento, INTERVAL 1 DAY)),
    MAKETIME(MOD(cuota.id_cuota * 3, 24), MOD(cuota.id_cuota * 17, 60), 0)
  ),
  cuota.importe_cuota,
  poliza.moneda,
  'RECHAZADO'
FROM aseguradora_cuota AS cuota
INNER JOIN aseguradora_poliza AS poliza
  ON poliza.id_poliza = cuota.id_poliza
WHERE cuota.estado = 'VENCIDA'
  AND MOD(cuota.id_cuota, 4) = 0;

-- 4 mil siniestros sintéticos vinculados a pólizas y tipos compatibles.
INSERT INTO aseguradora_siniestro (
  id_poliza,
  id_tipo_siniestro,
  id_ubicacion,
  numero_siniestro,
  fecha_ocurrencia,
  fecha_reporte,
  monto_reclamado,
  monto_deducible,
  monto_reserva,
  monto_aprobado,
  monto_pagado,
  fecha_cierre,
  estado,
  indicador_fraude
)
SELECT
  calculado.id_poliza,
  calculado.id_tipo_siniestro,
  calculado.id_ubicacion,
  CONCAT('SIN-', DATE_FORMAT(calculado.fecha_reporte, '%Y%m'), '-', LPAD(calculado.n, 8, '0')),
  calculado.fecha_ocurrencia,
  calculado.fecha_reporte,
  calculado.monto_reclamado,
  CASE
    WHEN calculado.familia IN ('VEHICULAR', 'HOGAR') THEN ROUND(calculado.monto_reclamado * 0.10, 2)
    WHEN calculado.familia = 'VIAJES' THEN ROUND(calculado.monto_reclamado * 0.05, 2)
    ELSE 0
  END,
  CASE
    WHEN calculado.score_estado BETWEEN 8 AND 24 THEN ROUND(calculado.monto_reclamado * 0.60, 2)
    WHEN calculado.score_estado BETWEEN 25 AND 39 THEN calculado.monto_aprobado_calculado
    ELSE 0
  END,
  CASE
    WHEN calculado.score_estado >= 25 THEN calculado.monto_aprobado_calculado
    ELSE 0
  END,
  CASE
    WHEN calculado.score_estado >= 40 THEN calculado.monto_aprobado_calculado
    ELSE 0
  END,
  CASE
    WHEN calculado.score_estado < 8 OR calculado.score_estado >= 75
      THEN LEAST(
        '2026-08-31',
        DATE_ADD(DATE(calculado.fecha_reporte), INTERVAL (5 + MOD(calculado.n * 11, 41)) DAY)
      )
    ELSE NULL
  END,
  CASE
    WHEN calculado.score_estado < 8 THEN 'RECHAZADO'
    WHEN calculado.score_estado < 18 THEN 'EN_EVALUACION'
    WHEN calculado.score_estado < 25 THEN 'OBSERVADO'
    WHEN calculado.score_estado < 40 THEN 'APROBADO'
    WHEN calculado.score_estado < 75 THEN 'PAGADO'
    ELSE 'CERRADO'
  END,
  MOD(calculado.n * 19, 100) < 2
FROM (
  SELECT
    base.*,
    ROUND(base.monto_reclamado * (70 + MOD(base.n * 7, 26)) / 100, 2)
      AS monto_aprobado_calculado
  FROM (
    SELECT
      secuencia.n,
      poliza.id_poliza,
      poliza.id_producto,
      producto.familia,
      cliente.id_ubicacion,
      (
        SELECT MIN(tipo.id_tipo_siniestro) + MOD(secuencia.n, COUNT(*))
        FROM aseguradora_tipo_siniestro AS tipo
        WHERE tipo.id_producto = poliza.id_producto
      ) AS id_tipo_siniestro,
      TIMESTAMP(
        DATE_ADD(
          poliza.fecha_inicio_vigencia,
          INTERVAL MOD(
            secuencia.n * 13,
            GREATEST(
              1,
              DATEDIFF(LEAST(poliza.fecha_fin_vigencia, '2026-08-31'), poliza.fecha_inicio_vigencia) + 1
            )
          ) DAY
        ),
        MAKETIME(MOD(secuencia.n * 5, 24), MOD(secuencia.n * 7, 60), 0)
      ) AS fecha_ocurrencia,
      LEAST(
        TIMESTAMP('2026-08-31 23:59:59'),
        TIMESTAMP(
          DATE_ADD(
            DATE_ADD(
              poliza.fecha_inicio_vigencia,
              INTERVAL MOD(
                secuencia.n * 13,
                GREATEST(
                  1,
                  DATEDIFF(LEAST(poliza.fecha_fin_vigencia, '2026-08-31'), poliza.fecha_inicio_vigencia) + 1
                )
              ) DAY
            ),
            INTERVAL MOD(secuencia.n, 6) DAY
          ),
          MAKETIME(MOD(secuencia.n * 5, 24), MOD(secuencia.n * 7, 60), 0)
        )
      ) AS fecha_reporte,
      CASE producto.familia
        WHEN 'VEHICULAR' THEN 1200 + MOD(secuencia.n * 7919, 58801)
        WHEN 'HOGAR' THEN 900 + MOD(secuencia.n * 7919, 79101)
        WHEN 'ACCIDENTES' THEN 5000 + MOD(secuencia.n * 7919, 45001)
        WHEN 'ONCOLOGICO' THEN 3000 + MOD(secuencia.n * 7919, 17001)
        WHEN 'VIDA_AHORRO' THEN 20000 + MOD(secuencia.n * 7919, 180001)
        ELSE 400 + MOD(secuencia.n * 7919, 19601)
      END AS monto_reclamado,
      MOD(secuencia.n * 23 + 3, 100) AS score_estado
    FROM lab06_sequence AS secuencia
    CROSS JOIN (
      SELECT MIN(id_poliza) AS primera_poliza, COUNT(*) AS total_polizas
      FROM aseguradora_poliza
    ) AS cantidad
    INNER JOIN aseguradora_poliza AS poliza
      ON poliza.id_poliza = cantidad.primera_poliza
        + MOD((secuencia.n - 1) * 37, cantidad.total_polizas)
    INNER JOIN aseguradora_producto AS producto
      ON producto.id_producto = poliza.id_producto
    INNER JOIN aseguradora_cliente AS cliente
      ON cliente.id_cliente = poliza.id_cliente
    WHERE secuencia.n <= 4000
  ) AS base
) AS calculado;

COMMIT;

DROP TEMPORARY TABLE IF EXISTS lab06_sequence;
