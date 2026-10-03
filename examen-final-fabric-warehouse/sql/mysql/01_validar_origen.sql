-- Ejecutar en MySQL, seleccionando la base de datos del curso.
SHOW COLUMNS FROM banco_cuenta;
SHOW COLUMNS FROM banco_canal;
SHOW COLUMNS FROM banco_transaccion;
SELECT 'cuenta' tabla, COUNT(*) filas FROM banco_cuenta
UNION ALL SELECT 'canal', COUNT(*) FROM banco_canal
UNION ALL SELECT 'transaccion', COUNT(*) FROM banco_transaccion;
SELECT moneda, COUNT(*) cuentas, SUM(saldo_actual) saldo
FROM banco_cuenta GROUP BY moneda;
SELECT MIN(fecha_transaccion) primera, MAX(fecha_transaccion) ultima
FROM banco_transaccion;
SELECT COUNT(*) huerfanos
FROM banco_transaccion t
LEFT JOIN banco_cuenta c ON c.id_cuenta=t.id_cuenta
LEFT JOIN banco_canal ca ON ca.id_canal=t.id_canal
WHERE c.id_cuenta IS NULL OR ca.id_canal IS NULL;
SELECT ca.nombre_canal, c.moneda, t.estado, COUNT(*) operaciones, SUM(t.monto) monto
FROM banco_transaccion t
JOIN banco_cuenta c ON c.id_cuenta=t.id_cuenta
JOIN banco_canal ca ON ca.id_canal=t.id_canal
GROUP BY ca.nombre_canal, c.moneda, t.estado;
