# Guía paso a paso

## Paso 01 — Validar MySQL

Confirma que existen `banco_cliente` y `banco_prestamo`, que ambas tienen datos
y que no existen préstamos sin cliente. Puedes reutilizar la validación del
[Lab 07](../lab07-fabric-warehouse-clientes-prestamos/sql/mysql/01_validar_origen.sql).

## Paso 02 — Crear la metadata del Lakehouse

1. Crea `lh_banca_dev_medallion` con **Lakehouse schemas** habilitado.
2. Abre **New SparkSQL Query** desde el explorador del Lakehouse.
3. Ejecuta
   [`01_crear_metadata_lakehouse.sql`](sql/lakehouse/01_crear_metadata_lakehouse.sql).
4. Actualiza el explorador y comprueba los schemas `brz` y `slv`.

El DDL se mantiene en SQL porque su responsabilidad es definir metadata. No
contiene lógica ETL.

## Paso 03 — Crear el notebook PySpark

1. Importa [`03_cargar_silver.py`](notebooks/03_cargar_silver.py).
2. Guárdalo como `nb_banca_dev_cargar_silver`.
3. Selecciona PySpark como lenguaje principal.
4. Adjunta `lh_banca_dev_medallion` como Lakehouse predeterminado.
5. Recorre y ejecuta las secciones una por una.

El notebook está escrito de manera lineal para que el alumno pueda observar:

```text
leer → limpiar → tipificar → comparar → cerrar versión → insertar versión
```

## Paso 04 — Preparar la limpieza Bronze

Crea un notebook Spark SQL llamado `nb_banca_dev_limpiar_bronze`, adjunta el
Lakehouse y copia el contenido de
[`02_limpiar_bronze.sql`](sql/lakehouse/02_limpiar_bronze.sql).

Este notebook se usará al inicio del pipeline para recibir un snapshot completo.

## Paso 05 — Copiar MySQL hacia Bronze

Configura dos actividades Copy Data:

| Origen MySQL | Destino Lakehouse |
|---|---|
| `banco_cliente` | `brz.banco_cliente` |
| `banco_prestamo` | `brz.banco_prestamo` |

Importa el mapping y confirma que las columnas destino sigan siendo `STRING`.
Usa las tablas existentes; Copy Data no debe recrearlas.

## Paso 06 — Crear el Warehouse Gold

1. Crea `wh_banca_dev_gold` en el mismo workspace.
2. Desde su explorador, selecciona **+ Warehouses**.
3. Agrega el SQL analytics endpoint de `lh_banca_dev_medallion`.
4. Comprueba primero la lectura directa:

```sql
SELECT TOP 10 *
FROM [lh_banca_dev_medallion].[slv].[cliente];
```

La consulta puede estar vacía antes de la primera carga, pero debe reconocer la
tabla.

## Paso 07 — Crear tablas y procedimientos Gold

Ejecuta en `wh_banca_dev_gold`, en este orden:

1. [`01_crear_modelo_gold.sql`](sql/warehouse/01_crear_modelo_gold.sql)
2. [`02_crear_sp_dimensiones.sql`](sql/warehouse/02_crear_sp_dimensiones.sql)
3. [`03_crear_sp_hechos.sql`](sql/warehouse/03_crear_sp_hechos.sql)
4. [`04_crear_sp_cargar_gold.sql`](sql/warehouse/04_crear_sp_cargar_gold.sql)

Los procedimientos usan nombres de tres partes para consultar las tablas Delta
del Lakehouse sin crear staging en el Warehouse.

## Paso 08 — Crear el pipeline

Crea `pl_banca_dev_lakehouse_warehouse` siguiendo
[`CONFIGURACION_PIPELINE.md`](pipeline/CONFIGURACION_PIPELINE.md).

El flujo será:

```text
limpiar Bronze
      │
      ├── copiar cliente ──┐
      └── copiar préstamo ─┤
                           ▼
                  notebook PySpark Silver
                           │
                           ▼
                 SP gld.usp_cargar_gold
```

## Paso 09 — Ejecutar y validar

1. Ejecuta el pipeline.
2. Ejecuta
   [`04_validar_lakehouse.sql`](sql/lakehouse/04_validar_lakehouse.sql) con
   Spark SQL.
3. Ejecuta [`05_validar_gold.sql`](sql/warehouse/05_validar_gold.sql) con T-SQL.
4. Comprueba que cada cliente tenga una sola versión actual.
5. Comprueba que no existan préstamos sin dimensiones.

## Paso 10 — Demostrar el historial

Modifica un atributo descriptivo de un cliente en MySQL y ejecuta otra vez el
pipeline. Consulta sus versiones en `slv.cliente` y `gld.dim_cliente`.

Después ejecuta el pipeline sin nuevos cambios y confirma que el número de
versiones no aumente.

## Paso 11 — Crear el modelo semántico

Selecciona estas tablas del Warehouse:

```text
gld.dim_cliente
gld.dim_tipo_prestamo
gld.fct_prestamo
```

Configura relaciones `1:*`:

```text
dim_cliente[cliente_sk] → fct_prestamo[cliente_sk]
dim_tipo_prestamo[tipo_prestamo_sk] → fct_prestamo[tipo_prestamo_sk]
```
