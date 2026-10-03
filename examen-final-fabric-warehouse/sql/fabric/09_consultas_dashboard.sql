-- Referencias para comparar con DAX con los mismos filtros.
SELECT ca.nombre_canal, c.moneda, COUNT_BIG(*) aprobadas, SUM(t.monto) monto
FROM gld.fct_transaccion t
JOIN gld.dim_canal ca ON ca.id_canal=t.id_canal
JOIN gld.dim_cuenta c ON c.id_cuenta=t.id_cuenta
WHERE t.estado='APROBADA'
GROUP BY ca.nombre_canal, c.moneda;
SELECT CONVERT(VARCHAR(7),t.fecha,126) anio_mes, c.moneda,
 COUNT_BIG(*) aprobadas, SUM(t.monto) monto
FROM gld.fct_transaccion t JOIN gld.dim_cuenta c ON c.id_cuenta=t.id_cuenta
WHERE t.estado='APROBADA'
GROUP BY CONVERT(VARCHAR(7),t.fecha,126), c.moneda;
