START TRANSACTION;

INSERT INTO aseguradora_ubicacion (
  id_ubicacion, codigo_ubigeo, departamento, provincia, distrito, macroregion
) VALUES
  (1,  '150101', 'Lima',          'Lima',          'Lima',                  'LIMA'),
  (2,  '150122', 'Lima',          'Lima',          'Miraflores',            'LIMA'),
  (3,  '150130', 'Lima',          'Lima',          'San Borja',             'LIMA'),
  (4,  '150131', 'Lima',          'Lima',          'San Isidro',            'LIMA'),
  (5,  '150132', 'Lima',          'Lima',          'San Juan de Lurigancho','LIMA'),
  (6,  '150133', 'Lima',          'Lima',          'San Juan de Miraflores','LIMA'),
  (7,  '150134', 'Lima',          'Lima',          'San Luis',              'LIMA'),
  (8,  '150135', 'Lima',          'Lima',          'San Martin de Porres',  'LIMA'),
  (9,  '150136', 'Lima',          'Lima',          'San Miguel',            'LIMA'),
  (10, '150137', 'Lima',          'Lima',          'Santa Anita',           'LIMA'),
  (11, '150140', 'Lima',          'Lima',          'Santiago de Surco',     'LIMA'),
  (12, '150142', 'Lima',          'Lima',          'Villa El Salvador',     'LIMA'),
  (13, '150143', 'Lima',          'Lima',          'Villa Maria del Triunfo','LIMA'),
  (14, '070101', 'Callao',        'Callao',        'Callao',                'LIMA'),
  (15, '040101', 'Arequipa',      'Arequipa',      'Arequipa',              'SUR'),
  (16, '130101', 'La Libertad',   'Trujillo',      'Trujillo',              'NORTE'),
  (17, '140101', 'Lambayeque',    'Chiclayo',      'Chiclayo',              'NORTE'),
  (18, '200101', 'Piura',         'Piura',         'Piura',                 'NORTE'),
  (19, '080101', 'Cusco',         'Cusco',         'Cusco',                 'SUR'),
  (20, '120101', 'Junin',         'Huancayo',      'Huancayo',              'CENTRO'),
  (21, '160101', 'Loreto',        'Maynas',        'Iquitos',               'ORIENTE'),
  (22, '110101', 'Ica',           'Ica',           'Ica',                   'SUR'),
  (23, '060101', 'Cajamarca',     'Cajamarca',     'Cajamarca',             'NORTE'),
  (24, '020101', 'Ancash',        'Huaraz',        'Huaraz',                'NORTE'),
  (25, '220901', 'San Martin',    'San Martin',    'Tarapoto',              'ORIENTE'),
  (26, '230101', 'Tacna',         'Tacna',         'Tacna',                 'SUR'),
  (27, '210101', 'Puno',          'Puno',          'Puno',                  'SUR'),
  (28, '050101', 'Ayacucho',      'Huamanga',      'Ayacucho',              'CENTRO'),
  (29, '100101', 'Huanuco',       'Huanuco',       'Huanuco',               'CENTRO'),
  (30, '250101', 'Ucayali',       'Coronel Portillo','Calleria',            'ORIENTE');

INSERT INTO aseguradora_producto (
  id_producto,
  familia,
  nombre_producto,
  codigo_sbs,
  descripcion,
  prima_base_simulada,
  frecuencia_pago_sugerida,
  permite_venta_online,
  requiere_evaluacion,
  url_fuente,
  fecha_verificacion,
  estado
) VALUES
  (
    1, 'VEHICULAR', 'Auto Total', 'RG0412100001',
    'Seguro vehicular a todo riesgo para daños propios, ocupantes y terceros.',
    1500.00, 'ANUAL', TRUE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-vehiculo/seguros-vehiculares',
    '2026-09-03', 'ACTIVO'
  ),
  (
    2, 'VEHICULAR', 'Auto Total Kilometros', 'RG0412100001',
    'Seguro vehicular cuyo esquema comercial considera el kilometraje recorrido.',
    1050.00, 'ANUAL', TRUE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-vehiculo/seguros-vehiculares',
    '2026-09-03', 'ACTIVO'
  ),
  (
    3, 'VEHICULAR', 'Robo Total', 'RG0412100001',
    'Proteccion frente al robo total del vehiculo y responsabilidad frente a terceros.',
    420.00, 'MENSUAL', TRUE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-vehiculo/seguros-vehiculares',
    '2026-09-03', 'ACTIVO'
  ),
  (
    4, 'VEHICULAR', 'Auto Danos a Terceros', 'RG0412100001',
    'Proteccion por danos materiales o personales ocasionados a terceros.',
    360.00, 'ANUAL', TRUE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-vehiculo/seguros-vehiculares',
    '2026-09-03', 'ACTIVO'
  ),
  (
    5, 'HOGAR', 'Hogar Protegido', NULL,
    'Proteccion del hogar ante incendio, inundacion, robo y asistencias domiciliarias.',
    560.00, 'MENSUAL', FALSE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mis-bienes/seguros-hogar',
    '2026-09-03', 'ACTIVO'
  ),
  (
    6, 'HOGAR', 'Casa Plus', NULL,
    'Proteccion del inmueble, contenido, equipos y responsabilidad frente a terceros.',
    840.00, 'MENSUAL', FALSE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mis-bienes/seguros-hogar',
    '2026-09-03', 'ACTIVO'
  ),
  (
    7, 'ACCIDENTES', 'Accidente Cash', NULL,
    'Seguro de afiliacion sencilla para muerte e invalidez permanente por accidente.',
    120.00, 'SEMESTRAL', FALSE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-salud/seguros-contra-accidentes',
    '2026-09-03', 'ACTIVO'
  ),
  (
    8, 'ONCOLOGICO', 'Onco Cash', 'AE0416400234',
    'Microseguro con indemnizacion ante el primer diagnostico de cancer.',
    240.00, 'SEMESTRAL', FALSE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-salud/seguros-salud-oncologicos',
    '2026-09-03', 'ACTIVO'
  ),
  (
    9, 'VIDA_AHORRO', 'Vida Positiva Ahorro', NULL,
    'Producto que combina proteccion por fallecimiento con un componente de ahorro.',
    1200.00, 'MENSUAL', FALSE, TRUE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-futuro/seguros-vida-ahorro',
    '2026-09-03', 'ACTIVO'
  ),
  (
    10, 'VIAJES', 'Seguro de Asistencia al Viajero Internacional', 'AE0416120126',
    'Asistencia para emergencias medicas y otros imprevistos durante viajes internacionales.',
    180.00, 'UNICA', TRUE, FALSE,
    'https://www.lapositiva.com.pe/wps/portal/corporativo/home/proteger/mi-viaje/seguros-viaje-internacional',
    '2026-09-03', 'ACTIVO'
  );

