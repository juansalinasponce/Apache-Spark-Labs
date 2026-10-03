-- Ejecutar en wh_banca_dev_gold después de crear las dimensiones.

DROP PROCEDURE IF EXISTS gld.usp_cargar_fct_prestamo;
GO

CREATE PROCEDURE gld.usp_cargar_fct_prestamo
AS
BEGIN
    SET NOCOUNT ON;

    MERGE gld.fct_prestamo AS destino
    USING (
        SELECT
            prestamo.id_prestamo,
            cliente.cliente_sk,
            tipo.tipo_prestamo_sk,
            prestamo.id_cliente,
            prestamo.id_sucursal,
            prestamo.fecha_desembolso,
            YEAR(prestamo.fecha_desembolso) AS anio_desembolso,
            MONTH(prestamo.fecha_desembolso) AS mes_desembolso,
            prestamo.monto_desembolso,
            prestamo.saldo_pendiente,
            prestamo.monto_desembolso - prestamo.saldo_pendiente
                AS monto_pagado,
            prestamo.tasa_interes_anual,
            prestamo.numero_cuotas,
            prestamo.estado
        FROM [lh_banca_dev_medallion].[slv].[prestamo] AS prestamo
        INNER JOIN gld.dim_cliente AS cliente
            ON cliente.id_cliente = prestamo.id_cliente
           AND cliente.es_actual = 1
        INNER JOIN gld.dim_tipo_prestamo AS tipo
            ON tipo.tipo_prestamo = prestamo.tipo_prestamo
    ) AS fuente
        ON destino.id_prestamo = fuente.id_prestamo
    WHEN MATCHED THEN UPDATE SET
        destino.tipo_prestamo_sk = fuente.tipo_prestamo_sk,
        destino.id_cliente = fuente.id_cliente,
        destino.id_sucursal = fuente.id_sucursal,
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
        tipo_prestamo_sk,
        id_cliente,
        id_sucursal,
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
        fuente.tipo_prestamo_sk,
        fuente.id_cliente,
        fuente.id_sucursal,
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
END;
GO
