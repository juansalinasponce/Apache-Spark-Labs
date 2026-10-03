USE u845286110_labs;

-- Genera los enteros 1..50000 sin depender de tablas del sistema.
DROP TEMPORARY TABLE IF EXISTS lab_sequence;

CREATE TEMPORARY TABLE lab_sequence (
  n INT UNSIGNED NOT NULL,
  PRIMARY KEY (n)
) ENGINE = InnoDB;

INSERT INTO lab_sequence (n)
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
  + ten_thousands.d * 10000 <= 50000;

START TRANSACTION;

-- 500 clientes: 450 personas naturales y 50 empresas.
INSERT INTO banco_cliente (
  id_cliente,
  tipo_documento,
  nro_documento,
  nombre_completo,
  tipo_cliente,
  segmento,
  fecha_registro,
  email,
  telefono,
  estado
)
SELECT
  1000 + n,
  CASE WHEN MOD(n, 10) = 0 THEN 'RUC' ELSE 'DNI' END,
  CASE
    WHEN MOD(n, 10) = 0 THEN CONCAT('20', LPAD(300000000 + n, 9, '0'))
    ELSE LPAD(10000000 + n, 8, '0')
  END,
  CASE
    WHEN MOD(n, 10) = 0 THEN CONCAT('Empresa Histórica ', LPAD(n, 4, '0'), ' SAC')
    ELSE CONCAT('Cliente Histórico ', LPAD(n, 4, '0'))
  END,
  CASE WHEN MOD(n, 10) = 0 THEN 'JURIDICA' ELSE 'NATURAL' END,
  CASE
    WHEN MOD(n, 20) = 0 THEN 'EMPRESA'
    WHEN MOD(n, 10) = 0 THEN 'PYME'
    WHEN MOD(n, 5) = 0 THEN 'PREFERENTE'
    ELSE 'MASIVO'
  END,
  DATE_ADD('2018-01-01', INTERVAL MOD(n * 17, 2400) DAY),
  CONCAT('cliente', LPAD(n, 4, '0'), '@banklab.example'),
  CONCAT('9', LPAD(n, 8, '0')),
  CASE WHEN MOD(n, 50) = 0 THEN 'INACTIVO' ELSE 'ACTIVO' END
FROM lab_sequence
WHERE n <= 500;

-- 800 cuentas: todos los clientes tienen al menos una y 300 tienen una segunda.
INSERT INTO banco_cuenta (
  id_cuenta,
  id_cliente,
  numero_cuenta,
  tipo_cuenta,
  moneda,
  saldo_actual,
  fecha_apertura,
  estado
)
SELECT
  1000 + n,
  1001 + MOD(n - 1, 500),
  CONCAT('HIST-', LPAD(n, 10, '0')),
  CASE
    WHEN MOD(MOD(n - 1, 500) + 1, 10) = 0 THEN 'CORRIENTE'
    WHEN MOD(n, 8) = 0 THEN 'PLAZO_FIJO'
    ELSE 'AHORROS'
  END,
  CASE WHEN MOD(n, 5) = 0 THEN 'USD' ELSE 'PEN' END,
  CASE
    WHEN MOD(MOD(n - 1, 500) + 1, 10) = 0
      THEN ROUND(25000 + MOD(n * 7919, 47500000) / 100, 2)
    ELSE ROUND(500 + MOD(n * 7919, 2500000) / 100, 2)
  END,
  DATE_ADD('2018-02-01', INTERVAL MOD(n * 19, 2350) DAY),
  CASE
    WHEN MOD(n, 100) = 0 THEN 'BLOQUEADA'
    WHEN MOD(n, 157) = 0 THEN 'CERRADA'
    ELSE 'ACTIVA'
  END
FROM lab_sequence
WHERE n <= 800;

-- 400 tarjetas sin almacenar números reales.
INSERT INTO banco_tarjeta (
  id_tarjeta,
  id_cliente,
  numero_enmascarado,
  tipo_tarjeta,
  marca,
  linea_credito,
  fecha_emision,
  fecha_vencimiento,
  estado
)
SELECT
  1000 + n,
  1000 + n,
  CONCAT('**** **** 9', LPAD(n, 7, '0')),
  CASE WHEN MOD(n, 3) = 0 THEN 'CREDITO' ELSE 'DEBITO' END,
  CASE
    WHEN MOD(n, 5) = 0 THEN 'AMEX'
    WHEN MOD(n, 2) = 0 THEN 'MASTERCARD'
    ELSE 'VISA'
  END,
  CASE
    WHEN MOD(n, 3) = 0 THEN 3000 + MOD(n * 997, 47000)
    ELSE 0
  END,
  DATE_ADD('2021-01-01', INTERVAL MOD(n * 23, 1200) DAY),
  DATE_ADD(
    DATE_ADD('2021-01-01', INTERVAL MOD(n * 23, 1200) DAY),
    INTERVAL 8 YEAR
  ),
  CASE
    WHEN MOD(n, 97) = 0 THEN 'BLOQUEADA'
    WHEN MOD(n, 131) = 0 THEN 'CANCELADA'
    ELSE 'ACTIVA'
  END
