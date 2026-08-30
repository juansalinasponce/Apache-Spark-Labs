# Laboratorio Data Engineering: Arquitectura Medallion en Databricks con Modelo OLTP, OLAP, SCD y Datamart de Ventas

## 1. Contexto del laboratorio

Este laboratorio implementa una arquitectura **Lakehouse Medallion** en Databricks para un caso de ventas de cursos, diplomados, especializaciones y bootcamps de Data & Analytics. El objetivo es que los alumnos comprendan el flujo completo de ingeniería de datos desde archivos CSV de origen hasta un modelo estrella en capa Gold, listo para consumo analítico con Databricks SQL Warehouse, Power BI u otra herramienta BI.

El caso simula una empresa educativa que registra ventas por diferentes canales: tienda física, web y partners. Las fuentes operacionales se modelan inicialmente como un sistema **OLTP** simple y luego se transforman hacia un modelo **OLAP** con dimensiones, hechos, Slowly Changing Dimensions y reportes agregados.

## 2. Problema que resuelve

El laboratorio resuelve los siguientes puntos:

1. Organizar archivos, scripts y tablas usando una taxonomía productiva.
2. Cargar datos crudos desde CSV hacia Bronze.
3. Limpiar, tipificar y estandarizar datos en Silver.
4. Aplicar SCD Tipo 1 y SCD Tipo 2 según el comportamiento de las entidades.
5. Construir un modelo estrella en Gold para un Datamart de Ventas.
6. Crear tablas de reporting listas para dashboards.
7. Dejar una estructura base que pueda escalar hacia proyectos productivos.

## 3. Arquitectura lógica

```text
CSV en S3 / Landing
        |
        v
Bronze / BRZ
Datos crudos, trazabilidad de ingesta, mínima transformación
        |
        v
Silver / SLV
Datos limpios, tipificados, deduplicados, estandarizados
        |
        v
Gold / GLD
Modelo dimensional, datamarts y reporting de negocio
        |
        v
Databricks SQL Warehouse / BI / Power BI
```

## 4. Convenciones generales

### 4.1 Nombres de capas

| Capa | Nombre corto | Propósito |
|---|---:|---|
| Bronze | `brz` | Persistir datos crudos desde landing, con metadatos de ingesta. |
| Silver | `slv` | Datos limpios, validados y homologados. |
| Gold | `gld` | Datos de negocio, dimensiones, hechos y agregados. |

### 4.2 Convención de archivos para Bronze y Silver

Para Bronze y Silver se usará la siguiente estructura:

```text
lakehouse/<capa>/<fuente>/<tabla>/<nombre_archivo>
```

El nombre del archivo debe seguir este patrón:

```text
{capa}-{fuente}-{tabla}-{ddl|etl}.{py|ipynb}
```

Ejemplos:

```text
lakehouse/brz/crm/clientes/brz-crm-clientes-ddl.py
lakehouse/brz/crm/clientes/brz-crm-clientes-etl.py
lakehouse/slv/crm/clientes/slv-crm-clientes-ddl.py
lakehouse/slv/crm/clientes/slv-crm-clientes-etl.py
```

### 4.3 Taxonomía productiva para Bronze

```text
lakehouse/
└── brz/
    ├── crm/
    │   └── clientes/
    │       ├── brz-crm-clientes-ddl.py
    │       └── brz-crm-clientes-etl.py
    ├── erp/
    │   ├── categorias/
    │   │   ├── brz-erp-categorias-ddl.py
    │   │   └── brz-erp-categorias-etl.py
    │   └── productos/
    │       ├── brz-erp-productos-ddl.py
    │       └── brz-erp-productos-etl.py
    └── pos/
        ├── tiendas/
        │   ├── brz-pos-tiendas-ddl.py
        │   └── brz-pos-tiendas-etl.py
        ├── vendedores/
        │   ├── brz-pos-vendedores-ddl.py
        │   └── brz-pos-vendedores-etl.py
        ├── ordenes/
        │   ├── brz-pos-ordenes-ddl.py
        │   └── brz-pos-ordenes-etl.py
        └── detalle_ordenes/
            ├── brz-pos-detalle_ordenes-ddl.py
            └── brz-pos-detalle_ordenes-etl.py
```

