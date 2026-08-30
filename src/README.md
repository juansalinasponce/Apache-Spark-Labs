# Laboratorio Databricks Free Edition + S3

Este `src` contiene notebooks Python para poblar las tres capas del laboratorio Medallion usando los CSV del `lab01-Lakehouse-in-databricks`.

## Enfoque

- S3 se usa como zona landing para los CSV.
- Bronze, Silver y Gold se escriben como tablas Delta administradas en Unity Catalog.
- El valor por defecto del catalogo es `workspace`, comun en Databricks Free Edition.
- Los scripts son idempotentes para clase: cada ejecucion reemplaza las tablas destino.

## Rutas esperadas en S3

Sube los archivos CSV a estas rutas:

```text
s3://<bucket>/lakehouse/landing/crm/clientes/clientes_cdc.csv
s3://<bucket>/lakehouse/landing/erp/categorias/categorias.csv
s3://<bucket>/lakehouse/landing/erp/productos/productos_cdc.csv
s3://<bucket>/lakehouse/landing/pos/tiendas/tiendas.csv
s3://<bucket>/lakehouse/landing/pos/vendedores/vendedores.csv
s3://<bucket>/lakehouse/landing/pos/ordenes/ordenes.csv
s3://<bucket>/lakehouse/landing/pos/detalle_ordenes/detalle_ordenes.csv
```

En Databricks Free Edition, configura el acceso a S3 desde Catalog Explorer como external location o con el mecanismo que tengas habilitado en tu workspace. Los notebooks leen desde `s3://...` y escriben tablas administradas para evitar depender de permisos de escritura en S3 durante el laboratorio.

## Orden de ejecucion

1. Importa la carpeta `src` como notebooks en Databricks.
2. Abre `99_run_all.py` y configura los widgets:
   - `catalog`: por defecto `workspace`.
   - `s3_bucket`: por ejemplo `s3://mi-bucket`.
   - `batch_id`: por ejemplo `manual_001`.
3. Ejecuta `99_run_all.py` para poblar todo el lakehouse, o ejecuta manualmente estos notebooks en orden:

```text
00_setup.py
01_bronze_load.py
02_silver_load.py
03_gold_load.py
```

Si ejecutas los notebooks manualmente por separado, configura los mismos valores de widgets en cada notebook o ejecutalos como un Workflow con parametros comunes.

## Tablas creadas

Bronze:

```text
brz.crm_clientes
brz.erp_categorias
brz.erp_productos
brz.pos_tiendas
brz.pos_vendedores
brz.pos_ordenes
brz.pos_detalle_ordenes
```

Silver:

```text
slv.crm_clientes
slv.erp_categorias
slv.erp_productos
slv.pos_tiendas
slv.pos_vendedores
slv.pos_ordenes
slv.pos_detalle_ordenes
```

Gold:

```text
gld.dim_cliente
gld.dim_producto
gld.dim_tienda
gld.dim_vendedor
gld.dim_fecha
gld.fact_ventas
gld.rpt_ventas_mensual
gld.rpt_ventas_por_categoria
gld.rpt_top_clientes
```

## Consultas rapidas

```sql
SELECT * FROM gld.rpt_ventas_mensual ORDER BY anio, mes;
SELECT * FROM gld.rpt_ventas_por_categoria;
SELECT * FROM gld.rpt_top_clientes LIMIT 20;
```
