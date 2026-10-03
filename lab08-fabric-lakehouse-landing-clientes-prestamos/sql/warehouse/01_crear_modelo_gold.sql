-- Ejecutar una sola vez en wh_banca_dev_gold.

CREATE SCHEMA gld;
GO

-- La dimensión conserva todas las versiones creadas en Silver.
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

-- IDENTITY genera una clave sustituta administrada por el Warehouse.
CREATE TABLE gld.dim_tipo_prestamo (
    tipo_prestamo_sk      BIGINT IDENTITY,
    tipo_prestamo         VARCHAR(30)  NOT NULL,
    fecha_carga           DATETIME2(6) NOT NULL,
    fecha_actualizacion   DATETIME2(6) NOT NULL
);

CREATE TABLE gld.fct_prestamo (
    id_prestamo         INT           NOT NULL,
    cliente_sk          VARCHAR(64)   NOT NULL,
    tipo_prestamo_sk    BIGINT        NOT NULL,
    id_cliente          INT           NOT NULL,
    id_sucursal         SMALLINT      NULL,
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
