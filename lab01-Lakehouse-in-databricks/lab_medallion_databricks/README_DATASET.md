# Dataset fuente para laboratorio Medallion Databricks

Este paquete contiene datos sintéticos de 2 años, desde 2024-01-01 hasta 2025-12-31, para un caso de ventas de cursos, diplomados, especializaciones y bootcamps de Data & Analytics.

## Fuentes simuladas

- `crm/clientes_cdc.csv`: cambios de clientes para demostrar SCD Tipo 2.
- `erp/categorias.csv`: catálogo de categorías.
- `erp/productos_cdc.csv`: cambios de productos/precios para demostrar SCD Tipo 1.
- `pos/tiendas.csv`: puntos de venta y canales.
- `pos/vendedores.csv`: vendedores asociados a tiendas.
- `pos/ordenes.csv`: cabeceras de órdenes.
- `pos/detalle_ordenes.csv`: líneas de órdenes.

## Ruta sugerida para carga manual en S3

```text
s3://<bucket>/lakehouse/landing/crm/clientes/clientes_cdc.csv
s3://<bucket>/lakehouse/landing/erp/categorias/categorias.csv
s3://<bucket>/lakehouse/landing/erp/productos/productos_cdc.csv
s3://<bucket>/lakehouse/landing/pos/tiendas/tiendas.csv
s3://<bucket>/lakehouse/landing/pos/vendedores/vendedores.csv
s3://<bucket>/lakehouse/landing/pos/ordenes/ordenes.csv
s3://<bucket>/lakehouse/landing/pos/detalle_ordenes/detalle_ordenes.csv
```
