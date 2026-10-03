-- Ejecutar después de Gold y antes de actualizar el modelo.
IF (SELECT COUNT_BIG(*) FROM brz.banco_cuenta) <> (SELECT COUNT_BIG(*) FROM slv.cuenta)
 OR (SELECT COUNT_BIG(*) FROM slv.cuenta) <> (SELECT COUNT_BIG(*) FROM gld.dim_cuenta)
    THROW 50006, 'Conteos no coinciden: cuenta.', 1;
IF EXISTS (SELECT id_cuenta FROM gld.dim_cuenta GROUP BY id_cuenta HAVING COUNT(*) > 1)
    THROW 50007, 'Clave Gold duplicada: dim_cuenta.', 1;
IF (SELECT COUNT_BIG(*) FROM brz.banco_canal) <> (SELECT COUNT_BIG(*) FROM slv.canal)
 OR (SELECT COUNT_BIG(*) FROM slv.canal) <> (SELECT COUNT_BIG(*) FROM gld.dim_canal)
    THROW 50006, 'Conteos no coinciden: canal.', 1;
IF EXISTS (SELECT id_canal FROM gld.dim_canal GROUP BY id_canal HAVING COUNT(*) > 1)
    THROW 50007, 'Clave Gold duplicada: dim_canal.', 1;
IF (SELECT COUNT_BIG(*) FROM brz.banco_transaccion) <> (SELECT COUNT_BIG(*) FROM slv.transaccion)
 OR (SELECT COUNT_BIG(*) FROM slv.transaccion) <> (SELECT COUNT_BIG(*) FROM gld.fct_transaccion)
    THROW 50006, 'Conteos no coinciden: transaccion.', 1;
IF EXISTS (SELECT id_transaccion FROM gld.fct_transaccion GROUP BY id_transaccion HAVING COUNT(*) > 1)
    THROW 50007, 'Clave Gold duplicada: fct_transaccion.', 1;
IF EXISTS (
 SELECT 1 FROM gld.fct_transaccion t
 LEFT JOIN gld.dim_cuenta c ON c.id_cuenta=t.id_cuenta
 LEFT JOIN gld.dim_canal ca ON ca.id_canal=t.id_canal
 LEFT JOIN gld.dim_fecha f ON f.fecha=t.fecha
 WHERE c.id_cuenta IS NULL OR ca.id_canal IS NULL OR f.fecha IS NULL
)
 THROW 50008, 'Hechos huérfanos.', 1;
IF EXISTS (
 SELECT fecha FROM gld.dim_fecha GROUP BY fecha HAVING COUNT(*) > 1
)
 THROW 50009, 'Fechas duplicadas.', 1;
IF EXISTS (
 SELECT moneda, SUM(saldo_actual) saldo FROM slv.cuenta GROUP BY moneda
 EXCEPT
 SELECT moneda, SUM(saldo_actual) FROM gld.dim_cuenta GROUP BY moneda
) OR EXISTS (
 SELECT c.moneda, t.estado, SUM(t.monto) monto
 FROM slv.transaccion t JOIN slv.cuenta c ON c.id_cuenta=t.id_cuenta
 GROUP BY c.moneda, t.estado
 EXCEPT
 SELECT c.moneda, t.estado, SUM(t.monto)
 FROM gld.fct_transaccion t JOIN gld.dim_cuenta c ON c.id_cuenta=t.id_cuenta
 GROUP BY c.moneda, t.estado
)
 THROW 50010, 'Importes Silver y Gold no coinciden.', 1;
SELECT 'VALIDACION CORRECTA' resultado;
SELECT moneda, COUNT_BIG(*) cuentas, SUM(saldo_actual) saldo
FROM gld.dim_cuenta GROUP BY moneda;
SELECT c.moneda, t.estado, COUNT_BIG(*) operaciones, SUM(t.monto) monto
FROM gld.fct_transaccion t JOIN gld.dim_cuenta c ON c.id_cuenta=t.id_cuenta
GROUP BY c.moneda, t.estado;
