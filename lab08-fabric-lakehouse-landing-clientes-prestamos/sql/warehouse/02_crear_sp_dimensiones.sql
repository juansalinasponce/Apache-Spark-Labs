-- Ejecutar en wh_banca_dev_gold.
-- Ambos procedimientos leen tablas Delta desde el SQL analytics endpoint del
-- Lakehouse mediante nombres de tres partes: lakehouse.schema.tabla.

DROP PROCEDURE IF EXISTS gld.usp_cargar_dim_cliente;
GO

CREATE PROCEDURE gld.usp_cargar_dim_cliente
AS
BEGIN
    SET NOCOUNT ON;

    MERGE gld.dim_cliente AS destino
    USING [lh_banca_dev_medallion].[slv].[cliente] AS fuente
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
END;
GO

DROP PROCEDURE IF EXISTS gld.usp_cargar_dim_tipo_prestamo;
GO

CREATE PROCEDURE gld.usp_cargar_dim_tipo_prestamo
AS
BEGIN
    SET NOCOUNT ON;

    MERGE gld.dim_tipo_prestamo AS destino
    USING (
        SELECT DISTINCT
            UPPER(TRIM(tipo_prestamo)) AS tipo_prestamo
        FROM [lh_banca_dev_medallion].[slv].[prestamo]
        WHERE tipo_prestamo IS NOT NULL
    ) AS fuente
        ON destino.tipo_prestamo = fuente.tipo_prestamo
    WHEN MATCHED THEN UPDATE SET
        destino.fecha_actualizacion = SYSDATETIME()
    WHEN NOT MATCHED THEN INSERT (
        tipo_prestamo,
        fecha_carga,
        fecha_actualizacion
    )
    VALUES (
        fuente.tipo_prestamo,
        SYSDATETIME(),
        SYSDATETIME()
    );
END;
GO
