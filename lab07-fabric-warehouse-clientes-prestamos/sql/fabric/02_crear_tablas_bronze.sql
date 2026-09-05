-- Bronze conserva los nombres y columnas principales del origen MySQL.

CREATE TABLE brz.banco_cliente (
    id_cliente       INT          NOT NULL,
    tipo_documento   VARCHAR(20)  NOT NULL,
    nro_documento    VARCHAR(20)  NOT NULL,
    nombre_completo  VARCHAR(150) NOT NULL,
    tipo_cliente     VARCHAR(20)  NOT NULL,
    segmento         VARCHAR(20)  NOT NULL,
    fecha_registro   DATE         NOT NULL,
    email            VARCHAR(150) NULL,
    telefono         VARCHAR(20)  NULL,
    estado           VARCHAR(20)  NOT NULL,
    creado_en        DATETIME2(0) NOT NULL
);

CREATE TABLE brz.banco_prestamo (
    id_prestamo         INT           NOT NULL,
    id_cliente          INT           NOT NULL,
    id_sucursal         SMALLINT      NOT NULL,
    tipo_prestamo       VARCHAR(30)   NOT NULL,
    monto_desembolso    DECIMAL(16,2) NOT NULL,
    saldo_pendiente     DECIMAL(16,2) NOT NULL,
    tasa_interes_anual  DECIMAL(7,4)  NOT NULL,
    numero_cuotas       SMALLINT      NOT NULL,
    fecha_desembolso    DATE          NOT NULL,
    estado              VARCHAR(20)   NOT NULL
);