### 4.4 Taxonomía productiva para Silver

```text
lakehouse/
└── slv/
    ├── crm/
    │   └── clientes/
    │       ├── slv-crm-clientes-ddl.py
    │       └── slv-crm-clientes-etl.py
    ├── erp/
    │   ├── categorias/
    │   │   ├── slv-erp-categorias-ddl.py
    │   │   └── slv-erp-categorias-etl.py
    │   └── productos/
    │       ├── slv-erp-productos-ddl.py
    │       └── slv-erp-productos-etl.py
    └── pos/
        ├── tiendas/
        │   ├── slv-pos-tiendas-ddl.py
        │   └── slv-pos-tiendas-etl.py
        ├── vendedores/
        │   ├── slv-pos-vendedores-ddl.py
        │   └── slv-pos-vendedores-etl.py
        ├── ordenes/
        │   ├── slv-pos-ordenes-ddl.py
        │   └── slv-pos-ordenes-etl.py
        └── detalle_ordenes/
            ├── slv-pos-detalle_ordenes-ddl.py
            └── slv-pos-detalle_ordenes-etl.py
```

### 4.5 Taxonomía distinta para Gold: Datamart de Ventas

En Gold se recomienda separar por producto analítico, no por fuente operacional.

```text
lakehouse/
└── gld/
    └── datamarts/
        └── ventas/
            ├── dimensions/
            │   ├── dim_cliente/
            │   │   ├── gld-dm-ventas-dim_cliente-ddl.py
            │   │   └── gld-dm-ventas-dim_cliente-etl.py
            │   ├── dim_producto/
            │   │   ├── gld-dm-ventas-dim_producto-ddl.py
            │   │   └── gld-dm-ventas-dim_producto-etl.py
            │   ├── dim_tienda/
            │   │   ├── gld-dm-ventas-dim_tienda-ddl.py
            │   │   └── gld-dm-ventas-dim_tienda-etl.py
            │   ├── dim_vendedor/
            │   │   ├── gld-dm-ventas-dim_vendedor-ddl.py
            │   │   └── gld-dm-ventas-dim_vendedor-etl.py
            │   └── dim_fecha/
            │       ├── gld-dm-ventas-dim_fecha-ddl.py
            │       └── gld-dm-ventas-dim_fecha-etl.py
            └── facts/
                └── fact_ventas/
                    ├── gld-dm-ventas-fact_ventas-ddl.py
                    └── gld-dm-ventas-fact_ventas-etl.py
```

### 4.6 Taxonomía distinta para Gold: Reporting

La zona de reporting contiene tablas agregadas y orientadas a consumo directo.

```text
lakehouse/
└── gld/
    └── reporting/
        └── ventas/
            ├── rpt_ventas_mensual/
            │   ├── gld-rpt-ventas-rpt_ventas_mensual-ddl.py
            │   └── gld-rpt-ventas-rpt_ventas_mensual-etl.py
            ├── rpt_ventas_por_categoria/
            │   ├── gld-rpt-ventas-rpt_ventas_por_categoria-ddl.py
            │   └── gld-rpt-ventas-rpt_ventas_por_categoria-etl.py
            └── rpt_top_clientes/
                ├── gld-rpt-ventas-rpt_top_clientes-ddl.py
                └── gld-rpt-ventas-rpt_top_clientes-etl.py
```

## 5. Datos fuente CSV

Los archivos CSV deben cargarse manualmente a S3 en una zona landing.

### 5.1 Ruta sugerida de landing

