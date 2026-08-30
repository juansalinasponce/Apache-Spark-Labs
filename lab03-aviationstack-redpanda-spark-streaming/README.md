# Lab 03 — Peru Flight Producer

Construcción incremental de un producer Python que consultará Aviationstack y
publicará observaciones de vuelos en Redpanda.

## Alcance

El laboratorio procesará vuelos cuya salida o llegada corresponda a uno de los
aeropuertos peruanos configurados.

## Avance

- [x] Paso 1: estructura, `.env` y validación de configuración.
- [x] Paso 2: cliente Aviationstack y visualización de una respuesta.
- [x] Paso 3: contrato y normalización del evento.
- [x] Paso 4: publicación inicial en Redpanda.
- [ ] Paso 5: pruebas integrales y control de cuota.

Consulta [producer/README.md](producer/README.md) para revisar el primer paso.

## Databricks

- [x] Paso 1: configuración no secreta y diseño del namespace.
- [x] Paso 2: taxonomía S3 y DDL externo inicial de Bronze.
- [x] Paso 3: DDL externo de Silver.
- [x] Paso 4: DDL externo del producto de datos Gold.
- [x] Paso 5: conexión e ingestión incremental Redpanda hacia Bronze.
- [x] Paso 6: normalización y actualización de Silver.
- [x] Paso 7: producto de datos e indicadores Gold.

Consulta [databricks/README.md](databricks/README.md) antes de importar el primer
notebook.
