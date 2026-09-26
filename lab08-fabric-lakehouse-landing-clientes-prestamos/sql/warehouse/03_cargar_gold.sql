-- Ejecutar después de copiar Silver a las tablas stg del Warehouse.

MERGE gld.dim_cliente AS destino
USING stg.cliente AS fuente
ON destino.cliente_sk = fuente.cliente_sk
WHEN MATCHED THEN UPDATE SET
    destino.id_cliente = fuente.id_cliente,
    destino.tipo_documento = fuente.tipo_documento,
    destino.nro_documento = fuente.nro_documento,
    destino.nombre_completo = fuente.nombre_completo,
    destino.tipo_cliente = fuente.tipo_cliente,
    destino.segmento = fuente.segmento,
    destino.fecha_registro = fuente.fecha_registro,
    destino.email = fuente.email,
    destino.telefono = fuente.telefono,
    destino.estado = fuente.estado,
    destino.vigente_desde = fuente.vigente_desde,
    destino.vigente_hasta = fuente.vigente_hasta,
    destino.es_actual = fuente.es_actual,
    destino.fecha_carga = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT (
    cliente_sk,
    id_cliente,
    tipo_documento,
    nro_documento,
    nombre_completo,
    tipo_cliente,
    segmento,
    fecha_registro,
    email,
    telefono,
    estado,
    vigente_desde,
    vigente_hasta,
    es_actual,
    fecha_carga
)
VALUES (
    fuente.cliente_sk,
    fuente.id_cliente,
    fuente.tipo_documento,
    fuente.nro_documento,
    fuente.nombre_completo,
    fuente.tipo_cliente,
    fuente.segmento,
    fuente.fecha_registro,
    fuente.email,
    fuente.telefono,
    fuente.estado,
    fuente.vigente_desde,
    fuente.vigente_hasta,
    fuente.es_actual,
    SYSDATETIME()
);

-- Un préstamo nuevo se relaciona con la versión vigente del cliente.
-- En actualizaciones posteriores se conserva cliente_sk para no reescribir
-- la versión histórica con la que el hecho fue incorporado originalmente.
MERGE gld.fct_prestamo AS destino
USING (
    SELECT
        prestamo.id_prestamo,
        cliente.cliente_sk,
        prestamo.id_cliente,
        prestamo.id_sucursal,
        prestamo.tipo_prestamo,
        prestamo.fecha_desembolso,
        YEAR(prestamo.fecha_desembolso) AS anio_desembolso,
        MONTH(prestamo.fecha_desembolso) AS mes_desembolso,
        prestamo.monto_desembolso,
        prestamo.saldo_pendiente,
        prestamo.monto_desembolso - prestamo.saldo_pendiente AS monto_pagado,
        prestamo.tasa_interes_anual,
        prestamo.numero_cuotas,
        prestamo.estado
    FROM stg.prestamo AS prestamo
    INNER JOIN gld.dim_cliente AS cliente
        ON cliente.id_cliente = prestamo.id_cliente
       AND cliente.es_actual = 1
) AS fuente
ON destino.id_prestamo = fuente.id_prestamo
WHEN MATCHED THEN UPDATE SET
    destino.id_cliente = fuente.id_cliente,
    destino.id_sucursal = fuente.id_sucursal,
    destino.tipo_prestamo = fuente.tipo_prestamo,
    destino.fecha_desembolso = fuente.fecha_desembolso,
    destino.anio_desembolso = fuente.anio_desembolso,
    destino.mes_desembolso = fuente.mes_desembolso,
    destino.monto_desembolso = fuente.monto_desembolso,
    destino.saldo_pendiente = fuente.saldo_pendiente,
    destino.monto_pagado = fuente.monto_pagado,
    destino.tasa_interes_anual = fuente.tasa_interes_anual,
    destino.numero_cuotas = fuente.numero_cuotas,
    destino.estado = fuente.estado,
    destino.fecha_carga = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT (
    id_prestamo,
    cliente_sk,
    id_cliente,
    id_sucursal,
    tipo_prestamo,
    fecha_desembolso,
    anio_desembolso,
    mes_desembolso,
    monto_desembolso,
    saldo_pendiente,
    monto_pagado,
    tasa_interes_anual,
    numero_cuotas,
    estado,
    fecha_carga
)
VALUES (
    fuente.id_prestamo,
    fuente.cliente_sk,
    fuente.id_cliente,
    fuente.id_sucursal,
    fuente.tipo_prestamo,
    fuente.fecha_desembolso,
    fuente.anio_desembolso,
    fuente.mes_desembolso,
    fuente.monto_desembolso,
    fuente.saldo_pendiente,
    fuente.monto_pagado,
    fuente.tasa_interes_anual,
    fuente.numero_cuotas,
    fuente.estado,
    SYSDATETIME()
);