```text
s3://<bucket>/lakehouse/landing/crm/clientes/clientes_cdc.csv
s3://<bucket>/lakehouse/landing/erp/categorias/categorias.csv
s3://<bucket>/lakehouse/landing/erp/productos/productos_cdc.csv
s3://<bucket>/lakehouse/landing/pos/tiendas/tiendas.csv
s3://<bucket>/lakehouse/landing/pos/vendedores/vendedores.csv
s3://<bucket>/lakehouse/landing/pos/ordenes/ordenes.csv
s3://<bucket>/lakehouse/landing/pos/detalle_ordenes/detalle_ordenes.csv
```

### 5.2 Tablas fuente OLTP

| Fuente | Archivo | Tabla conceptual OLTP | Descripción |
|---|---|---|---|
| CRM | `clientes_cdc.csv` | `clientes` | Clientes y cambios históricos para SCD Tipo 2. |
| ERP | `categorias.csv` | `categorias` | Catálogo de categorías de productos. |
| ERP | `productos_cdc.csv` | `productos` | Productos y cambios de precio/estado para SCD Tipo 1. |
| POS | `tiendas.csv` | `tiendas` | Tiendas, canal y ubicación. |
| POS | `vendedores.csv` | `vendedores` | Vendedores asociados a una tienda. |
| POS | `ordenes.csv` | `ordenes` | Cabecera transaccional de ventas. |
| POS | `detalle_ordenes.csv` | `detalle_ordenes` | Detalle transaccional de productos vendidos. |

## 6. Modelo OLTP inicial

```text
clientes 1 ──────── N ordenes
tiendas  1 ──────── N ordenes
vendedores 1 ───── N ordenes
ordenes 1 ───────── N detalle_ordenes
productos 1 ─────── N detalle_ordenes
categorias 1 ────── N productos
```

## 7. Diseño de Bronze

### 7.1 Objetivo

Bronze guarda los datos casi como llegaron desde S3, conservando trazabilidad técnica. No debe aplicar reglas complejas de negocio.

### 7.2 Columnas técnicas recomendadas

Todas las tablas Bronze deben incluir:

| Columna | Tipo | Descripción |
|---|---|---|
| `_ingestion_timestamp` | timestamp | Fecha y hora de carga. |
| `_source_file` | string | Archivo físico leído desde S3. |
| `_source_system` | string | Fuente lógica: CRM, ERP o POS. |
| `_batch_id` | string | Identificador del lote de carga. |

### 7.3 Tablas Bronze

```text
brz.crm_clientes
brz.erp_categorias
brz.erp_productos
brz.pos_tiendas
brz.pos_vendedores
brz.pos_ordenes
brz.pos_detalle_ordenes
```

## 8. Diseño de Silver

### 8.1 Objetivo

Silver representa datos limpios, normalizados y listos para reglas de negocio. Aquí se aplican:

- Conversión de tipos.
- Homologación de nombres.
- Eliminación de duplicados.
- Validaciones básicas.
- Limpieza de nulos.
- Normalización de fechas, importes y claves.

### 8.2 Tablas Silver

```text
slv.crm_clientes
slv.erp_categorias
slv.erp_productos
slv.pos_tiendas
slv.pos_vendedores
slv.pos_ordenes
slv.pos_detalle_ordenes
```

### 8.3 Reglas mínimas de calidad

| Regla | Tabla | Acción |
|---|---|---|
| `cliente_id` no nulo | clientes, ordenes | Rechazar o enviar a cuarentena. |
| `producto_id` no nulo | productos, detalle_ordenes | Rechazar o enviar a cuarentena. |
| `orden_id` no nulo | ordenes, detalle_ordenes | Rechazar o enviar a cuarentena. |
| `fecha_orden` válida | ordenes | Convertir a fecha; si falla, cuarentena. |
| Importes >= 0 | ordenes, detalle_ordenes | Validar o marcar como error. |
| Cantidad > 0 | detalle_ordenes | Validar o marcar como error. |

## 9. Diseño Gold: Datamart de Ventas

## 9.1 Modelo estrella

