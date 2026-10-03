-- Silver validada antes de publicar Gold. Recarga completa, sin SCD.
BEGIN TRY
    BEGIN TRANSACTION;
    DELETE FROM gld.fct_transaccion;
    DELETE FROM gld.dim_cuenta;
    DELETE FROM gld.dim_canal;
    DELETE FROM gld.dim_fecha;
    INSERT INTO gld.dim_cuenta (id_cuenta, id_cliente, numero_cuenta, tipo_cuenta, moneda, saldo_actual, fecha_apertura, estado)
    SELECT id_cuenta, id_cliente, numero_cuenta, tipo_cuenta, moneda, saldo_actual, fecha_apertura, estado FROM slv.cuenta;
    INSERT INTO gld.dim_canal (id_canal, nombre_canal, tipo_canal, estado)
    SELECT id_canal, nombre_canal, tipo_canal, estado FROM slv.canal;
    INSERT INTO gld.fct_transaccion (id_transaccion, id_cuenta, id_canal, codigo_operacion, fecha_transaccion, tipo_transaccion, naturaleza, monto, descripcion, estado, fecha)
    SELECT id_transaccion, id_cuenta, id_canal, codigo_operacion, fecha_transaccion, tipo_transaccion, naturaleza, monto, descripcion, estado, CAST(fecha_transaccion AS DATE) FROM slv.transaccion;

    -- Calendario continuo de años completos, sin recursión ni notebook.
    DECLARE @inicio DATE, @fin DATE;
    SELECT @inicio = DATEFROMPARTS(YEAR(MIN(fecha)), 1, 1),
           @fin = DATEFROMPARTS(YEAR(MAX(fecha)), 12, 31)
    FROM gld.fct_transaccion;
    IF @inicio IS NULL OR DATEDIFF(DAY, @inicio, @fin) >= 100000
        THROW 50005, 'Rango de fechas vacío o superior al calendario.', 1;
    ;WITH digito AS (
        SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d(n)
    ), numeros AS (
        SELECT a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n AS n
        FROM digito a CROSS JOIN digito b CROSS JOIN digito c
        CROSS JOIN digito d CROSS JOIN digito e
    ), fechas AS (
        SELECT DATEADD(DAY, n, @inicio) AS fecha
        FROM numeros WHERE n <= DATEDIFF(DAY, @inicio, @fin)
    )
    INSERT INTO gld.dim_fecha (fecha, anio, mes, anio_mes)
    SELECT fecha, YEAR(fecha), MONTH(fecha), CONVERT(VARCHAR(7), fecha, 126)
    FROM fechas;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
