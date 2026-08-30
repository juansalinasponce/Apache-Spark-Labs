## data/source/crm/clientes_cdc.csv

Filas: 104

Columnas:

- `cliente_id`
- `nombres`
- `apellidos`
- `email`
- `telefono`
- `ciudad`
- `departamento`
- `pais`
- `segmento`
- `fecha_actualizacion`
- `operacion`


## data/source/erp/categorias.csv

Filas: 4

Columnas:

- `categoria_id`
- `nombre_categoria`
- `estado`
- `fecha_creacion`
- `fecha_actualizacion`


## data/source/erp/productos_cdc.csv

Filas: 17

Columnas:

- `producto_id`
- `categoria_id`
- `sku`
- `nombre_producto`
- `marca`
- `precio_lista`
- `estado`
- `fecha_actualizacion`
- `operacion`


## data/source/pos/detalle_ordenes.csv

Filas: 1322

Columnas:

- `orden_detalle_id`
- `orden_id`
- `producto_id`
- `cantidad`
- `precio_unitario`
- `descuento_linea`
- `impuesto_linea`
- `total_linea`


## data/source/pos/ordenes.csv

Filas: 900

Columnas:

- `orden_id`
- `cliente_id`
- `tienda_id`
- `vendedor_id`
- `fecha_orden`
- `estado_orden`
- `metodo_pago`
- `moneda`
- `total_bruto`
- `descuento_total`
- `impuesto_total`
- `total_neto`


## data/source/pos/tiendas.csv

Filas: 5

Columnas:

- `tienda_id`
- `nombre_tienda`
- `canal`
- `ciudad`
- `region`
- `estado`
- `fecha_creacion`


## data/source/pos/vendedores.csv

Filas: 12

Columnas:

- `vendedor_id`
- `tienda_id`
- `nombre_vendedor`
- `estado`
- `fecha_ingreso`