```text
                    dim_fecha
                        |
dim_cliente ──── fact_ventas ──── dim_producto
                        |
                   dim_tienda
                        |
                  dim_vendedor
```

### 9.2 Dimensiones

| Dimensión | Fuente principal | Tipo SCD | Justificación |
|---|---|---:|---|
| `dim_cliente` | `slv.crm_clientes` | Tipo 2 | Se desea conservar historial de segmento, ciudad o datos comerciales del cliente. |
| `dim_producto` | `slv.erp_productos` | Tipo 1 | Para el laboratorio se sobrescribe precio/lista/estado y se mantiene la visión vigente. |
| `dim_tienda` | `slv.pos_tiendas` | Tipo 1 | Los atributos son estables o no requieren historial para el análisis. |
| `dim_vendedor` | `slv.pos_vendedores` | Tipo 1 | Se mantiene la versión vigente del vendedor. |
| `dim_fecha` | Calendario generado | No aplica | Dimensión derivada para análisis temporal. |

### 9.3 Tabla de hechos

| Hecho | Grano | Descripción |
|---|---|---|
| `fact_ventas` | Una fila por línea de orden vendida | Integra orden, detalle, producto, cliente, tienda, vendedor y fecha. |

### 9.4 Métricas de `fact_ventas`

| Métrica | Descripción |
|---|---|
| `cantidad` | Cantidad vendida. |
| `precio_unitario` | Precio unitario al momento de la venta. |
| `descuento_linea` | Descuento aplicado a la línea. |
| `impuesto_linea` | Impuesto calculado. |
| `total_linea` | Total neto de la línea con impuesto. |
| `venta_bruta` | Cantidad * precio unitario. |
| `venta_neta` | Venta luego de descuento e impuesto. |

## 10. Implementación SCD

### 10.1 SCD Tipo 1 para `dim_producto`

Uso recomendado:

- Sobrescribir cambios de precio, nombre, marca, estado o categoría.
- No mantener historial.
- Implementar con `MERGE INTO` sobre Delta.

Clave de negocio:

```text
producto_id
```

Columnas a actualizar:

```text
categoria_id, sku, nombre_producto, marca, precio_lista, estado, fecha_actualizacion
```

### 10.2 SCD Tipo 2 para `dim_cliente`

Uso recomendado:

- Mantener historial de segmento, ciudad, departamento, país o email.
- Crear una nueva versión cuando cambie un atributo relevante.
- Mantener columnas de vigencia.

Clave de negocio:

```text
cliente_id
```

Columnas de control SCD2:

```text
cliente_sk
cliente_id
fecha_inicio_vigencia
fecha_fin_vigencia
es_actual
hash_diff
```

Regla:

1. Si el cliente no existe, insertar como versión actual.
2. Si el cliente existe y cambió el `hash_diff`, cerrar la versión vigente.
3. Insertar una nueva versión con `es_actual = true`.

## 11. Repositorio esperado

Codex debe generar la siguiente estructura:

```text
databricks-medallion-lab/
├── README.md
├── configs/
│   └── lab_config.py
├── data/
│   └── source/
│       ├── crm/
│       ├── erp/
│       └── pos/
├── lakehouse/
│   ├── brz/
│   ├── slv/
│   └── gld/
├── tests/
│   ├── test_row_counts.py
│   └── test_quality_rules.py
└── docs/
    ├── arquitectura_medallion.md
    └── diccionario_datos.md
```

## 12. Parámetros del laboratorio

Crear un archivo `configs/lab_config.py` con parámetros centralizados.

```python
CATALOG = "workspace"
SCHEMA_BRONZE = "brz"
SCHEMA_SILVER = "slv"
SCHEMA_GOLD = "gld"

S3_BUCKET = "s3://<bucket>"
LANDING_PATH = f"{S3_BUCKET}/lakehouse/landing"
BRONZE_PATH = f"{S3_BUCKET}/lakehouse/brz"
SILVER_PATH = f"{S3_BUCKET}/lakehouse/slv"
GOLD_PATH = f"{S3_BUCKET}/lakehouse/gld"

BATCH_ID = "manual_001"
```

