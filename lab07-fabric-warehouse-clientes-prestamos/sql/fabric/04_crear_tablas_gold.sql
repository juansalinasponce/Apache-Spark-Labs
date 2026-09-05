-- Gold contiene un modelo estrella mínimo: una dimensión y un hecho.

CREATE TABLE gld.dim_cliente (
    id_cliente       INT          NOT NULL,
    tipo_documento   VARCHAR(20)  NOT NULL,
    numero_documento VARCHAR(20)  NOT NULL,
    nombre_completo  VARCHAR(150) NOT NULL,
    tipo_cliente     VARCHAR(20)  NOT NULL,
    segmento         VARCHAR(20)  NOT NULL,
    fecha_registro   DATE         NOT NULL,
    estado_cliente   VARCHAR(20)  NOT NULL,
    es_cliente_activo SMALLINT     NOT NULL
);

CREATE TABLE gld.fct_prestamo (
    id_prestamo         INT           NOT NULL,
    id_cliente          INT           NOT NULL,
    id_sucursal         SMALLINT      NOT NULL,
    fecha_desembolso    DATE          NOT NULL,
    anio_desembolso     SMALLINT      NOT NULL,
    mes_desembolso      TINYINT       NOT NULL,
    tipo_prestamo       VARCHAR(30)   NOT NULL,
    monto_desembolso    DECIMAL(16,2) NOT NULL,
    saldo_pendiente     DECIMAL(16,2) NOT NULL,
    monto_pagado        DECIMAL(16,2) NOT NULL,
    tasa_interes_anual  DECIMAL(7,4)  NOT NULL,
    numero_cuotas       SMALLINT      NOT NULL,
    estado_prestamo     VARCHAR(20)   NOT NULL
);
