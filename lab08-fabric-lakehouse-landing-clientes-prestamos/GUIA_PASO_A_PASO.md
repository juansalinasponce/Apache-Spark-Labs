# Guía paso a paso

## Paso 01 — Validar el origen MySQL

Confirma que existen `banco_cliente` y `banco_prestamo`, que ambas tienen datos
y que no existen préstamos sin cliente. Puedes reutilizar la validación del
[Lab 07](../lab07-fabric-warehouse-clientes-prestamos/sql/mysql/01_validar_origen.sql).

## Paso 02 — Crear el Lakehouse

1. Abre `wk_banca_dev`.
2. Crea un Lakehouse llamado `lh_banca_dev_medallion`.
3. Conserva seleccionada la opción **Lakehouse schemas**.
4. Crea un notebook llamado `nb_banca_dev_crear_lakehouse` y adjunta el
   Lakehouse.
5. Selecciona Spark SQL como lenguaje y ejecuta:
   [`01_crear_tablas_bronze_silver.sql`](sql/lakehouse/01_crear_tablas_bronze_silver.sql).

Debes obtener los schemas `brz` y `slv`, cada uno con dos tablas Delta.

## Paso 03 — Crear el Warehouse Gold

1. En el mismo workspace crea `wh_banca_dev_gold`.
2. Abre una consulta T-SQL.
3. Ejecuta una sola vez:
   [`01_crear_staging_gold.sql`](sql/warehouse/01_crear_staging_gold.sql).

Debes obtener los schemas `stg` y `gld`, cada uno con dos tablas.

## Paso 04 — Preparar los notebooks del pipeline

Crea dos notebooks con el Lakehouse adjunto:

| Notebook | Script |
|---|---|
| `nb_banca_dev_limpiar_bronze` | `sql/lakehouse/02_limpiar_bronze.sql` |
| `nb_banca_dev_cargar_silver` | `sql/lakehouse/03_cargar_silver.sql` |

Usa celdas Spark SQL. Ejecuta manualmente cada notebook una vez para detectar
errores de contexto antes de incorporarlo al pipeline.

## Paso 05 — Crear el pipeline

Crea `pl_banca_dev_lakehouse_warehouse` y agrega las actividades descritas en
[`CONFIGURACION_PIPELINE.md`](pipeline/CONFIGURACION_PIPELINE.md).

El flujo general debe ser:

```text
limpiar Bronze
      │
      ├── copiar cliente ──┐
      └── copiar préstamo ─┤
                           ▼
                     cargar Silver
                           │
                           ▼
                  limpiar staging WH
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
     copiar cliente SCD2          copiar préstamo
             └─────────────┬─────────────┘
                           ▼
                       cargar Gold
```

## Paso 06 — Configurar MySQL hacia Bronze

Configura dos actividades Copy Data:

| Origen MySQL | Destino Lakehouse |
|---|---|
| `banco_cliente` | `brz.banco_cliente` |
| `banco_prestamo` | `brz.banco_prestamo` |

Importa el schema y revisa manualmente el mapping. Todas las columnas destino
deben permanecer como `STRING`, aunque MySQL exponga tipos numéricos o fechas.

No permitas que Copy Data elimine y vuelva a crear las tablas, porque eso podría
reemplazar el DDL de Bronze. El notebook anterior ya realiza el truncado.

## Paso 07 — Procesar Silver

Ejecuta `nb_banca_dev_cargar_silver` después de que terminen las dos copias.

El notebook realiza:

1. conversión segura con `TRY_CAST`;
2. normalización de texto;
3. deduplicación por clave de negocio;
4. cálculo del hash de atributos;
5. `MERGE` SCD Tipo 2 para clientes;
6. `MERGE` Tipo 1 para préstamos.

## Paso 08 — Copiar Silver al Warehouse

Primero ejecuta
[`02_limpiar_staging.sql`](sql/warehouse/02_limpiar_staging.sql) mediante una
actividad Script conectada al Warehouse.

Después configura estas copias en paralelo:

| Origen Lakehouse | Destino Warehouse |
|---|---|
| `slv.cliente` | `stg.cliente` |
| `slv.prestamo` | `stg.prestamo` |

Usa copia completa. `stg` es una zona técnica reemplazable; el historial
persistente se mantiene en Silver y Gold.

## Paso 09 — Cargar Gold

Después de ambas copias, ejecuta
[`03_cargar_gold.sql`](sql/warehouse/03_cargar_gold.sql) mediante una actividad
Script conectada a `wh_banca_dev_gold`.

El primer `MERGE` replica en `gld.dim_cliente` las versiones de Silver. El
segundo carga los préstamos y asigna a los nuevos hechos el `cliente_sk` vigente.

## Paso 10 — Ejecutar la carga inicial

1. Ejecuta el pipeline.
2. Comprueba que todas las actividades terminen correctamente.
3. Ejecuta
   [`04_validar_lakehouse.sql`](sql/lakehouse/04_validar_lakehouse.sql) con
   Spark SQL.
4. Ejecuta [`04_validar_gold.sql`](sql/warehouse/04_validar_gold.sql) con T-SQL.
5. Confirma que cada cliente tenga una sola versión y que sea actual.

## Paso 11 — Demostrar SCD Tipo 2

Selecciona un cliente con préstamo y modifica en MySQL un atributo descriptivo.
Por ejemplo, usa un valor válido para el catálogo de `segmento`:

```sql
UPDATE banco_cliente
SET segmento = 'PREFERENTE'
WHERE id_cliente = <ID_ELEGIDO>;
```

No ejecutes el ejemplo sin sustituir `<ID_ELEGIDO>` y no modifiques una fila si
ya tiene ese segmento.

Ejecuta nuevamente el pipeline y consulta el historial:

```sql
SELECT
    id_cliente,
    segmento,
    vigente_desde,
    vigente_hasta,
    es_actual,
    cliente_sk
FROM slv.cliente
WHERE id_cliente = <ID_ELEGIDO>
ORDER BY vigente_desde;
```

Debes observar dos versiones. Ejecuta el pipeline por tercera vez sin nuevos
cambios: el conteo debe permanecer en dos.

## Paso 12 — Crear el modelo semántico

Desde `wh_banca_dev_gold`, crea el modelo
`sm_banca_dev_clientes_prestamos_lh` con:

```text
gld.dim_cliente
gld.fct_prestamo
```

Crea una relación activa `1:*` desde `dim_cliente[cliente_sk]` hacia
`fct_prestamo[cliente_sk]`. Para análisis del estado actual, filtra
`dim_cliente[es_actual] = TRUE`; para analizar el historial conserva todas las
versiones.
