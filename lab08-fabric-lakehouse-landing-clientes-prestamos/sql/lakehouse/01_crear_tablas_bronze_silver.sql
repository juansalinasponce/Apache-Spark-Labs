-- Lab 08 / Fabric 02
-- Ejecutar con Spark SQL sobre lh_banca_dev_medallion.
-- El Lakehouse debe estar adjunto y tener schemas habilitados.

CREATE SCHEMA IF NOT EXISTS brz;
CREATE SCHEMA IF NOT EXISTS slv;

-- Bronze recibe una copia fiel del origen. Todas las columnas son STRING.
CREATE TABLE IF NOT EXISTS brz.banco_cliente (
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

CREATE TABLE IF NOT EXISTS brz.banco_prestamo (
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

-- Silver tipifica y conserva el historial del cliente con SCD Tipo 2.
CREATE TABLE IF NOT EXISTS slv.cliente (
    cliente_sk        STRING,
    id_cliente        INT,
    tipo_documento    STRING,
    nro_documento     STRING,
    nombre_completo   STRING,
    tipo_cliente      STRING,
    segmento          STRING,
    fecha_registro    DATE,
    email             STRING,
    telefono          STRING,
    estado            STRING,
    creado_en         TIMESTAMP,
    vigente_desde     TIMESTAMP,
    vigente_hasta     TIMESTAMP,
    es_actual         BOOLEAN,
    hash_atributos    STRING,
    fecha_proceso     TIMESTAMP
)
USING DELTA;

-- El préstamo se mantiene con el último estado conocido (SCD Tipo 1).
CREATE TABLE IF NOT EXISTS slv.prestamo (
    id_prestamo         INT,
    id_cliente          INT,
    id_sucursal         SMALLINT,
    tipo_prestamo       STRING,
    monto_desembolso    DECIMAL(16,2),
    saldo_pendiente     DECIMAL(16,2),
    tasa_interes_anual  DECIMAL(7,4),
    numero_cuotas       SMALLINT,
    fecha_desembolso    DATE,
    estado              STRING,
    fecha_proceso       TIMESTAMP
)
USING DELTA;
