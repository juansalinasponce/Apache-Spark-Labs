-- Carga completa: limpiar Bronze antes de copiar el snapshot actual de MySQL.
-- Ejecutar con Spark SQL sobre lh_banca_dev_medallion.

TRUNCATE TABLE brz.banco_cliente;
TRUNCATE TABLE brz.banco_prestamo;
