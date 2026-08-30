# Databricks — Lab 03

Este paso configura nombres y credenciales de forma separada. No crea tablas,
catálogos ni conexiones de streaming.

## 1. Importar el notebook

Importa `00_config.py` en tu workspace de Databricks y ejecútalo con compute
serverless.

Las capturas de Free Edition confirman que `workspace` es el catálogo
predeterminado y escribible. `samples` contiene ejemplos y `system` contiene
objetos internos de observabilidad; no escribiremos en ellos.

Las capas serán schemas:

```text
workspace.bronze
workspace.silver
workspace.gold
workspace.operations
```

La primera tabla será externa y sus datos vivirán en S3:

```text
workspace.bronze.aviationstack_flights
s3://atokongo-labs/lab03-spark-streaming-redpanda-and-spark/
  bronze/aviationstack/flights
```

El checkpoint de la primera consulta será:

```text
s3://atokongo-labs/lab03-spark-streaming-redpanda-and-spark/
  operations/checkpoints/redpanda-to-bronze-aviationstack-flights
```

No se crea ningún Volume. Antes de ejecutar `01_setup_bronze.py`, la ruta
`s3://atokongo-labs/` debe estar registrada y validada como External Location
en Unity Catalog.

## 2. Taxonomía de almacenamiento

Cada capa responde a una pregunta diferente:

```text
bronze/<fuente>/<objeto-de-origen>
silver/<dominio>/<entidad>/<dataset>
gold/<dominio>/<producto-de-datos>/<dataset>
operations/checkpoints/<pipeline>
```

Los nombres de tablas siguen una taxonomía complementaria:

```text
bronze.<fuente>_<objeto>
silver.<entidad>_<propósito>
gold.<producto_de_datos>_<dataset>
```

Para este laboratorio se usarán:

```text
workspace.bronze.aviationstack_flights
workspace.silver.flight_status_history
workspace.silver.current_flight_status
workspace.gold.peru_flight_tracking_current_status
workspace.gold.peru_flight_tracking_airport_movements
```

Silver no incluye `aviationstack` en el nombre porque representa el modelo
conformado del dominio y podrá integrar otras fuentes sin renombrar sus tablas.
Redpanda tampoco forma parte del nombre lógico: es el canal técnico de
ingestión y queda registrado en metadatos y columnas técnicas.

Aplicada al laboratorio:

```text
lab03-spark-streaming-redpanda-and-spark/
├── bronze/
│   └── aviationstack/flights/
├── silver/
│   └── flight-operations/flights/
│       ├── flight-status-history/
│       └── flight-status-current/
├── gold/
│   └── flight-operations/peru-flight-tracking/
│       ├── current-flight-status/
│       └── airport-movements/
└── operations/
    └── checkpoints/
        ├── redpanda-to-bronze-aviationstack-flights/
        └── bronze-to-silver-flights/
```

Importa los notebooks en la misma carpeta y ejecuta los DDL en orden:

```text
00_config.py
01_setup_bronze.py
02_setup_silver.py
03_setup_gold.py
```

Las tablas se crean vacías. Los notebooks de transformación posteriores serán
los responsables de poblar Silver desde Bronze y Gold desde Silver.

## 3. Responsabilidad de las tablas

| Tabla | Responsabilidad |
|---|---|
| `bronze.aviationstack_flights` | Conservar cada mensaje original y sus metadatos Kafka. |
| `silver.flight_status_history` | Mantener cada observación válida del vuelo a través del tiempo. |
| `silver.current_flight_status` | Conservar únicamente el último estado conocido por vuelo programado. |
| `gold.peru_flight_tracking_current_status` | Entregar a Power BI el seguimiento actual de vuelos peruanos. |
| `gold.peru_flight_tracking_airport_movements` | Entregar indicadores horarios de llegadas, salidas, retrasos y cancelaciones. |

La tabla `current_flight_status` será actualizada con `MERGE` usando
`flight_instance_id`; así Power BI obtiene el último estado sin perder el
histórico almacenado en `flight_status_history`.

## 4. Procesos de poblamiento

Los procesos se ejecutan en este orden:

```text
Producer Python
    ↓
Redpanda: viation-peru
    ↓ 04_redpanda_to_bronze.py
workspace.bronze.aviationstack_flights
    ↓ 05_bronze_to_silver.py
workspace.silver.flight_status_history
workspace.silver.current_flight_status
    ↓ 06_silver_to_gold.py
workspace.gold.peru_flight_tracking_current_status
workspace.gold.peru_flight_tracking_airport_movements
```

`04_redpanda_to_bronze.py` y `05_bronze_to_silver.py` utilizan Structured
Streaming con `AvailableNow`: procesan todo lo pendiente, conservan el avance
en sus checkpoints de S3 y terminan. `06_silver_to_gold.py` es un proceso
incremental batch que usa `MERGE` para actualizar el producto de datos.

Para una ejecución completa importa y ejecuta:

```text
00_config.py
01_setup_bronze.py
02_setup_silver.py
03_setup_gold.py
04_redpanda_to_bronze.py
05_bronze_to_silver.py
06_silver_to_gold.py
```

En ejecuciones posteriores no necesitas repetir los DDL `01`, `02` y `03`.
Ejecuta nuevamente `04`, `05` y `06` después de que el producer publique datos.

Comprueba el resultado con:

```sql
SELECT COUNT(*) FROM workspace.bronze.aviationstack_flights;
SELECT COUNT(*) FROM workspace.silver.flight_status_history;
SELECT COUNT(*) FROM workspace.silver.current_flight_status;
SELECT * FROM workspace.gold.peru_flight_tracking_current_status;
SELECT * FROM workspace.gold.peru_flight_tracking_airport_movements;
```

## 5. Configurar Redpanda

En el widget `redpanda_bootstrap_servers`, coloca el hostname y puerto del
cluster Redpanda. Este dato no es una contraseña.

El tópico ya está configurado como:

```text
viation-peru
```

Para Databricks utiliza un usuario Redpanda de lectura diferente al usuario del
producer cuando sea posible.

## 6. Crear el Secret Scope

Crea un scope llamado:

```text
redpanda-viation-peru
```

Dentro del scope crea dos claves:

```text
username
password
```

No copies esos valores dentro del notebook. Más adelante Spark los leerá con:

```python
username = dbutils.secrets.get("redpanda-viation-peru", "username")
password = dbutils.secrets.get("redpanda-viation-peru", "password")
```

Para abrir la pantalla de creación del scope utiliza:

```text
https://<tu-workspace-databricks>#secrets/createScope
```

## Resultado esperado de `00_config.py`

Al ejecutar `00_config.py` solo deben aparecer nombres no secretos:

```text
Topic: viation-peru
Bronze: workspace.bronze
Silver: workspace.silver
Gold: workspace.gold
Operations: workspace.operations
Secret scope: redpanda-viation-peru
S3 lab root: s3://atokongo-labs/lab03-spark-streaming-redpanda-and-spark
Bronze data: s3://atokongo-labs/lab03-spark-streaming-redpanda-and-spark/bronze/aviationstack/flights
Bronze checkpoint: s3://atokongo-labs/lab03-spark-streaming-redpanda-and-spark/operations/checkpoints/redpanda-to-bronze-aviationstack-flights
```
