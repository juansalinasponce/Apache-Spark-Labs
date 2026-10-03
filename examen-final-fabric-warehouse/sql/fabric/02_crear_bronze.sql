-- DDL inicial. No volver a ejecutar si las tablas ya existen.
CREATE TABLE brz.banco_cuenta (
    id_cuenta VARCHAR(250) NULL,
    id_cliente VARCHAR(250) NULL,
    numero_cuenta VARCHAR(250) NULL,
    tipo_cuenta VARCHAR(250) NULL,
    moneda VARCHAR(250) NULL,
    saldo_actual VARCHAR(250) NULL,
    fecha_apertura VARCHAR(250) NULL,
    estado VARCHAR(250) NULL
);

CREATE TABLE brz.banco_canal (
    id_canal VARCHAR(250) NULL,
    nombre_canal VARCHAR(250) NULL,
    tipo_canal VARCHAR(250) NULL,
    estado VARCHAR(250) NULL
);

CREATE TABLE brz.banco_transaccion (
    id_transaccion VARCHAR(250) NULL,
    id_cuenta VARCHAR(250) NULL,
    id_canal VARCHAR(250) NULL,
    codigo_operacion VARCHAR(250) NULL,
    fecha_transaccion VARCHAR(250) NULL,
    tipo_transaccion VARCHAR(250) NULL,
    naturaleza VARCHAR(250) NULL,
    monto VARCHAR(250) NULL,
    descripcion VARCHAR(250) NULL,
    estado VARCHAR(250) NULL
);
