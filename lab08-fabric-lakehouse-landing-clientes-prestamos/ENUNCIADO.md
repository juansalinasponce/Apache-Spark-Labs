# Enunciado — Fabric 02: Lakehouse y Warehouse Gold

## Situación

El banco necesita analizar sus clientes y préstamos. Los datos se encuentran en
MySQL y deben procesarse con una arquitectura híbrida de Microsoft Fabric.

Bronze y Silver estarán en un Lakehouse. Gold estará en un Warehouse y deberá
leer Silver directamente, sin duplicar los datos en tablas de staging.

## Objetivo

Construir el flujo:

```text
MySQL → Bronze Delta → Silver Delta → Warehouse Gold → Power BI
```

Al finalizar se debe poder analizar:

1. cantidad de clientes y préstamos;
2. montos desembolsados, pagados y pendientes;
3. colocaciones por tipo de préstamo y segmento;
4. evolución mensual de desembolsos;
5. historial de cambios de los clientes.

## Requerimientos de metadata

1. Crea los schemas `brz` y `slv` con Spark SQL.
2. Crea `brz.banco_cliente` y `brz.banco_prestamo` como tablas Delta.
3. Declara todas las columnas Bronze como `STRING`.
4. Crea `slv.cliente` y `slv.prestamo` como tablas Delta tipificadas.
5. Mantén el DDL separado del código de transformación.

## Requerimientos del ETL PySpark

Implementa Bronze → Silver en un único notebook PySpark fácil de seguir.

El notebook debe mostrar de forma explícita:

1. lectura mediante `spark.table`;
2. limpieza con `trim`, `upper` y `lower`;
3. conversión de tipos con `cast`;
4. deduplicación con `row_number`;
5. cálculo de un hash para detectar cambios;
6. cierre de la versión anterior con `DeltaTable.merge`;
7. inserción de la nueva versión del cliente;
8. upsert del último estado del préstamo.

Evita clases, decoradores, configuraciones dinámicas y abstracciones avanzadas.
El propósito es que un alumno pueda ejecutar cada sección y comprenderla.

## Requerimientos del historial

Usa `id_cliente` como clave de negocio. `slv.cliente` debe incluir:

```text
cliente_sk
vigente_desde
vigente_hasta
es_actual
hash_atributos
fecha_proceso
```

Una modificación debe cerrar la versión anterior y crear una nueva. Una tercera
ejecución sin cambios no debe insertar otra versión.

## Requerimientos de Gold

1. Crea `gld.dim_cliente`, `gld.dim_tipo_prestamo` y `gld.fct_prestamo`.
2. Usa `BIGINT IDENTITY` para la clave de `dim_tipo_prestamo`.
3. Crea procedimientos separados para cargar cada dimensión y el hecho.
4. Los procedimientos deben leer directamente:
   - `[lh_banca_dev_medallion].[slv].[cliente]`;
   - `[lh_banca_dev_medallion].[slv].[prestamo]`.
5. Usa `MERGE` para que las cargas sean repetibles.
6. Crea un procedimiento orquestador `gld.usp_cargar_gold`.
7. Ejecuta primero las dimensiones y después la tabla de hechos.
8. No crees tablas staging en el Warehouse.

## Prueba de historial

1. Ejecuta la carga inicial.
2. Cambia el segmento, estado, email o teléfono de un cliente en MySQL.
3. Ejecuta nuevamente el flujo.
4. Confirma que el cliente tenga dos versiones y dos `cliente_sk` distintos.
5. Ejecuta el flujo una tercera vez sin cambios.
6. Confirma que el cliente continúe teniendo únicamente dos versiones.

## Entregables

- DDL Spark SQL del Lakehouse.
- Notebook PySpark de Bronze → Silver.
- DDL T-SQL del modelo Gold.
- Procedimientos almacenados de dimensiones y hechos.
- Pipeline ejecutado correctamente.
- Evidencia del historial del cliente.
- Consultas de validación.

## Criterios de finalización

- Bronze conserva todas las columnas como `STRING`.
- Silver contiene datos tipificados.
- Cada cliente tiene exactamente una versión actual.
- El ETL PySpark es idempotente cuando no cambia el origen.
- Los procedimientos leen las tablas Delta sin staging intermedio.
- Gold no contiene préstamos sin dimensiones relacionadas.
