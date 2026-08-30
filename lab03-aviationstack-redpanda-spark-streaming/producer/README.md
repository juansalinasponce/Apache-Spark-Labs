# Paso 1 — Configuración del producer

Este paso no llama a ninguna API y no se conecta con Redpanda. Solo define y
valida la configuración que usarán los siguientes pasos.

## Preparación

```bash
cd lab03-aviationstack-redpanda-spark-streaming/producer
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Completa `.env` con credenciales nuevas. El archivo está excluido por Git.

## Decisiones para revisar

- `PERU_AIRPORT_IATA_CODES=LIM,CUZ,AQP` inicia con tres aeropuertos.
- Se consultarán salidas y llegadas, por lo que una vuelta consumirá seis
  solicitudes.
- `AVIATIONSTACK_MAX_REQUESTS=12` permite dos vueltas en una demostración.
- El tópico configurado es `viation-peru`.
- `load_aviationstack_config()` devuelve un diccionario con la configuración de
  la API.
- `load_redpanda_config()` devuelve otro diccionario y se usará más adelante.

Ejemplo:

```python
from config import load_aviationstack_config

config = load_aviationstack_config()
print(config["airport_codes"])
```

La API key solo se utiliza en el producer. Databricks tendrá posteriormente su
propia configuración y Secret Scope para conectarse con Redpanda.

## Paso 2 — Consulta de prueba

`aviationstack_client.py` hace una sola solicitud para las salidas del primer
aeropuerto de `PERU_AIRPORT_IATA_CODES`. Con la configuración inicial consulta
`LIM` y muestra como máximo cinco filas.

```bash
python aviationstack_client.py
```

Salida esperada:

```text
Querying departure flights for LIM...
Flights returned: 8
Showing at most 5 flights:

LA2213: LIM -> CUZ | status=active
```

La prueba consume una solicitud de la cuota de Aviationstack. Todavía no hay
bucle de polling ni conexión con Redpanda.

## Pasos 3 y 4 — Evento y publicación

`flight_event.py` convierte la respuesta de Aviationstack en un evento estable
con `event_id`, versión, alcance aeroportuario, vuelo, salida, llegada y
posición. Una captura idéntica genera el mismo `event_id`.

Completa primero estas variables en `.env`:

```env
REDPANDA_BOOTSTRAP_SERVERS=...
REDPANDA_USERNAME=...
REDPANDA_PASSWORD=...
```

Crea el tópico una sola vez:

```bash
python create_topic.py
```

Después publica una muestra:

```bash
python redpanda_publisher.py
```

La ejecución realiza una consulta de salidas del primer aeropuerto configurado
y publica como máximo `REDPANDA_MAX_MESSAGES=5`. Cada envío espera la
confirmación de Redpanda y muestra únicamente vuelo, partición y offset.
