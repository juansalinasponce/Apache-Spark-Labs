# Prompt para Codex: Generar laboratorio Databricks Medallion con OLTP, OLAP, SCD y Datamart de Ventas

Actúa como un Senior Data Engineer especializado en Databricks, Delta Lake, PySpark, modelamiento dimensional y arquitectura Medallion. Necesito que generes un repositorio completo para un laboratorio académico, claro, ejecutable y mantenible, orientado a alumnos de Data Engineering.

## 1. Objetivo general

Generar un laboratorio en Databricks que implemente una arquitectura Medallion usando datos CSV cargados manualmente en S3. El flujo debe cubrir:

1. Ingesta desde S3 Landing hacia Bronze.
2. Limpieza y estandarización en Silver.
3. Implementación de SCD Tipo 1 y SCD Tipo 2.
4. Construcción de un modelo estrella en Gold para un Datamart de Ventas.
5. Creación de tablas agregadas de reporting para consumo BI.
6. Documentación clara para que un alumno entienda el proceso completo.

## 2. Caso de negocio

La empresa vende cursos, diplomados, especializaciones y bootcamps de Data & Analytics en canales Web, Tienda y Partner. Las ventas se registran en un sistema POS; los clientes vienen de CRM; los productos y categorías vienen de ERP.

## 3. Archivos CSV fuente

El repositorio debe esperar los siguientes archivos en S3:

```text
s3://<bucket>/lakehouse/landing/crm/clientes/clientes_cdc.csv
s3://<bucket>/lakehouse/landing/erp/categorias/categorias.csv
s3://<bucket>/lakehouse/landing/erp/productos/productos_cdc.csv
s3://<bucket>/lakehouse/landing/pos/tiendas/tiendas.csv
s3://<bucket>/lakehouse/landing/pos/vendedores/vendedores.csv
s3://<bucket>/lakehouse/landing/pos/ordenes/ordenes.csv
s3://<bucket>/lakehouse/landing/pos/detalle_ordenes/detalle_ordenes.csv
```

## 4. Estructura obligatoria del repositorio

Genera exactamente esta estructura base:

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
│   │   ├── crm/
│   │   │   └── clientes/
│   │   ├── erp/
│   │   │   ├── categorias/
│   │   │   └── productos/
│   │   └── pos/
│   │       ├── tiendas/
│   │       ├── vendedores/
│   │       ├── ordenes/
│   │       └── detalle_ordenes/
│   ├── slv/
│   │   ├── crm/
│   │   │   └── clientes/
│   │   ├── erp/
│   │   │   ├── categorias/
│   │   │   └── productos/
│   │   └── pos/
│   │       ├── tiendas/
│   │       ├── vendedores/
│   │       ├── ordenes/
│   │       └── detalle_ordenes/
│   └── gld/
│       ├── datamarts/
│       │   └── ventas/
│       │       ├── dimensions/
│       │       │   ├── dim_cliente/
│       │       │   ├── dim_producto/
│       │       │   ├── dim_tienda/
│       │       │   ├── dim_vendedor/
│       │       │   └── dim_fecha/
│       │       └── facts/
│       │           └── fact_ventas/
│       └── reporting/
│           └── ventas/
│               ├── rpt_ventas_mensual/
│               ├── rpt_ventas_por_categoria/
│               └── rpt_top_clientes/
├── tests/
│   ├── test_row_counts.py
│   └── test_quality_rules.py
└── docs/
    ├── arquitectura_medallion.md
    └── diccionario_datos.md
