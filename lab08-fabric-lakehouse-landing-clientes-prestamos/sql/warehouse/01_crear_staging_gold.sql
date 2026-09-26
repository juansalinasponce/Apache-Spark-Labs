-- Ejecutar una sola vez en wh_banca_dev_gold con T-SQL.

CREATE SCHEMA stg;
GO

CREATE SCHEMA gld;
GO

-- Staging recibe una copia completa de las tablas Silver del Lakehouse.
CREATE TABLE stg.cliente (
    cliente_sk        VARCHAR(64)   NOT NULL,
    id_cliente        INT           NOT NULL,
    tipo_documento    VARCHAR(20)   NULL,
    nro_documento     VARCHAR(20)   NULL,
    nombre_completo   VARCHAR(150)  NULL,
    tipo_cliente      VARCHAR(20)   NULL,
    segmento          VARCHAR(20)   NULL,
    fecha_registro    DATE          NULL,
    email             VARCHAR(150)  NULL,
    telefono          VARCHAR(20)   NULL,
    estado            VARCHAR(20)   NULL,
    creado_en         DATETIME2(6)  NULL,
    vigente_desde     DATETIME2(6)  NOT NULL,
    vigente_hasta     DATETIME2(6)  NOT NULL,
    es_actual         BIT           NOT NULL,
    hash_atributos    VARCHAR(64)   NOT NULL,
    fecha_proceso     DATETIME2(6)  NOT NULL
);

CREATE TABLE stg.prestamo (
    id_prestamo         INT           NOT NULL,
    id_cliente          INT           NOT NULL,
    id_sucursal         SMALLINT      NULL,
    tipo_prestamo       VARCHAR(30)   NULL,
    monto_desembolso    DECIMAL(16,2) NULL,
    saldo_pendiente     DECIMAL(16,2) NULL,
    tasa_interes_anual  DECIMAL(7,4)  NULL,
    numero_cuotas       SMALLINT      NULL,
    fecha_desembolso    DATE          NULL,
    estado              VARCHAR(20)   NULL,
    fecha_proceso       DATETIME2(6)  NOT NULL
);

CREATE TABLE gld.dim_cliente (
    cliente_sk        VARCHAR(64)   NOT NULL,
    id_cliente        INT           NOT NULL,
    tipo_documento    VARCHAR(20)   NULL,
    nro_documento     VARCHAR(20)   NULL,
    nombre_completo   VARCHAR(150)  NULL,
    tipo_cliente      VARCHAR(20)   NULL,
    segmento          VARCHAR(20)   NULL,
    fecha_registro    DATE          NULL,
    email             VARCHAR(150)  NULL,
    telefono          VARCHAR(20)   NULL,
    estado            VARCHAR(20)   NULL,
    vigente_desde     DATETIME2(6)  NOT NULL,
    vigente_hasta     DATETIME2(6)  NOT NULL,
    es_actual         BIT           NOT NULL,
    fecha_carga       DATETIME2(6)  NOT NULL
);

CREATE TABLE gld.fct_prestamo (
    id_prestamo         INT           NOT NULL,
    cliente_sk          VARCHAR(64)   NOT NULL,
    id_cliente          INT           NOT NULL,
    id_sucursal         SMALLINT      NULL,
    tipo_prestamo       VARCHAR(30)   NULL,
    fecha_desembolso    DATE          NULL,
    anio_desembolso     SMALLINT      NULL,
    mes_desembolso      TINYINT       NULL,
    monto_desembolso    DECIMAL(16,2) NULL,
    saldo_pendiente     DECIMAL(16,2) NULL,
    monto_pagado        DECIMAL(16,2) NULL,
    tasa_interes_anual  DECIMAL(7,4)  NULL,
    numero_cuotas       SMALLINT      NULL,
    estado              VARCHAR(20)   NULL,
    fecha_carga         DATETIME2(6)  NOT NULL
);