FROM lab_sequence
WHERE n <= 400;

-- 180 préstamos con estados y saldos variados.
INSERT INTO banco_prestamo (
  id_prestamo,
  id_cliente,
  id_sucursal,
  tipo_prestamo,
  monto_desembolso,
  saldo_pendiente,
  tasa_interes_anual,
  numero_cuotas,
  fecha_desembolso,
  estado
)
SELECT
  1000 + n,
  1000 + n,
  1 + MOD(n - 1, 6),
  CASE MOD(n, 4)
    WHEN 0 THEN 'CONSUMO'
    WHEN 1 THEN 'HIPOTECARIO'
    WHEN 2 THEN 'VEHICULAR'
    ELSE 'EMPRESARIAL'
  END,
  CASE MOD(n, 4)
    WHEN 0 THEN 5000 + MOD(n * 1543, 45000)
    WHEN 1 THEN 150000 + MOD(n * 1543, 450000)
    WHEN 2 THEN 35000 + MOD(n * 1543, 115000)
    ELSE 80000 + MOD(n * 1543, 420000)
  END AS monto_desembolso,
  CASE
    WHEN MOD(n, 19) = 0 THEN 0
    ELSE ROUND(
      (
        CASE MOD(n, 4)
          WHEN 0 THEN 5000 + MOD(n * 1543, 45000)
          WHEN 1 THEN 150000 + MOD(n * 1543, 450000)
          WHEN 2 THEN 35000 + MOD(n * 1543, 115000)
          ELSE 80000 + MOD(n * 1543, 420000)
        END
      ) * (40 + MOD(n * 7, 55)) / 100,
      2
    )
  END AS saldo_pendiente,
  ROUND(7.5 + MOD(n * 37, 1500) / 100, 4),
  CASE MOD(n, 4)
    WHEN 0 THEN 24
    WHEN 1 THEN 240
    WHEN 2 THEN 60
    ELSE 72
  END,
  DATE_ADD('2022-01-01', INTERVAL MOD(n * 29, 950) DAY),
  CASE
    WHEN MOD(n, 19) = 0 THEN 'PAGADO'
    WHEN MOD(n, 23) = 0 THEN 'VENCIDO'
    ELSE 'VIGENTE'
  END
FROM lab_sequence
WHERE n <= 180;

-- 50,000 operaciones durante 730 días: 2024-09-01 a 2026-08-31.
INSERT INTO banco_transaccion (
  id_transaccion,
  id_cuenta,
  id_canal,
  codigo_operacion,
  fecha_transaccion,
  tipo_transaccion,
  naturaleza,
  monto,
  descripcion,
  estado
)
SELECT
  100000 + n,
  1001 + MOD(n * 37 - 1, 800),
  1 + MOD(n * 13, 5),
  CONCAT('H-', LPAD(n, 8, '0')),
  DATE_ADD(
    DATE_ADD('2024-09-01 00:00:00', INTERVAL MOD(n * 37, 730) DAY),
    INTERVAL MOD(n * 7919, 86400) SECOND
  ),
  CASE MOD(n, 6)
    WHEN 0 THEN 'DEPOSITO'
    WHEN 1 THEN 'RETIRO'
    WHEN 2 THEN 'TRANSFERENCIA'
    WHEN 3 THEN 'COMPRA'
    WHEN 4 THEN 'PAGO'
    ELSE 'COMISION'
  END,
  CASE
    WHEN MOD(n, 6) = 0 THEN 'CREDITO'
    WHEN MOD(n, 6) = 2 AND MOD(n, 4) = 0 THEN 'CREDITO'
    ELSE 'DEBITO'
  END,
  CASE
    WHEN MOD(MOD(n * 37 - 1, 800) + 1, 10) = 0
      THEN ROUND(500 + MOD(n * 104729, 25000000) / 100, 2)
    ELSE ROUND(5 + MOD(n * 104729, 800000) / 100, 2)
  END,
  CASE MOD(n, 6)
    WHEN 0 THEN 'Depósito o abono en cuenta'
    WHEN 1 THEN 'Retiro de fondos'
    WHEN 2 THEN 'Transferencia entre cuentas'
    WHEN 3 THEN 'Compra en comercio'
    WHEN 4 THEN 'Pago de servicio u obligación'
    ELSE 'Comisión bancaria'
  END,
  CASE
    WHEN MOD(n, 100) < 96 THEN 'APROBADA'
    WHEN MOD(n, 100) < 98 THEN 'RECHAZADA'
    ELSE 'REVERSADA'
  END
FROM lab_sequence
WHERE n <= 50000;

COMMIT;

DROP TEMPORARY TABLE IF EXISTS lab_sequence;
