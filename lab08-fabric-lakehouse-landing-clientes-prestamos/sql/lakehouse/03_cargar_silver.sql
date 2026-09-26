-- Ejecutar con Spark SQL después de cargar ambas tablas Bronze.
-- cliente: conserva historia mediante SCD Tipo 2 y Delta MERGE.
-- prestamo: upsert Tipo 1 mediante Delta MERGE.

CREATE OR REPLACE TEMP VIEW vw_cliente_fuente AS
WITH cliente_tipado AS (
    SELECT
        TRY_CAST(id_cliente AS INT)              AS id_cliente,
        UPPER(TRIM(tipo_documento))              AS tipo_documento,
        TRIM(nro_documento)                      AS nro_documento,
        TRIM(nombre_completo)                    AS nombre_completo,
        UPPER(TRIM(tipo_cliente))                AS tipo_cliente,
        UPPER(TRIM(segmento))                    AS segmento,
        TRY_CAST(fecha_registro AS DATE)         AS fecha_registro,
        LOWER(TRIM(email))                       AS email,
        TRIM(telefono)                           AS telefono,
        UPPER(TRIM(estado))                      AS estado,
        TRY_CAST(creado_en AS TIMESTAMP)         AS creado_en
    FROM brz.banco_cliente
),
cliente_deduplicado AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id_cliente
            ORDER BY creado_en DESC NULLS LAST
        ) AS numero_fila
    FROM cliente_tipado
    WHERE id_cliente IS NOT NULL
)
SELECT
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
    creado_en,
    SHA2(
        CONCAT_WS(
            '||',
            COALESCE(tipo_documento, '∅'),
            COALESCE(nro_documento, '∅'),
            COALESCE(nombre_completo, '∅'),
            COALESCE(tipo_cliente, '∅'),
            COALESCE(segmento, '∅'),
            COALESCE(CAST(fecha_registro AS STRING), '∅'),
            COALESCE(email, '∅'),
            COALESCE(telefono, '∅'),
            COALESCE(estado, '∅'),
            COALESCE(CAST(creado_en AS STRING), '∅')
        ),
        256
    ) AS hash_atributos
FROM cliente_deduplicado
WHERE numero_fila = 1;

-- La primera rama actualiza la versión vigente cuando cambia el hash.
-- La segunda rama fuerza la inserción de la nueva versión con merge_key NULL.
MERGE INTO slv.cliente AS destino
USING (
    SELECT
        fuente.id_cliente AS merge_key,
        fuente.*
    FROM vw_cliente_fuente AS fuente

    UNION ALL

    SELECT
        CAST(NULL AS INT) AS merge_key,
        fuente.*
    FROM vw_cliente_fuente AS fuente
    INNER JOIN slv.cliente AS actual
        ON actual.id_cliente = fuente.id_cliente
       AND actual.es_actual = TRUE
    WHERE actual.hash_atributos <> fuente.hash_atributos
) AS etapa
ON destino.id_cliente = etapa.merge_key
AND destino.es_actual = TRUE
WHEN MATCHED
 AND destino.hash_atributos <> etapa.hash_atributos
THEN UPDATE SET
    destino.vigente_hasta = CURRENT_TIMESTAMP(),
    destino.es_actual = FALSE,
    destino.fecha_proceso = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
    INSERT (
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
        creado_en,
        vigente_desde,
        vigente_hasta,
        es_actual,
        hash_atributos,
        fecha_proceso
    )
    VALUES (
        SHA2(
            CONCAT_WS(
                '||',
                CAST(etapa.id_cliente AS STRING),
                etapa.hash_atributos,
                CAST(CURRENT_TIMESTAMP() AS STRING)
            ),
            256
        ),
        etapa.id_cliente,
        etapa.tipo_documento,
        etapa.nro_documento,
        etapa.nombre_completo,
        etapa.tipo_cliente,
        etapa.segmento,
        etapa.fecha_registro,
        etapa.email,
        etapa.telefono,
        etapa.estado,
        etapa.creado_en,
        CURRENT_TIMESTAMP(),
        CAST('9999-12-31 23:59:59.999999' AS TIMESTAMP),
        TRUE,
        etapa.hash_atributos,
        CURRENT_TIMESTAMP()
    );

CREATE OR REPLACE TEMP VIEW vw_prestamo_fuente AS
WITH prestamo_tipado AS (
    SELECT
        TRY_CAST(id_prestamo AS INT)                 AS id_prestamo,
        TRY_CAST(id_cliente AS INT)                  AS id_cliente,
        TRY_CAST(id_sucursal AS SMALLINT)            AS id_sucursal,
        UPPER(TRIM(tipo_prestamo))                   AS tipo_prestamo,
        TRY_CAST(monto_desembolso AS DECIMAL(16,2))  AS monto_desembolso,
        TRY_CAST(saldo_pendiente AS DECIMAL(16,2))   AS saldo_pendiente,
        TRY_CAST(tasa_interes_anual AS DECIMAL(7,4)) AS tasa_interes_anual,
        TRY_CAST(numero_cuotas AS SMALLINT)           AS numero_cuotas,
        TRY_CAST(fecha_desembolso AS DATE)            AS fecha_desembolso,
        UPPER(TRIM(estado))                           AS estado
    FROM brz.banco_prestamo
),
prestamo_deduplicado AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY id_prestamo
            ORDER BY fecha_desembolso DESC NULLS LAST
        ) AS numero_fila
    FROM prestamo_tipado
    WHERE id_prestamo IS NOT NULL
      AND id_cliente IS NOT NULL
)
SELECT
    id_prestamo,
    id_cliente,
    id_sucursal,
    tipo_prestamo,
    monto_desembolso,
    saldo_pendiente,
    tasa_interes_anual,
    numero_cuotas,
    fecha_desembolso,
    estado
FROM prestamo_deduplicado
WHERE numero_fila = 1;

MERGE INTO slv.prestamo AS destino
USING vw_prestamo_fuente AS fuente
ON destino.id_prestamo = fuente.id_prestamo
WHEN MATCHED THEN UPDATE SET
    destino.id_cliente = fuente.id_cliente,
    destino.id_sucursal = fuente.id_sucursal,
    destino.tipo_prestamo = fuente.tipo_prestamo,
    destino.monto_desembolso = fuente.monto_desembolso,
    destino.saldo_pendiente = fuente.saldo_pendiente,
    destino.tasa_interes_anual = fuente.tasa_interes_anual,
    destino.numero_cuotas = fuente.numero_cuotas,
    destino.fecha_desembolso = fuente.fecha_desembolso,
    destino.estado = fuente.estado,
    destino.fecha_proceso = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (
    id_prestamo,
    id_cliente,
    id_sucursal,
    tipo_prestamo,
    monto_desembolso,
    saldo_pendiente,
    tasa_interes_anual,
    numero_cuotas,
    fecha_desembolso,
    estado,
    fecha_proceso
)
VALUES (
    fuente.id_prestamo,
    fuente.id_cliente,
    fuente.id_sucursal,
    fuente.tipo_prestamo,
    fuente.monto_desembolso,
    fuente.saldo_pendiente,
    fuente.tasa_interes_anual,
    fuente.numero_cuotas,
    fuente.fecha_desembolso,
    fuente.estado,
    CURRENT_TIMESTAMP()
);
