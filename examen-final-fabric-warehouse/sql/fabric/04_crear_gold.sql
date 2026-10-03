-- Grano: una cuenta, un canal y una transacción respectivamente.
CREATE TABLE gld.dim_cuenta (
    id_cuenta BIGINT NOT NULL,
    id_cliente BIGINT NOT NULL,
    numero_cuenta VARCHAR(24) NOT NULL,
    tipo_cuenta VARCHAR(20) NOT NULL,
    moneda VARCHAR(3) NOT NULL,
    saldo_actual DECIMAL(16,2) NOT NULL,
    fecha_apertura DATE NOT NULL,
    estado VARCHAR(15) NOT NULL
);

CREATE TABLE gld.dim_canal (
    id_canal INT NOT NULL,
    nombre_canal VARCHAR(60) NOT NULL,
    tipo_canal VARCHAR(20) NOT NULL,
    estado VARCHAR(15) NOT NULL
);

CREATE TABLE gld.fct_transaccion (
    id_transaccion BIGINT NOT NULL,
    id_cuenta BIGINT NOT NULL,
    id_canal INT NOT NULL,
    codigo_operacion VARCHAR(30) NOT NULL,
    fecha_transaccion DATETIME2(3) NOT NULL,
    tipo_transaccion VARCHAR(20) NOT NULL,
    naturaleza VARCHAR(10) NOT NULL,
    monto DECIMAL(16,2) NOT NULL,
    descripcion VARCHAR(250) NULL,
    estado VARCHAR(15) NOT NULL,
    fecha DATE NOT NULL
);

CREATE TABLE gld.dim_fecha (
    fecha DATE NOT NULL,
    anio INT NOT NULL,
    mes INT NOT NULL,
    anio_mes VARCHAR(7) NOT NULL
);
