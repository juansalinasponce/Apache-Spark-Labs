-- DDL inicial. No volver a ejecutar si las tablas ya existen.
CREATE TABLE slv.cuenta (
    id_cuenta BIGINT NULL,
    id_cliente BIGINT NULL,
    numero_cuenta VARCHAR(24) NULL,
    tipo_cuenta VARCHAR(20) NULL,
    moneda VARCHAR(3) NULL,
    saldo_actual DECIMAL(16,2) NULL,
    fecha_apertura DATE NULL,
    estado VARCHAR(15) NULL
);

CREATE TABLE slv.canal (
    id_canal INT NULL,
    nombre_canal VARCHAR(60) NULL,
    tipo_canal VARCHAR(20) NULL,
    estado VARCHAR(15) NULL
);

CREATE TABLE slv.transaccion (
    id_transaccion BIGINT NULL,
    id_cuenta BIGINT NULL,
    id_canal INT NULL,
    codigo_operacion VARCHAR(30) NULL,
    fecha_transaccion DATETIME2(3) NULL,
    tipo_transaccion VARCHAR(20) NULL,
    naturaleza VARCHAR(10) NULL,
    monto DECIMAL(16,2) NULL,
    descripcion VARCHAR(250) NULL,
    estado VARCHAR(15) NULL
);
