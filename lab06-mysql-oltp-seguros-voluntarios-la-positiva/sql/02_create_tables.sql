CREATE TABLE IF NOT EXISTS aseguradora_ubicacion (
  id_ubicacion SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo_ubigeo CHAR(6) NOT NULL,
  departamento VARCHAR(80) NOT NULL,
  provincia VARCHAR(80) NOT NULL,
  distrito VARCHAR(80) NOT NULL,
  macroregion ENUM('LIMA', 'NORTE', 'CENTRO', 'SUR', 'ORIENTE') NOT NULL,
  PRIMARY KEY (id_ubicacion),
  UNIQUE KEY uk_aseguradora_ubicacion_ubigeo (codigo_ubigeo),
  KEY ix_aseguradora_ubicacion_geografia (departamento, provincia, distrito)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_producto (
  id_producto SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  familia ENUM(
    'VEHICULAR',
    'HOGAR',
    'ACCIDENTES',
    'ONCOLOGICO',
    'VIDA_AHORRO',
    'VIAJES'
  ) NOT NULL,
  nombre_producto VARCHAR(120) NOT NULL,
  codigo_sbs VARCHAR(20) NULL,
  descripcion VARCHAR(300) NOT NULL,
  prima_base_simulada DECIMAL(12, 2) NOT NULL,
  frecuencia_pago_sugerida ENUM('UNICA', 'MENSUAL', 'SEMESTRAL', 'ANUAL') NOT NULL,
  permite_venta_online BOOLEAN NOT NULL DEFAULT FALSE,
  requiere_evaluacion BOOLEAN NOT NULL DEFAULT TRUE,
  url_fuente VARCHAR(500) NOT NULL,
  fecha_verificacion DATE NOT NULL,
  estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id_producto),
  UNIQUE KEY uk_aseguradora_producto_nombre (nombre_producto),
  KEY ix_aseguradora_producto_familia_estado (familia, estado),
  CONSTRAINT chk_aseguradora_producto_prima CHECK (prima_base_simulada > 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_broker (
  id_broker SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ubicacion SMALLINT UNSIGNED NOT NULL,
  codigo_broker VARCHAR(20) NOT NULL,
  nombre_broker VARCHAR(150) NOT NULL,
  tipo_broker ENUM('CORREDOR', 'AGENCIA', 'ASESOR', 'ALIANZA_COMERCIAL') NOT NULL,
  fecha_afiliacion DATE NOT NULL,
  porcentaje_comision DECIMAL(5, 2) NOT NULL,
  meta_prima_mensual DECIMAL(14, 2) NOT NULL,
  estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id_broker),
  UNIQUE KEY uk_aseguradora_broker_codigo (codigo_broker),
  KEY ix_aseguradora_broker_ubicacion (id_ubicacion),
  KEY ix_aseguradora_broker_tipo_estado (tipo_broker, estado),
  CONSTRAINT fk_aseguradora_broker_ubicacion
    FOREIGN KEY (id_ubicacion) REFERENCES aseguradora_ubicacion (id_ubicacion)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_aseguradora_broker_comision
    CHECK (porcentaje_comision BETWEEN 0 AND 30),
  CONSTRAINT chk_aseguradora_broker_meta CHECK (meta_prima_mensual > 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_canal_venta (
  id_canal TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_canal VARCHAR(60) NOT NULL,
  tipo_canal ENUM('INTERMEDIADO', 'DIGITAL', 'TELEFONICO', 'PRESENCIAL', 'ALIANZA') NOT NULL,
  estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id_canal),
  UNIQUE KEY uk_aseguradora_canal_nombre (nombre_canal)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_medio_pago (
  id_medio_pago TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_medio_pago VARCHAR(60) NOT NULL,
  tipo_medio ENUM('TARJETA', 'TRANSFERENCIA', 'DEBITO', 'BILLETERA', 'EFECTIVO') NOT NULL,
  estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  PRIMARY KEY (id_medio_pago),
  UNIQUE KEY uk_aseguradora_medio_pago_nombre (nombre_medio_pago)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_cliente (
  id_cliente INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_ubicacion SMALLINT UNSIGNED NOT NULL,
  tipo_documento ENUM('DNI', 'CE', 'PASAPORTE') NOT NULL,
  numero_documento VARCHAR(20) NOT NULL,
  nombre_completo VARCHAR(150) NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  sexo ENUM('F', 'M', 'NO_ESPECIFICA') NOT NULL,
  email VARCHAR(150) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  segmento ENUM('JOVEN', 'FAMILIA', 'PROFESIONAL', 'EMPRENDEDOR', 'PREMIUM') NOT NULL,
  fecha_registro DATE NOT NULL,
  estado ENUM('ACTIVO', 'INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_cliente),
  UNIQUE KEY uk_aseguradora_cliente_documento (tipo_documento, numero_documento),
  UNIQUE KEY uk_aseguradora_cliente_email (email),
  KEY ix_aseguradora_cliente_ubicacion (id_ubicacion),
  KEY ix_aseguradora_cliente_segmento_estado (segmento, estado),
  CONSTRAINT fk_aseguradora_cliente_ubicacion
    FOREIGN KEY (id_ubicacion) REFERENCES aseguradora_ubicacion (id_ubicacion)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_aseguradora_cliente_documento
    CHECK (CHAR_LENGTH(TRIM(numero_documento)) >= 8)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_cotizacion (
  id_cotizacion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cliente INT UNSIGNED NOT NULL,
  id_producto SMALLINT UNSIGNED NOT NULL,
  id_broker SMALLINT UNSIGNED NULL,
  id_canal TINYINT UNSIGNED NOT NULL,
  numero_cotizacion VARCHAR(30) NOT NULL,
  fecha_cotizacion DATETIME NOT NULL,
  prima_cotizada DECIMAL(14, 2) NOT NULL,
  suma_asegurada DECIMAL(16, 2) NOT NULL,
  moneda CHAR(3) NOT NULL DEFAULT 'PEN',
  estado ENUM('GENERADA', 'EN_SEGUIMIENTO', 'RECHAZADA', 'EXPIRADA', 'CONVERTIDA') NOT NULL,
  motivo_no_conversion ENUM(
    'PRECIO',
    'SIN_RESPUESTA',
    'PREFIERE_COMPETENCIA',
    'RIESGO_NO_ACEPTADO'
  ) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_cotizacion),
  UNIQUE KEY uk_aseguradora_cotizacion_numero (numero_cotizacion),
  KEY ix_aseguradora_cotizacion_fecha_id (fecha_cotizacion, id_cotizacion),
  KEY ix_aseguradora_cotizacion_cliente_fecha (id_cliente, fecha_cotizacion),
  KEY ix_aseguradora_cotizacion_producto_estado (id_producto, estado),
  KEY ix_aseguradora_cotizacion_broker_fecha (id_broker, fecha_cotizacion),
  KEY ix_aseguradora_cotizacion_canal_estado (id_canal, estado),
  CONSTRAINT fk_aseguradora_cotizacion_cliente
    FOREIGN KEY (id_cliente) REFERENCES aseguradora_cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_cotizacion_producto
    FOREIGN KEY (id_producto) REFERENCES aseguradora_producto (id_producto)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_cotizacion_broker
    FOREIGN KEY (id_broker) REFERENCES aseguradora_broker (id_broker)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_cotizacion_canal
    FOREIGN KEY (id_canal) REFERENCES aseguradora_canal_venta (id_canal)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_aseguradora_cotizacion_importes
    CHECK (prima_cotizada > 0 AND suma_asegurada > 0),
  CONSTRAINT chk_aseguradora_cotizacion_moneda CHECK (moneda IN ('PEN', 'USD')),
  CONSTRAINT chk_aseguradora_cotizacion_motivo CHECK (
    (estado IN ('RECHAZADA', 'EXPIRADA') AND motivo_no_conversion IS NOT NULL)
    OR (estado NOT IN ('RECHAZADA', 'EXPIRADA') AND motivo_no_conversion IS NULL)
  )
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_poliza (
  id_poliza BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cotizacion BIGINT UNSIGNED NOT NULL,
  id_cliente INT UNSIGNED NOT NULL,
  id_producto SMALLINT UNSIGNED NOT NULL,
  id_broker SMALLINT UNSIGNED NULL,
  id_canal TINYINT UNSIGNED NOT NULL,
  numero_poliza VARCHAR(30) NOT NULL,
  referencia_riesgo VARCHAR(80) NOT NULL,
  fecha_emision DATETIME NOT NULL,
  fecha_inicio_vigencia DATE NOT NULL,
  fecha_fin_vigencia DATE NOT NULL,
  prima_neta DECIMAL(14, 2) NOT NULL,
  impuestos DECIMAL(14, 2) NOT NULL,
  prima_total DECIMAL(14, 2) NOT NULL,
  suma_asegurada DECIMAL(16, 2) NOT NULL,
  moneda CHAR(3) NOT NULL DEFAULT 'PEN',
  numero_cuotas TINYINT UNSIGNED NOT NULL,
  porcentaje_comision DECIMAL(5, 2) NOT NULL DEFAULT 0,
  monto_comision DECIMAL(14, 2) NOT NULL DEFAULT 0,
  es_renovacion BOOLEAN NOT NULL DEFAULT FALSE,
  estado ENUM('VIGENTE', 'SUSPENDIDA', 'CANCELADA', 'VENCIDA', 'RENOVADA') NOT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_poliza),
  UNIQUE KEY uk_aseguradora_poliza_cotizacion (id_cotizacion),
  UNIQUE KEY uk_aseguradora_poliza_numero (numero_poliza),
  KEY ix_aseguradora_poliza_fecha_id (fecha_emision, id_poliza),
  KEY ix_aseguradora_poliza_cliente_estado (id_cliente, estado),
  KEY ix_aseguradora_poliza_producto_fecha (id_producto, fecha_emision),
  KEY ix_aseguradora_poliza_broker_fecha (id_broker, fecha_emision),
  CONSTRAINT fk_aseguradora_poliza_cotizacion
    FOREIGN KEY (id_cotizacion) REFERENCES aseguradora_cotizacion (id_cotizacion)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_poliza_cliente
    FOREIGN KEY (id_cliente) REFERENCES aseguradora_cliente (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_poliza_producto
    FOREIGN KEY (id_producto) REFERENCES aseguradora_producto (id_producto)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_poliza_broker
    FOREIGN KEY (id_broker) REFERENCES aseguradora_broker (id_broker)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_poliza_canal
    FOREIGN KEY (id_canal) REFERENCES aseguradora_canal_venta (id_canal)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_aseguradora_poliza_fechas
    CHECK (fecha_fin_vigencia > fecha_inicio_vigencia),
  CONSTRAINT chk_aseguradora_poliza_importes CHECK (
    prima_neta > 0
    AND impuestos >= 0
    AND prima_total = prima_neta + impuestos
    AND suma_asegurada > 0
    AND monto_comision >= 0
    AND monto_comision <= prima_total
  ),
  CONSTRAINT chk_aseguradora_poliza_cuotas CHECK (numero_cuotas IN (1, 4, 6, 12)),
  CONSTRAINT chk_aseguradora_poliza_moneda CHECK (moneda IN ('PEN', 'USD'))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_cuota (
  id_cuota BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_poliza BIGINT UNSIGNED NOT NULL,
  numero_cuota TINYINT UNSIGNED NOT NULL,
  fecha_emision DATE NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  importe_cuota DECIMAL(14, 2) NOT NULL,
  saldo_pendiente DECIMAL(14, 2) NOT NULL,
  fecha_pago_completo DATE NULL,
  dias_mora SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  estado ENUM('PENDIENTE', 'PAGADA', 'PAGADA_PARCIAL', 'VENCIDA', 'ANULADA') NOT NULL,
  PRIMARY KEY (id_cuota),
  UNIQUE KEY uk_aseguradora_cuota_poliza_numero (id_poliza, numero_cuota),
  KEY ix_aseguradora_cuota_vencimiento_estado (fecha_vencimiento, estado),
  CONSTRAINT fk_aseguradora_cuota_poliza
    FOREIGN KEY (id_poliza) REFERENCES aseguradora_poliza (id_poliza)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_aseguradora_cuota_fechas
    CHECK (fecha_vencimiento >= fecha_emision),
  CONSTRAINT chk_aseguradora_cuota_importes CHECK (
    importe_cuota > 0
    AND saldo_pendiente >= 0
    AND saldo_pendiente <= importe_cuota
  ),
  CONSTRAINT chk_aseguradora_cuota_pagada CHECK (
    (estado = 'PAGADA' AND saldo_pendiente = 0 AND fecha_pago_completo IS NOT NULL)
    OR (estado <> 'PAGADA' AND fecha_pago_completo IS NULL)
  )
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_pago (
  id_pago BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_cuota BIGINT UNSIGNED NOT NULL,
  id_medio_pago TINYINT UNSIGNED NOT NULL,
  numero_operacion VARCHAR(35) NOT NULL,
  fecha_pago DATETIME NOT NULL,
  importe_pagado DECIMAL(14, 2) NOT NULL,
  moneda CHAR(3) NOT NULL DEFAULT 'PEN',
  estado ENUM('PROCESADO', 'RECHAZADO', 'EXTORNADO') NOT NULL,
  PRIMARY KEY (id_pago),
  UNIQUE KEY uk_aseguradora_pago_operacion (numero_operacion),
  KEY ix_aseguradora_pago_fecha_id (fecha_pago, id_pago),
  KEY ix_aseguradora_pago_cuota_estado (id_cuota, estado),
  KEY ix_aseguradora_pago_medio_fecha (id_medio_pago, fecha_pago),
  CONSTRAINT fk_aseguradora_pago_cuota
    FOREIGN KEY (id_cuota) REFERENCES aseguradora_cuota (id_cuota)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_pago_medio
    FOREIGN KEY (id_medio_pago) REFERENCES aseguradora_medio_pago (id_medio_pago)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_aseguradora_pago_importe CHECK (importe_pagado > 0),
  CONSTRAINT chk_aseguradora_pago_moneda CHECK (moneda IN ('PEN', 'USD'))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_tipo_siniestro (
  id_tipo_siniestro SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_producto SMALLINT UNSIGNED NOT NULL,
  codigo_tipo VARCHAR(50) NOT NULL,
  nombre_tipo VARCHAR(120) NOT NULL,
  PRIMARY KEY (id_tipo_siniestro),
  UNIQUE KEY uk_aseguradora_tipo_siniestro_codigo (codigo_tipo),
  KEY ix_aseguradora_tipo_siniestro_producto (id_producto),
  CONSTRAINT fk_aseguradora_tipo_siniestro_producto
    FOREIGN KEY (id_producto) REFERENCES aseguradora_producto (id_producto)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS aseguradora_siniestro (
  id_siniestro BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_poliza BIGINT UNSIGNED NOT NULL,
  id_tipo_siniestro SMALLINT UNSIGNED NOT NULL,
  id_ubicacion SMALLINT UNSIGNED NOT NULL,
  numero_siniestro VARCHAR(30) NOT NULL,
  fecha_ocurrencia DATETIME NOT NULL,
  fecha_reporte DATETIME NOT NULL,
  monto_reclamado DECIMAL(16, 2) NOT NULL,
  monto_deducible DECIMAL(16, 2) NOT NULL DEFAULT 0,
  monto_reserva DECIMAL(16, 2) NOT NULL DEFAULT 0,
  monto_aprobado DECIMAL(16, 2) NOT NULL DEFAULT 0,
  monto_pagado DECIMAL(16, 2) NOT NULL DEFAULT 0,
  fecha_cierre DATE NULL,
  estado ENUM(
    'REPORTADO',
    'EN_EVALUACION',
    'OBSERVADO',
    'APROBADO',
    'RECHAZADO',
    'PAGADO',
    'CERRADO'
  ) NOT NULL,
  indicador_fraude BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_siniestro),
  UNIQUE KEY uk_aseguradora_siniestro_numero (numero_siniestro),
  KEY ix_aseguradora_siniestro_fecha_id (fecha_reporte, id_siniestro),
  KEY ix_aseguradora_siniestro_poliza_estado (id_poliza, estado),
  KEY ix_aseguradora_siniestro_tipo_fecha (id_tipo_siniestro, fecha_ocurrencia),
  KEY ix_aseguradora_siniestro_ubicacion_fecha (id_ubicacion, fecha_ocurrencia),
  CONSTRAINT fk_aseguradora_siniestro_poliza
    FOREIGN KEY (id_poliza) REFERENCES aseguradora_poliza (id_poliza)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_siniestro_tipo
    FOREIGN KEY (id_tipo_siniestro) REFERENCES aseguradora_tipo_siniestro (id_tipo_siniestro)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_aseguradora_siniestro_ubicacion
    FOREIGN KEY (id_ubicacion) REFERENCES aseguradora_ubicacion (id_ubicacion)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_aseguradora_siniestro_fechas CHECK (
    fecha_reporte >= fecha_ocurrencia
    AND (fecha_cierre IS NULL OR fecha_cierre >= DATE(fecha_reporte))
  ),
  CONSTRAINT chk_aseguradora_siniestro_importes CHECK (
    monto_reclamado > 0
    AND monto_deducible >= 0
    AND monto_reserva >= 0
    AND monto_aprobado >= 0
    AND monto_pagado >= 0
    AND monto_aprobado <= monto_reclamado
    AND monto_pagado <= monto_aprobado
  )
) ENGINE = InnoDB;
