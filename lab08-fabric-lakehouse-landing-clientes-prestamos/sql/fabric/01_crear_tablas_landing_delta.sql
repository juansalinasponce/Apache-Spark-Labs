-- Lab 08 / Fabric 02
-- Ejecutar con Spark SQL sobre el Lakehouse lh_banca_dev_landing.
-- El Lakehouse debe estar adjunto a la sesión y tener schemas habilitados.
-- No ejecutar este script en el SQL analytics endpoint ni en un Warehouse.

CREATE SCHEMA IF NOT EXISTS landing;

CREATE TABLE IF NOT EXISTS landing.banco_cliente (
    id_cliente       STRING,
    tipo_documento   STRING,
    nro_documento    STRING,
    nombre_completo  STRING,
    tipo_cliente     STRING,
    segmento         STRING,
    fecha_registro   STRING,
    email            STRING,
    telefono         STRING,
    estado           STRING,
    creado_en        STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS landing.banco_prestamo (
    id_prestamo         STRING,
    id_cliente          STRING,
    id_sucursal         STRING,
    tipo_prestamo       STRING,
    monto_desembolso    STRING,
    saldo_pendiente     STRING,
    tasa_interes_anual  STRING,
    numero_cuotas       STRING,
    fecha_desembolso    STRING,
    estado              STRING
)
USING DELTA;

-- Comprobaciones rápidas.
SHOW TABLES IN landing;

DESCRIBE DETAIL landing.banco_cliente;
DESCRIBE DETAIL landing.banco_prestamo;
