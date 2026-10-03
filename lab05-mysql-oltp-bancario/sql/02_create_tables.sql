USE u845286110_labs;

CREATE TABLE IF NOT EXISTS banco_cliente (
  id_cliente INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_documento ENUM('DNI', 'CE', 'RUC', 'PASAPORTE') NOT NULL,
  nro_documento VARCHAR(20) NOT NULL,
  nombre_completo VARCHAR(150) NOT NULL,
  tipo_cliente ENUM('NATURAL', 'JURIDICA') NOT NULL,
  segmento ENUM('MASIVO', 'PREFERENTE', 'PYME', 'EMPRESA') NOT NULL,
  fecha_registro DATE NOT NULL,
  email VARCHAR(150) NULL,
  telefono VARCHAR(20) NULL,
  estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_cliente),
  UNIQUE KEY uk_cliente_documento (tipo_documento, nro_documento),
  UNIQUE KEY uk_cliente_email (email),
  KEY ix_cliente_segmento_estado (segmento, estado),
  CONSTRAINT chk_cliente_documento
    CHECK (CHAR_LENGTH(TRIM(nro_documento)) >= 8)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS banco_sucursal (
  id_sucursal SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_sucursal VARCHAR(100) NOT NULL,
  ciudad VARCHAR(80) NOT NULL,
  region VARCHAR(80) NOT NULL,
  fecha_apertura DATE NOT NULL,
  estado ENUM('ACTIVA', 'INACTIVA') NOT NULL DEFAULT 'ACTIVA',
  PRIMARY KEY (id_sucursal),
  UNIQUE KEY uk_sucursal_nombre_ciudad (nombre_sucursal, ciudad),
  KEY ix_sucursal_region (region)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS banco_canal (
  id_canal TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_canal VARCHAR(60) NOT NULL,
  tipo_canal ENUM('PRESENCIAL', 'DIGITAL', 'AUTOSERVICIO', 'COMERCIO') NOT NULL,
  estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id_canal),
  UNIQUE KEY uk_canal_nombre (nombre_canal)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS banco_cuenta (
  id_cuenta INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente INT UNSIGNED NOT NULL,
  numero_cuenta VARCHAR(24) NOT NULL,
  tipo_cuenta ENUM('AHORROS', 'CORRIENTE', 'PLAZO_FIJO') NOT NULL,
  moneda ENUM('PEN', 'USD') NOT NULL,
  saldo_actual DECIMAL(16, 2) NOT NULL DEFAULT 0.00,
  fecha_apertura DATE NOT NULL,
  estado ENUM('ACTIVA', 'BLOQUEADA', 'CERRADA') NOT NULL DEFAULT 'ACTIVA',
  PRIMARY KEY (id_cuenta),
  UNIQUE KEY uk_cuenta_numero (numero_cuenta),
  KEY ix_cuenta_cliente_estado (id_cliente, estado),
  KEY ix_cuenta_tipo_moneda (tipo_cuenta, moneda),
  CONSTRAINT fk_cuenta_cliente
    FOREIGN KEY (id_cliente) REFERENCES banco_cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_cuenta_saldo CHECK (saldo_actual >= 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS banco_tarjeta (
  id_tarjeta INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente INT UNSIGNED NOT NULL,
  numero_enmascarado VARCHAR(24) NOT NULL,
  tipo_tarjeta ENUM('DEBITO', 'CREDITO') NOT NULL,
  marca ENUM('VISA', 'MASTERCARD', 'AMEX') NOT NULL,
  linea_credito DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  fecha_emision DATE NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  estado ENUM('ACTIVA', 'BLOQUEADA', 'CANCELADA', 'VENCIDA') NOT NULL DEFAULT 'ACTIVA',
  PRIMARY KEY (id_tarjeta),
  UNIQUE KEY uk_tarjeta_numero_enmascarado (numero_enmascarado),
  KEY ix_tarjeta_cliente_estado (id_cliente, estado),
  CONSTRAINT fk_tarjeta_cliente
    FOREIGN KEY (id_cliente) REFERENCES banco_cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_tarjeta_linea_credito CHECK (linea_credito >= 0),
  CONSTRAINT chk_tarjeta_fechas CHECK (fecha_vencimiento > fecha_emision),
  CONSTRAINT chk_tarjeta_tipo_linea CHECK (
    (tipo_tarjeta = 'DEBITO' AND linea_credito = 0)
    OR (tipo_tarjeta = 'CREDITO' AND linea_credito > 0)
  )
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS banco_prestamo (
  id_prestamo INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente INT UNSIGNED NOT NULL,
  id_sucursal SMALLINT UNSIGNED NOT NULL,
  tipo_prestamo ENUM('CONSUMO', 'HIPOTECARIO', 'VEHICULAR', 'EMPRESARIAL') NOT NULL,
  monto_desembolso DECIMAL(16, 2) NOT NULL,
  saldo_pendiente DECIMAL(16, 2) NOT NULL,
  tasa_interes_anual DECIMAL(7, 4) NOT NULL,
  numero_cuotas SMALLINT UNSIGNED NOT NULL,
  fecha_desembolso DATE NOT NULL,
  estado ENUM('VIGENTE', 'PAGADO', 'VENCIDO', 'CASTIGADO') NOT NULL,
  PRIMARY KEY (id_prestamo),
  KEY ix_prestamo_cliente_estado (id_cliente, estado),
  KEY ix_prestamo_sucursal_fecha (id_sucursal, fecha_desembolso),
  CONSTRAINT fk_prestamo_cliente
    FOREIGN KEY (id_cliente) REFERENCES banco_cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_prestamo_sucursal
    FOREIGN KEY (id_sucursal) REFERENCES banco_sucursal (id_sucursal)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_prestamo_montos CHECK (
    monto_desembolso > 0
    AND saldo_pendiente >= 0
    AND saldo_pendiente <= monto_desembolso
  ),
  CONSTRAINT chk_prestamo_tasa CHECK (tasa_interes_anual > 0),
  CONSTRAINT chk_prestamo_cuotas CHECK (numero_cuotas > 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS banco_transaccion (
  id_transaccion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cuenta INT UNSIGNED NOT NULL,
  id_canal TINYINT UNSIGNED NOT NULL,
  codigo_operacion VARCHAR(30) NOT NULL,
  fecha_transaccion DATETIME(3) NOT NULL,
  tipo_transaccion ENUM(
    'DEPOSITO',
    'RETIRO',
    'TRANSFERENCIA',
    'COMPRA',
    'PAGO',
    'COMISION'
  ) NOT NULL,
  naturaleza ENUM('CREDITO', 'DEBITO') NOT NULL,
  monto DECIMAL(16, 2) NOT NULL,
  descripcion VARCHAR(250) NULL,
  estado ENUM('APROBADA', 'RECHAZADA', 'REVERSADA') NOT NULL DEFAULT 'APROBADA',
  PRIMARY KEY (id_transaccion),
  UNIQUE KEY uk_transaccion_codigo (codigo_operacion),
  KEY ix_transaccion_fecha_id (fecha_transaccion, id_transaccion),
  KEY ix_transaccion_cuenta_fecha (id_cuenta, fecha_transaccion),
  KEY ix_transaccion_canal_fecha (id_canal, fecha_transaccion),
  KEY ix_transaccion_tipo_estado (tipo_transaccion, estado),
  CONSTRAINT fk_transaccion_cuenta
    FOREIGN KEY (id_cuenta) REFERENCES banco_cuenta (id_cuenta)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_transaccion_canal
    FOREIGN KEY (id_canal) REFERENCES banco_canal (id_canal)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_transaccion_monto CHECK (monto > 0)
) ENGINE = InnoDB;
