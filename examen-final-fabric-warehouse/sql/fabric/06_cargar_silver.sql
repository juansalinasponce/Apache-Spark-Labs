-- Convertir a tipos destino; una conversión inválida se vuelve NULL.
-- Permitir una nueva ejecución en la misma sesión del editor.
DROP TABLE IF EXISTS #v_cuenta;
DROP TABLE IF EXISTS #v_canal;
DROP TABLE IF EXISTS #v_transaccion;
SELECT
    TRY_CONVERT(BIGINT, NULLIF(TRIM(id_cuenta), '')) AS id_cuenta,
    TRY_CONVERT(BIGINT, NULLIF(TRIM(id_cliente), '')) AS id_cliente,
    NULLIF(TRIM(numero_cuenta), '') AS numero_cuenta,
    UPPER(NULLIF(TRIM(tipo_cuenta), '')) AS tipo_cuenta,
    UPPER(NULLIF(TRIM(moneda), '')) AS moneda,
    TRY_CONVERT(DECIMAL(16,2), NULLIF(TRIM(saldo_actual), '')) AS saldo_actual,
    TRY_CONVERT(DATE, NULLIF(TRIM(fecha_apertura), '')) AS fecha_apertura,
    UPPER(NULLIF(TRIM(estado), '')) AS estado
INTO #v_cuenta
FROM brz.banco_cuenta;

SELECT
    TRY_CONVERT(INT, NULLIF(TRIM(id_canal), '')) AS id_canal,
    NULLIF(TRIM(nombre_canal), '') AS nombre_canal,
    UPPER(NULLIF(TRIM(tipo_canal), '')) AS tipo_canal,
    UPPER(NULLIF(TRIM(estado), '')) AS estado
INTO #v_canal
FROM brz.banco_canal;

SELECT
    TRY_CONVERT(BIGINT, NULLIF(TRIM(id_transaccion), '')) AS id_transaccion,
    TRY_CONVERT(BIGINT, NULLIF(TRIM(id_cuenta), '')) AS id_cuenta,
    TRY_CONVERT(INT, NULLIF(TRIM(id_canal), '')) AS id_canal,
    NULLIF(TRIM(codigo_operacion), '') AS codigo_operacion,
    TRY_CONVERT(DATETIME2(3), NULLIF(TRIM(fecha_transaccion), '')) AS fecha_transaccion,
    UPPER(NULLIF(TRIM(tipo_transaccion), '')) AS tipo_transaccion,
    UPPER(NULLIF(TRIM(naturaleza), '')) AS naturaleza,
    TRY_CONVERT(DECIMAL(16,2), NULLIF(TRIM(monto), '')) AS monto,
    NULLIF(TRIM(descripcion), '') AS descripcion,
    UPPER(NULLIF(TRIM(estado), '')) AS estado
INTO #v_transaccion
FROM brz.banco_transaccion;