```

## 5. Convención obligatoria de nombres para Bronze y Silver

Cada tabla de Bronze y Silver debe tener dos archivos:

```text
{capa}-{fuente}-{tabla}-ddl.py
{capa}-{fuente}-{tabla}-etl.py
```

Ejemplo:

```text
lakehouse/brz/crm/clientes/brz-crm-clientes-ddl.py
lakehouse/brz/crm/clientes/brz-crm-clientes-etl.py
lakehouse/slv/crm/clientes/slv-crm-clientes-ddl.py
lakehouse/slv/crm/clientes/slv-crm-clientes-etl.py
```

## 6. Convención obligatoria para Gold

Gold no se debe organizar por fuente, sino por producto analítico:

```text
gld/datamarts/ventas/dimensions/<dimension>/
gld/datamarts/ventas/facts/<fact>/
gld/reporting/ventas/<reporte>/
```

Cada entidad de Gold debe tener:

```text
gld-dm-ventas-<tabla>-ddl.py
gld-dm-ventas-<tabla>-etl.py
```

Para reporting:

```text
gld-rpt-ventas-<reporte>-ddl.py
gld-rpt-ventas-<reporte>-etl.py
```

## 7. Configuración centralizada

Crear `configs/lab_config.py` con:

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

Permitir que el usuario cambie `S3_BUCKET` fácilmente.

## 8. Reglas para scripts DDL

Los archivos `ddl.py` deben crear tablas Delta externas o administradas según la configuración. Usar `spark.sql()`.

Cada tabla debe incluir comentarios de columnas cuando sea posible.

## 9. Reglas para scripts ETL Bronze

Cada script Bronze debe:

1. Leer CSV desde `LANDING_PATH`.
2. Usar `header=True`.
3. Inferir schema solo si es didáctico, pero preferir schema explícito.
4. Agregar columnas técnicas:
   - `_ingestion_timestamp`
   - `_source_file`
   - `_source_system`
   - `_batch_id`
5. Escribir en Delta usando modo `append` o `overwrite` según corresponda.
6. Registrar conteos de filas con `print()`.

## 10. Reglas para scripts ETL Silver

Cada script Silver debe:

1. Leer desde Bronze.
2. Convertir tipos de datos correctamente.
3. Estandarizar nombres de columnas.
4. Eliminar duplicados por clave natural y fecha de actualización cuando aplique.
5. Validar campos obligatorios.
6. Separar registros inválidos en una tabla o vista de cuarentena si es simple de implementar.
7. Escribir en Delta.

## 11. Modelo Silver esperado

Crear estas tablas:

```text
slv.crm_clientes
slv.erp_categorias
slv.erp_productos
slv.pos_tiendas
slv.pos_vendedores
slv.pos_ordenes
slv.pos_detalle_ordenes
```

## 12. Modelo Gold esperado

Crear estas dimensiones:

```text
gld.dim_cliente
gld.dim_producto
gld.dim_tienda
gld.dim_vendedor
gld.dim_fecha
```

Crear esta tabla de hechos:

```text
gld.fact_ventas
```

Crear estos reportes:

```text
gld.rpt_ventas_mensual
gld.rpt_ventas_por_categoria
gld.rpt_top_clientes
```

## 13. SCD Tipo 1

Implementar SCD Tipo 1 en:

```text
gld.dim_producto
gld.dim_tienda
gld.dim_vendedor
```

Para `dim_producto`, usar como clave natural:

```text
producto_id
```

Actualizar atributos:

```text
categoria_id
sku
nombre_producto
marca
precio_lista
estado
fecha_actualizacion
```

Usar `MERGE INTO` de Delta.

## 14. SCD Tipo 2

Implementar SCD Tipo 2 en:

```text
gld.dim_cliente
```

Clave natural:

```text
cliente_id
```

Columnas técnicas obligatorias:

```text
cliente_sk BIGINT
cliente_id BIGINT
fecha_inicio_vigencia DATE
fecha_fin_vigencia DATE
es_actual BOOLEAN
hash_diff STRING
fecha_creacion_registro TIMESTAMP
fecha_actualizacion_registro TIMESTAMP
```

Atributos versionables:

```text
nombres
apellidos
email
telefono
ciudad
departamento
pais
segmento
```

Reglas:

1. Si `cliente_id` no existe en la dimensión, insertar nuevo registro actual.
2. Si existe y el `hash_diff` no cambió, no hacer nada.
3. Si existe y el `hash_diff` cambió:
   - Cerrar registro actual con `fecha_fin_vigencia = fecha_actualizacion - 1 día`.
   - Marcar `es_actual = false`.
   - Insertar nueva versión con `es_actual = true`.
4. Usar una llave surrogate `cliente_sk`.
5. La tabla de hechos debe resolver el `cliente_sk` vigente a la fecha de la orden.

## 15. Fact table

Crear `gld.fact_ventas` con grano:

```text
Una fila por cada línea de detalle de orden completada.
```

Debe integrar:

```text
slv.pos_ordenes
slv.pos_detalle_ordenes
gld.dim_cliente
gld.dim_producto
gld.dim_tienda
gld.dim_vendedor
gld.dim_fecha
```

Filtrar solo órdenes `COMPLETADA`.

Columnas mínimas:

```text
venta_sk
orden_id
orden_detalle_id
fecha_sk
cliente_sk
producto_sk
tienda_sk
vendedor_sk
cantidad
precio_unitario
descuento_linea
impuesto_linea
venta_bruta
venta_neta
metodo_pago
moneda
fecha_carga
```

## 16. Reporting

Crear:

### `gld.rpt_ventas_mensual`

Agrupar por:

```text
anio
mes
nombre_mes
canal
```

Métricas:

```text
venta_neta
cantidad_vendida
cantidad_ordenes
ticket_promedio
```

### `gld.rpt_ventas_por_categoria`

Agrupar por:

```text
anio
mes
nombre_categoria
```

Métricas:

```text
venta_neta
cantidad_vendida
cantidad_productos_distintos
```

### `gld.rpt_top_clientes`

Agrupar por:

```text
cliente_id
nombres
apellidos
segmento
```

Métricas:

```text
venta_neta
cantidad_ordenes
ultima_fecha_compra
```

## 17. README

El README debe explicar:

1. Contexto del negocio.
2. Arquitectura Medallion.
3. Estructura del repositorio.
4. Cómo cargar CSV a S3.
5. Cómo configurar `lab_config.py`.
6. Orden de ejecución.
7. Qué se espera validar en Bronze, Silver y Gold.
8. Consultas SQL de ejemplo.
9. Resultado esperado para los alumnos.

## 18. Diccionario de datos

Generar `docs/diccionario_datos.md` con:

1. Diccionario de CSV fuente.
2. Diccionario de Bronze.
3. Diccionario de Silver.
4. Diccionario de Gold.
5. Descripción de métricas.

## 19. Pruebas

Crear pruebas simples en `tests/` para validar:

1. Conteo de filas mayor a cero en Bronze.
2. Conteo de filas mayor a cero en Silver.
3. Existencia de dimensiones Gold.
4. Existencia de `fact_ventas`.
5. No existencia de claves nulas en `fact_ventas`.
6. Que `dim_cliente` tenga al menos algunos clientes con más de una versión histórica.

## 20. Reglas de calidad de código

1. Usar PySpark y Spark SQL.
2. Evitar hardcodear rutas dentro de scripts; usar `lab_config.py`.
3. Comentar las secciones importantes.
4. Mantener scripts simples y didácticos.
5. No generar una solución excesivamente compleja.
6. Priorizar claridad para clase.
7. Usar Delta Lake para todas las tablas destino.
8. Usar `MERGE INTO` para SCD.

## 21. Salida esperada

Devuélveme el repositorio completo con todos los archivos `.py`, `README.md`, documentación y pruebas. El código debe estar listo para copiarse a Databricks Repos o ejecutarse como notebooks Python en Databricks.