INSERT INTO aseguradora_canal_venta (
  id_canal, nombre_canal, tipo_canal, estado
) VALUES
  (1, 'Broker',           'INTERMEDIADO', 'ACTIVO'),
  (2, 'Sitio web',        'DIGITAL',      'ACTIVO'),
  (3, 'Aplicacion movil', 'DIGITAL',      'ACTIVO'),
  (4, 'Call center',      'TELEFONICO',   'ACTIVO'),
  (5, 'Oficina',          'PRESENCIAL',   'ACTIVO'),
  (6, 'Alianza comercial','ALIANZA',      'ACTIVO');

INSERT INTO aseguradora_medio_pago (
  id_medio_pago, nombre_medio_pago, tipo_medio, estado
) VALUES
  (1, 'Tarjeta de credito', 'TARJETA',       'ACTIVO'),
  (2, 'Tarjeta de debito',  'TARJETA',       'ACTIVO'),
  (3, 'Transferencia',      'TRANSFERENCIA', 'ACTIVO'),
  (4, 'Debito automatico',  'DEBITO',        'ACTIVO'),
  (5, 'Billetera digital',  'BILLETERA',     'ACTIVO'),
  (6, 'Efectivo',           'EFECTIVO',      'ACTIVO');

INSERT INTO aseguradora_tipo_siniestro (
  id_tipo_siniestro, id_producto, codigo_tipo, nombre_tipo
) VALUES
  (1,  1,  'AUTO_TOTAL_DANO_PROPIO',              'Dano propio del vehiculo'),
  (2,  1,  'AUTO_TOTAL_ROBO',                     'Robo total del vehiculo'),
  (3,  1,  'AUTO_TOTAL_RESPONSABILIDAD',           'Responsabilidad civil frente a terceros'),
  (4,  2,  'AUTO_KM_DANO_PROPIO',                 'Dano propio del vehiculo'),
  (5,  2,  'AUTO_KM_ROBO',                        'Robo total del vehiculo'),
  (6,  2,  'AUTO_KM_RESPONSABILIDAD',              'Responsabilidad civil frente a terceros'),
  (7,  3,  'ROBO_TOTAL_VEHICULO',                 'Robo total del vehiculo'),
  (8,  3,  'ROBO_TOTAL_RESPONSABILIDAD',           'Responsabilidad civil frente a terceros'),
  (9,  4,  'TERCEROS_DANO_MATERIAL',              'Danos materiales a terceros'),
  (10, 4,  'TERCEROS_LESION_PERSONAL',            'Lesiones personales a terceros'),
  (11, 5,  'HOGAR_INCENDIO',                      'Incendio de la vivienda'),
  (12, 5,  'HOGAR_INUNDACION',                    'Inundacion de la vivienda'),
  (13, 5,  'HOGAR_ROBO',                          'Robo en la vivienda'),
  (14, 6,  'CASA_PLUS_ROBO_VALORES',              'Robo de joyas o dinero'),
  (15, 6,  'CASA_PLUS_DANO_ELECTRICO',            'Dano de equipo electrico o electronico'),
  (16, 6,  'CASA_PLUS_ACCIDENTE_TERCERO',         'Accidente de un tercero en la vivienda'),
  (17, 7,  'ACCIDENTE_CASH_MUERTE',               'Muerte accidental'),
  (18, 7,  'ACCIDENTE_CASH_INVALIDEZ',            'Invalidez permanente por accidente'),
  (19, 8,  'ONCO_CASH_DIAGNOSTICO',               'Primer diagnostico de cancer'),
  (20, 8,  'ONCO_CASH_ENFERMEDAD_GRAVE',          'Diagnostico de enfermedad grave'),
  (21, 9,  'VIDA_AHORRO_FALLECIMIENTO_NATURAL',   'Fallecimiento natural'),
  (22, 9,  'VIDA_AHORRO_FALLECIMIENTO_ACCIDENTAL','Fallecimiento accidental'),
  (23, 9,  'VIDA_AHORRO_INVALIDEZ',               'Invalidez permanente'),
  (24, 10, 'VIAJE_EMERGENCIA_MEDICA',             'Emergencia medica en el extranjero'),
  (25, 10, 'VIAJE_PERDIDA_EQUIPAJE',              'Perdida de equipaje'),
  (26, 10, 'VIAJE_CANCELACION_VUELO',             'Cancelacion de vuelo');

COMMIT;
