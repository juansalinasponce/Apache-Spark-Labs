# Guía del examen final — Cuentas, canales y transacciones

## Paso 1. Comprender el caso (20 min)

Leer ENUNCIADO.md. Identificar el grano: una fila de cuenta, una fila de canal y una fila por operación. La transacción relaciona una cuenta con el canal donde se registra la operación. Una cuenta puede usar diferentes canales; su tabla no tiene id_canal.

## Paso 2. Preparar recursos (20 min)

Usar un workspace con capacidad Fabric habilitada y permisos para crear Warehouse, pipeline, modelo semántico y reporte. Disponer de la conexión MySQL del curso y gateway si el origen privado lo requiere. El docente entrega credenciales mediante un canal seguro. No guardar secretos en scripts ni capturas.

Crear wh_banca_final_<apellido> en el workspace del examen. Sustituir <apellido> en todos los nombres de artefactos, no en los nombres de las tablas. Cada estudiante trabaja en su Warehouse para evitar sobrescribir las tablas de otros. Seleccionar este Warehouse en el editor SQL y en las conexiones del pipeline.

## Paso 3. Validar MySQL (20 min)

Ejecutar sql/mysql/01_validar_origen.sql en MySQL, no en Fabric. Comparar columnas con la captura y confirmar que banco_transaccion tiene id_cuenta e id_canal. Guardar conteos, fechas mínima/máxima y saldos por moneda. Huérfanos debe ser cero. Si el origen varía respecto del DDL del Lab05, ajustar mapping y tipos antes de seguir. No hay conteos fijos para el examen.

## Paso 4. Crear la estructura Warehouse (25 min)

Ejecutar una sola vez, en orden:

1. sql/fabric/01_crear_schemas.sql.
2. sql/fabric/02_crear_bronze.sql.
3. sql/fabric/03_crear_silver.sql.
4. sql/fabric/04_crear_gold.sql.

GO es separador de lotes del editor. Si no lo admite, ejecutar cada CREATE SCHEMA por separado sin GO. Los DDL no deben ir dentro del pipeline recurrente. Bronze usa texto para practicar conversión y validación; Silver contiene tipos analíticos. Se preserva el rango INT UNSIGNED de MySQL usando BIGINT para cuentas/clientes y BIGINT para transacciones, adecuado al volumen del curso; valores MySQL mayores al máximo BIGINT serán rechazados.

Gold tiene dim_cuenta, dim_canal, dim_fecha y fct_transaccion. Se usan claves naturales para simplificar; no se asume que Fabric impone unicidad o integridad referencial. Los scripts las comprueban.

## Paso 5. Ingestar Bronze (35 min)

Construir los primeros cuatro pasos del pipeline con pipeline/CONFIGURACION_PIPELINE.md: limpieza y tres copias. Ejecutar sin Silver/Gold para revisar Bronze. Comparar conteos con MySQL en una ventana de origen estable. Revisar cinco filas de cada tabla y formato ISO de fechas. Dejar Retry=0 para copias Append.

## Paso 6. Transformar Silver en T-SQL (35 min)

Ejecutar sql/fabric/06_cargar_silver.sql completo o añadirlo como actividad Script. TRY_CONVERT detecta valores no convertibles y NULLIF elimina textos vacíos; UPPER/TRIM estandarizan categorías. Se validan obligatorios, dominios, montos, duplicados y referencias. No se descartan filas silenciosamente: ante un error, corregir mapping/origen autorizado y repetir desde el inicio. La carga usa DELETE/INSERT dentro de una transacción y mantiene la Silver anterior si falla.

No agregar una regla que elimine cuentas cerradas, operaciones rechazadas o reversadas: son categorías del análisis. No deduplicar arbitrariamente filas incompatibles con la misma clave; se bloquea la publicación para investigar.

## Paso 7. Publicar Gold y conciliar (30 min)

Ejecutar sql/fabric/07_cargar_gold.sql, después sql/fabric/08_validar_capas.sql. Se agrega fecha sin hora a transacciones y se genera calendario continuo de años completos según sus fechas. Gold se reemplaza dentro de una transacción. Todos los conteos Bronze/Silver/Gold deben coincidir y los importes se concilian por moneda/estado. Guardar evidencia de VALIDACION CORRECTA.

## Paso 8. Crear modelo y medidas (35 min)

Seguir powerbi/MODELO_Y_DASHBOARD.md, seleccionar solo Gold, crear relaciones 1:* unidireccionales y pegar medidas.dax una medida por vez. Revisar el comportamiento diferente de las medidas de cuentas y de operaciones. Crear explícitamente el modelo: no se genera automáticamente con el Warehouse.

## Paso 9. Construir reporte y dashboard (45 min)

Seguir los campos de ambas páginas en powerbi/MODELO_Y_DASHBOARD.md. Separar saldos PEN y USD. Publicar/guardar el reporte, anclar cuatro mosaicos al dashboard y comparar Power BI con sql/fabric/09_consultas_dashboard.sql. Explicar tres hallazgos sin inventar cifras ni atribuir ingresos a montos de transacciones.

## Paso 10. Completar automatización (25 min)

Agregar validación y Semantic model refresh al final del pipeline. Todas las conexiones deben apuntar al Warehouse propio. Ejecutar dos veces con un origen estable y comprobar mismos conteos/importes sin duplicados. Programar una ejecución, documentar America/Lima y el historial exitoso. Probar un fallo en una copia del pipeline, luego restaurar y repetir la carga completa.

## Paso 11. Entregar (10 min)

Crear una carpeta de evidencias con capturas del Warehouse, pipeline completo, historial manual/programado, error controlado, relaciones, reporte, dashboard y resultados SQL. Adjuntar informe breve y scripts utilizados. Entregar enlaces internos accesibles al docente; no publicar el dashboard en la web pública.

## Problemas frecuentes

- Objeto ya existe: no repetir DDL; usar los scripts de carga.
- TRY_CONVERT devuelve NULL: revisar formato de fecha/decimal en Bronze y mapping.
- Duplicados: no reintentar una copia aislada; limpiar Bronze y ejecutar el pipeline entero.
- Cantidades repetidas por canal: revisar relaciones activas y usar medidas del hecho.
- Saldo por canal no cambia: comportamiento esperado; saldo pertenece a la cuenta, no a una operación.
- Dashboard no refleja la última carga: comprobar refresh semántico y el reporte; revisar caché del mosaico.
- Fallo de conexión: revisar permisos y gateway con el docente sin exponer secretos.

## Referencias oficiales

- Warehouse y tablas: https://learn.microsoft.com/en-us/fabric/data-warehouse/tables
- Transacciones SQL: https://learn.microsoft.com/en-us/fabric/data-warehouse/transactions
- Conector MySQL: https://learn.microsoft.com/en-us/fabric/data-factory/connector-mysql-database-overview
- Modelo semántico: https://learn.microsoft.com/en-us/fabric/data-warehouse/create-semantic-model
- Refresh en pipeline: https://learn.microsoft.com/en-us/fabric/data-factory/semantic-model-refresh-activity
- Direct Lake: https://learn.microsoft.com/en-us/fabric/fundamentals/direct-lake-how-it-works

Los pasos se prepararon con documentación oficial consultada el 03/10/2026. Los rótulos de interfaz pueden variar por idioma o actualización del servicio.
