-- Actividad Script: act_05_cargar_gold.

TRUNCATE TABLE gld.fct_prestamo;
TRUNCATE TABLE gld.dim_cliente;

INSERT INTO gld.dim_cliente (
    id_cliente,
    tipo_documento,
    numero_documento,
    nombre_completo,
    tipo_cliente,
    segmento,
    fecha_registro,
    estado_cliente,
    es_cliente_activo
)
SELECT
    id_cliente,
    tipo_documento,
    numero_documento,
    nombre_completo,
    tipo_cliente,
    segmento,
    fecha_registro,
    estado_cliente,
    CASE WHEN estado_cliente = 'ACTIVO' THEN 1 ELSE 0 END
FROM slv.cliente;

INSERT INTO gld.fct_prestamo (
    id_prestamo,
    id_cliente,
    id_sucursal,
    fecha_desembolso,
    anio_desembolso,
    mes_desembolso,
    tipo_prestamo,
    monto_desembolso,
    saldo_pendiente,
    monto_pagado,
    tasa_interes_anual,
    numero_cuotas,
    estado_prestamo
)
SELECT
    id_prestamo,
    id_cliente,
    id_sucursal,
    fecha_desembolso,
    YEAR(fecha_desembolso),
    MONTH(fecha_desembolso),
    tipo_prestamo,
    monto_desembolso,
    saldo_pendiente,
    monto_desembolso - saldo_pendiente,
    tasa_interes_anual,
    numero_cuotas,
    estado_prestamo
FROM slv.prestamo;