IF NOT EXISTS (SELECT 1 FROM #v_cuenta)
    THROW 50001, 'Origen cuenta vacío: revisar Copy Data.', 1;
IF EXISTS (SELECT 1 FROM #v_cuenta WHERE id_cuenta IS NULL OR id_cliente IS NULL OR numero_cuenta IS NULL OR tipo_cuenta IS NULL OR moneda IS NULL OR saldo_actual IS NULL OR fecha_apertura IS NULL OR estado IS NULL OR id_cuenta <= 0 OR id_cliente <= 0 OR saldo_actual < 0 OR moneda NOT IN ('PEN','USD') OR tipo_cuenta NOT IN ('AHORROS','CORRIENTE','PLAZO_FIJO') OR estado NOT IN ('ACTIVA','BLOQUEADA','CERRADA'))
    THROW 50002, 'Datos inválidos en cuenta. Revisar origen y mapping.', 1;
IF EXISTS (SELECT id_cuenta FROM #v_cuenta GROUP BY id_cuenta HAVING COUNT(*) > 1)
    THROW 50003, 'Duplicados en cuenta.id_cuenta.', 1;
IF EXISTS (SELECT numero_cuenta FROM #v_cuenta GROUP BY numero_cuenta HAVING COUNT(*) > 1)
    THROW 50003, 'Duplicados en cuenta.numero_cuenta.', 1;
IF NOT EXISTS (SELECT 1 FROM #v_canal)
    THROW 50001, 'Origen canal vacío: revisar Copy Data.', 1;
IF EXISTS (SELECT 1 FROM #v_canal WHERE id_canal IS NULL OR nombre_canal IS NULL OR tipo_canal IS NULL OR estado IS NULL OR id_canal <= 0 OR tipo_canal NOT IN ('PRESENCIAL','DIGITAL','AUTOSERVICIO','COMERCIO') OR estado NOT IN ('ACTIVO','INACTIVO'))
    THROW 50002, 'Datos inválidos en canal. Revisar origen y mapping.', 1;
IF EXISTS (SELECT id_canal FROM #v_canal GROUP BY id_canal HAVING COUNT(*) > 1)
    THROW 50003, 'Duplicados en canal.id_canal.', 1;
IF NOT EXISTS (SELECT 1 FROM #v_transaccion)
    THROW 50001, 'Origen transaccion vacío: revisar Copy Data.', 1;
IF EXISTS (SELECT 1 FROM #v_transaccion WHERE id_transaccion IS NULL OR id_cuenta IS NULL OR id_canal IS NULL OR codigo_operacion IS NULL OR fecha_transaccion IS NULL OR tipo_transaccion IS NULL OR naturaleza IS NULL OR monto IS NULL OR estado IS NULL OR id_transaccion <= 0 OR monto <= 0 OR naturaleza NOT IN ('CREDITO','DEBITO') OR estado NOT IN ('APROBADA','RECHAZADA','REVERSADA') OR tipo_transaccion NOT IN ('DEPOSITO','RETIRO','TRANSFERENCIA','COMPRA','PAGO','COMISION'))
    THROW 50002, 'Datos inválidos en transaccion. Revisar origen y mapping.', 1;
IF EXISTS (SELECT id_transaccion FROM #v_transaccion GROUP BY id_transaccion HAVING COUNT(*) > 1)
    THROW 50003, 'Duplicados en transaccion.id_transaccion.', 1;
IF EXISTS (SELECT codigo_operacion FROM #v_transaccion GROUP BY codigo_operacion HAVING COUNT(*) > 1)
    THROW 50003, 'Duplicados en transaccion.codigo_operacion.', 1;

IF EXISTS (
    SELECT 1 FROM #v_transaccion t
    LEFT JOIN #v_cuenta c ON c.id_cuenta = t.id_cuenta
    LEFT JOIN #v_canal ca ON ca.id_canal = t.id_canal
    WHERE c.id_cuenta IS NULL OR ca.id_canal IS NULL
)
    THROW 50004, 'Transacciones con cuenta o canal inexistente.', 1;

-- Publicación atómica: si falla, conservar la versión Silver anterior.
BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM slv.cuenta;
    INSERT INTO slv.cuenta (id_cuenta, id_cliente, numero_cuenta, tipo_cuenta, moneda, saldo_actual, fecha_apertura, estado)
    SELECT id_cuenta, id_cliente, numero_cuenta, tipo_cuenta, moneda, saldo_actual, fecha_apertura, estado FROM #v_cuenta;
    DELETE FROM slv.canal;
    INSERT INTO slv.canal (id_canal, nombre_canal, tipo_canal, estado)
    SELECT id_canal, nombre_canal, tipo_canal, estado FROM #v_canal;
    DELETE FROM slv.transaccion;
    INSERT INTO slv.transaccion (id_transaccion, id_cuenta, id_canal, codigo_operacion, fecha_transaccion, tipo_transaccion, naturaleza, monto, descripcion, estado)
    SELECT id_transaccion, id_cuenta, id_canal, codigo_operacion, fecha_transaccion, tipo_transaccion, naturaleza, monto, descripcion, estado FROM #v_transaccion;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
