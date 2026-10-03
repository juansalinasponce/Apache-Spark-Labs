-- Procedimiento orquestador. Ejecuta dimensiones antes que la tabla de hechos.

DROP PROCEDURE IF EXISTS gld.usp_cargar_gold;
GO

CREATE PROCEDURE gld.usp_cargar_gold
AS
BEGIN
    SET NOCOUNT ON;

    EXEC gld.usp_cargar_dim_cliente;
    EXEC gld.usp_cargar_dim_tipo_prestamo;
    EXEC gld.usp_cargar_fct_prestamo;
END;
GO

-- Ejecución manual de prueba:
-- EXEC gld.usp_cargar_gold;
