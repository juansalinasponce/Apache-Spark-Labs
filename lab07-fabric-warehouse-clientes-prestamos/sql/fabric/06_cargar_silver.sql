-- Actividad Script: act_04_cargar_silver.

TRUNCATE TABLE slv.prestamo;
TRUNCATE TABLE slv.cliente;

INSERT INTO slv.cliente (
    id_cliente,
    tipo_documento,
    numero_documento,
    nombre_completo,
    tipo_cliente,
    segmento,
    fecha_registro,
    estado_cliente
)
SELECT
    id_cliente,
    UPPER(TRIM(tipo_documento)),
    TRIM(nro_documento),
    TRIM(nombre_completo),
    UPPER(TRIM(tipo_cliente)),
    UPPER(TRIM(segmento)),
    fecha_registro,
    UPPER(TRIM(estado))
FROM brz.banco_cliente
WHERE id_cliente IS NOT NULL
  AND nombre_completo IS NOT NULL;

INSERT INTO slv.prestamo (
    id_prestamo,
    id_cliente,
    id_sucursal,
    tipo_prestamo,
    monto_desembolso,
    saldo_pendiente,
    tasa_interes_anual,
    numero_cuotas,
    fecha_desembolso,
    estado_prestamo
)
SELECT
    id_prestamo,
    id_cliente,
    id_sucursal,
    UPPER(TRIM(tipo_prestamo)),
    monto_desembolso,
    saldo_pendiente,
    tasa_interes_anual,
    numero_cuotas,
    fecha_desembolso,
    UPPER(TRIM(estado))
FROM brz.banco_prestamo
WHERE id_prestamo IS NOT NULL
  AND id_cliente IS NOT NULL
  AND monto_desembolso > 0
  AND saldo_pendiente >= 0;
