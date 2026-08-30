# Databricks — Lab 03

Pipeline de datos para procesar observaciones de Aviationstack publicadas en
Redpanda mediante una arquitectura Medallion en Databricks.

## 1. Namespace de Unity Catalog

El laboratorio combina la capa Medallion y el entorno en el catálogo. El
schema representa la fuente en Bronze, el dominio en Silver y el producto de
datos en Gold:

```text
catalog.schema.table

bronze_dev.aviationstack.flights
silver_dev.aviation.flight_status_history
silver_dev.aviation.current_flight_status
gold_dev.peru_flight_tracking.current_status
gold_dev.peru_flight_tracking.airport_movements
```

Esta estructura evita repetir la fuente o el producto en el nombre de la
tabla. Redpanda tampoco forma parte del nombre lógico porque es el canal
técnico de ingestión.

El widget `environment` de `00_config.py` acepta:

```text
dev
stg
prd
```

Por ejemplo, al seleccionar `prd`, los catálogos serán `bronze_prd`,
`silver_prd` y `gold_prd` sin cambiar el resto de los notebooks.

## 2. Almacenamiento externo en S3

Todas las tablas son Delta externas. Antes de ejecutar los DDL, la ruta
`s3://atokongo-labs/` debe estar registrada y validada como External Location
en Unity Catalog.

No se crea ningún Volume. Para desarrollo se usa esta taxonomía física:

```text
s3://atokongo-labs/lab03-spark-streaming-redpanda-and-spark/dev/
├── bronze/
│   └── aviationstack/flights/
├── silver/
│   └── aviation/flights/
│       ├── flight-status-history/
│       └── current-flight-status/
├── gold/
│   └── aviation/peru-flight-tracking/
│       ├── current-status/
│       └── airport-movements/
└── operations/
    └── checkpoints/
        ├── redpanda-to-bronze-aviationstack-flights/
        └── bronze-to-silver-flights/
```

Los checkpoints son estado técnico de Structured Streaming y no se registran
como tablas, schemas ni catálogos.

## 3. Responsabilidad de las tablas

| Tabla | Responsabilidad |
|---|---|
| `bronze_dev.aviationstack.flights` | Conservar cada mensaje original junto con sus metadatos Kafka. |
| `silver_dev.aviation.flight_status_history` | Mantener cada observación válida del vuelo a través del tiempo. |
| `silver_dev.aviation.current_flight_status` | Conservar solamente el último estado conocido de cada vuelo programado. |
| `gold_dev.peru_flight_tracking.current_status` | Entregar a Power BI el seguimiento actual de los vuelos peruanos. |
| `gold_dev.peru_flight_tracking.airport_movements` | Entregar indicadores horarios de llegadas, salidas, retrasos y cancelaciones. |

`current_flight_status` se actualiza con `MERGE` usando
`flight_instance_id`. De esa manera Power BI consulta el último estado sin
perder el histórico almacenado en `flight_status_history`.

## 4. Orden de ejecución

Los notebooks deben permanecer juntos porque utilizan `%run ./00_config`.
Ejecuta por primera vez:

```text
00_config.py
01_setup_bronze.py
02_setup_silver.py
03_setup_gold.py
04_redpanda_to_bronze.py
05_bronze_to_silver.py
06_silver_to_gold.py
```

El flujo resultante es:

```text
Producer Python
    ↓
Redpanda: viation-peru
    ↓ 04_redpanda_to_bronze.py
bronze_dev.aviationstack.flights
    ↓ 05_bronze_to_silver.py
silver_dev.aviation.flight_status_history
silver_dev.aviation.current_flight_status
    ↓ 06_silver_to_gold.py
gold_dev.peru_flight_tracking.current_status
gold_dev.peru_flight_tracking.airport_movements
```

`04_redpanda_to_bronze.py` y `05_bronze_to_silver.py` usan Structured
Streaming con `AvailableNow`: procesan los mensajes pendientes, guardan el
avance en S3 y terminan. `06_silver_to_gold.py` usa `MERGE` para actualizar el
producto de datos.

En ejecuciones posteriores no es necesario repetir los DDL `01`, `02` y `03`.
Después de que el producer publique datos, ejecuta nuevamente `04`, `05` y
`06`.

## 5. Configuración de `00_config.py`

Configura estos widgets antes de ejecutar los procesos:

| Widget | Desarrollo |
|---|---|
| `environment` | `dev` |
| `s3_bucket` | `atokongo-labs` |
| `s3_lab_prefix` | `lab03-spark-streaming-redpanda-and-spark` |
| `redpanda_bootstrap_servers` | Host y puerto del cluster Redpanda |
| `redpanda_topic` | `viation-peru` |
| `redpanda_secret_scope` | `redpanda-viation-peru` |

El hostname de Redpanda no es una contraseña. Para Databricks utiliza un
usuario de lectura distinto al usuario del producer cuando sea posible.

## 6. Credenciales de Redpanda

Crea el Secret Scope:

```text
redpanda-viation-peru
```

Y agrega las claves:

```text
username
password
```

No copies los valores dentro de los notebooks. Para abrir la pantalla de
creación del scope utiliza:

```text
https://<tu-workspace-databricks>#secrets/createScope
```

## 7. Validación

Al ejecutar `00_config.py` deben aparecer nombres no secretos como:

```text
Environment: dev
Bronze: bronze_dev.aviationstack
Silver: silver_dev.aviation
Gold: gold_dev.peru_flight_tracking
S3 environment root: s3://atokongo-labs/lab03-spark-streaming-redpanda-and-spark/dev
```

Después de ejecutar el pipeline comprueba:

```sql
SELECT COUNT(*) FROM bronze_dev.aviationstack.flights;
SELECT COUNT(*) FROM silver_dev.aviation.flight_status_history;
SELECT COUNT(*) FROM silver_dev.aviation.current_flight_status;
SELECT * FROM gold_dev.peru_flight_tracking.current_status;
SELECT * FROM gold_dev.peru_flight_tracking.airport_movements;
```

Los objetos anteriores de `lakehouse.brz`, `lakehouse.slv` o `lakehouse.gld`
no se eliminan automáticamente. Primero valida los catálogos nuevos y elimina
los anteriores solamente cuando confirmes que ya no contienen datos útiles.