## 13. Orden de ejecución sugerido

### Paso 1: Cargar CSV a S3

Subir los CSV a las rutas landing definidas.

### Paso 2: Crear esquemas

Crear los schemas:

```sql
CREATE SCHEMA IF NOT EXISTS brz;
CREATE SCHEMA IF NOT EXISTS slv;
CREATE SCHEMA IF NOT EXISTS gld;
```

### Paso 3: Ejecutar DDL Bronze

Ejecutar todos los archivos:

```text
brz-*-ddl.py
```

### Paso 4: Ejecutar ETL Bronze

Ejecutar todos los archivos:

```text
brz-*-etl.py
```

### Paso 5: Ejecutar DDL Silver

Ejecutar todos los archivos:

```text
slv-*-ddl.py
```

### Paso 6: Ejecutar ETL Silver

Ejecutar todos los archivos:

```text
slv-*-etl.py
```

### Paso 7: Ejecutar Gold Datamart

Orden recomendado:

```text
dim_fecha
dim_cliente
dim_producto
dim_tienda
dim_vendedor
fact_ventas
```

### Paso 8: Ejecutar Gold Reporting

Orden recomendado:

```text
rpt_ventas_mensual
rpt_ventas_por_categoria
rpt_top_clientes
```

## 14. Consultas de validación para clase

### 14.1 Ventas mensuales

```sql
SELECT
    f.anio,
    f.mes,
    SUM(v.venta_neta) AS venta_neta
FROM gld.fact_ventas v
JOIN gld.dim_fecha f
    ON v.fecha_sk = f.fecha_sk
GROUP BY f.anio, f.mes
ORDER BY f.anio, f.mes;
```

### 14.2 Ventas por categoría

```sql
SELECT
    p.nombre_categoria,
    SUM(v.venta_neta) AS venta_neta,
    SUM(v.cantidad) AS cantidad_vendida
FROM gld.fact_ventas v
JOIN gld.dim_producto p
    ON v.producto_sk = p.producto_sk
GROUP BY p.nombre_categoria
ORDER BY venta_neta DESC;
```

### 14.3 Clientes con cambios históricos

```sql
SELECT
    cliente_id,
    nombres,
    apellidos,
    ciudad,
    segmento,
    fecha_inicio_vigencia,
    fecha_fin_vigencia,
    es_actual
FROM gld.dim_cliente
WHERE cliente_id IN (
    SELECT cliente_id
    FROM gld.dim_cliente
    GROUP BY cliente_id
    HAVING COUNT(*) > 1
)
ORDER BY cliente_id, fecha_inicio_vigencia;
```

## 15. Criterios de aceptación

El laboratorio se considera completo si:

1. Los CSV fueron cargados correctamente a S3.
2. Todas las tablas Bronze fueron creadas y pobladas.
3. Todas las tablas Silver fueron creadas y pobladas con tipos correctos.
4. `dim_producto` aplica SCD Tipo 1.
5. `dim_cliente` aplica SCD Tipo 2.
6. `fact_ventas` tiene una fila por cada línea válida de venta.
7. Existen reportes agregados en Gold Reporting.
8. Las consultas de validación devuelven resultados consistentes.
9. El modelo puede ser consultado desde Databricks SQL Warehouse.

## 16. Resultado esperado para los alumnos

Al finalizar, el alumno debe poder explicar:

- La diferencia entre OLTP y OLAP.
- Por qué Bronze no debe aplicar reglas complejas.
- Qué problemas resuelve Silver.
- Cuándo usar SCD Tipo 1 y Tipo 2.
- Cómo una tabla de hechos se relaciona con dimensiones.
- Cómo se organiza un repositorio de ingeniería de datos con enfoque productivo.
- Cómo un Datamart en Gold puede ser consumido por BI.
