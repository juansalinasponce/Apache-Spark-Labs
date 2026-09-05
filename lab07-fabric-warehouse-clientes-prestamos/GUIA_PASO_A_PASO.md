# Guía paso a paso

## Paso 01 — Validar el origen MySQL

Abre tu cliente MySQL y ejecuta:

[`sql/mysql/01_validar_origen.sql`](sql/mysql/01_validar_origen.sql)

Debes confirmar que existen `banco_cliente`, `banco_prestamo` y la relación
`id_cliente`. El nombre real de la tabla es singular: `banco_prestamo`.

## Paso 02 — Crear o seleccionar el workspace

En Microsoft Fabric:

1. Abre el workspace donde desarrollarás el laboratorio.
2. Si necesitas uno nuevo, créalo como `wk_banca_dev`.
3. Todos los elementos siguientes deben quedar en ese mismo workspace.

## Paso 03 — Crear el Warehouse

1. Selecciona **Nuevo elemento**.
2. Busca **Warehouse**.
3. Nómbralo `wh_banca_dev_comercial`.
4. No uses Warehouse de ejemplo.

## Paso 04 — Crear schemas y tablas

Abre el Warehouse, selecciona **Nueva consulta SQL** y ejecuta una sola vez, en
este orden:

1. [`01_crear_schemas.sql`](sql/fabric/01_crear_schemas.sql)
2. [`02_crear_tablas_bronze.sql`](sql/fabric/02_crear_tablas_bronze.sql)
3. [`03_crear_tablas_silver.sql`](sql/fabric/03_crear_tablas_silver.sql)
4. [`04_crear_tablas_gold.sql`](sql/fabric/04_crear_tablas_gold.sql)

Al terminar, el Warehouse tendrá tres schemas y seis tablas.

## Paso 05 — Crear la conexión MySQL

1. En Fabric, abre **Administrar conexiones y puertas de enlace**.
2. Crea una conexión de tipo **MySQL database**.
3. Usa el servidor, puerto, base, usuario y contraseña del archivo protegido del
   Lab 05. No copies las credenciales dentro de este repositorio.
4. Selecciona autenticación **Basic**.
5. Si el servidor es accesible desde internet, prueba primero sin gateway. Si la
   red lo bloquea, utiliza un gateway.

## Paso 06 — Crear el pipeline

1. En el mismo workspace crea un **Data pipeline**.
2. Nómbralo `pl_banca_dev_clientes_prestamos`.
3. Agrega las cinco actividades descritas en
   [`pipeline/CONFIGURACION_COPY_DATA.md`](pipeline/CONFIGURACION_COPY_DATA.md).

## Paso 07 — Copiar `banco_cliente`

Configura `act_02_copiar_cliente`:

- actividad: **Copy Data**;
- origen: conexión MySQL;
- modo: **Table**;
- tabla: `banco_cliente`;
- destino: conexión al Warehouse;
- tabla: `brz.banco_cliente`;
- mapping: selecciona **Import schemas** y verifica correspondencia por nombre.

No escribas una consulta ni hagas joins.

## Paso 08 — Copiar `banco_prestamo`

Configura `act_03_copiar_prestamo`:

- actividad: **Copy Data**;
- origen: conexión MySQL;
- modo: **Table**;
- tabla: `banco_prestamo`;
- destino: conexión al Warehouse;
- tabla: `brz.banco_prestamo`;
- mapping: selecciona **Import schemas**.

## Paso 09 — Transformar Bronze, Silver y Gold

Configura las actividades Script del pipeline:

- `act_01_limpiar_bronze`: usa `05_limpiar_bronze.sql`;
- `act_04_cargar_silver`: usa `06_cargar_silver.sql`;
- `act_05_cargar_gold`: usa `07_cargar_gold.sql`.

Las dos copias deben empezar después de limpiar Bronze. La carga de Silver debe
esperar a que ambas copias terminen; Gold debe esperar a Silver.

## Paso 10 — Ejecutar y validar

1. Selecciona **Run** en el pipeline.
2. Comprueba que las cinco actividades aparezcan en verde.
3. Abre el Warehouse y ejecuta
   [`08_validar_capas.sql`](sql/fabric/08_validar_capas.sql).
4. Bronze, Silver y Gold deben tener conteos equivalentes.
5. La consulta de huérfanos debe devolver `0`.

## Paso 11 — Crear el modelo semántico

Desde el Warehouse selecciona **New semantic model** y usa el nombre:

```text
sm_banca_dev_clientes_prestamos
```

Selecciona únicamente:

```text
gld.dim_cliente
gld.fct_prestamo
```

Configura la relación y las medidas siguiendo
[`powerbi/01_MODELO_SEMANTICO.md`](powerbi/01_MODELO_SEMANTICO.md).

## Paso 12 — Crear el dashboard básico

Desde el modelo semántico selecciona **New report**, crea los visuales descritos
en [`powerbi/03_DASHBOARD_BASICO.md`](powerbi/03_DASHBOARD_BASICO.md) y guárdalo
como:

```text
rpt_banca_dev_clientes_prestamos
```

Con esto termina el flujo MySQL → Bronze → Silver → Gold → modelo semántico →
reporte Power BI.
