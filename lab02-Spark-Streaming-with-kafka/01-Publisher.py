import json
import os
import uuid
import random
import socket
import time
from datetime import datetime, timezone
from kafka import KafkaProducer
from kafka.errors import KafkaError
from dotenv import load_dotenv


load_dotenv()

# =========================
# Configuración Redpanda / Kafka
# =========================

BOOTSTRAP_SERVERS = os.environ["REDPANDA_BOOTSTRAP_SERVERS"]
TOPIC_NAME = os.getenv("REDPANDA_TOPIC", "operaciones")

SASL_MECHANISM = os.getenv("REDPANDA_SASL_MECHANISM", "SCRAM-SHA-256")
USERNAME = os.environ["REDPANDA_USERNAME"]
PASSWORD = os.environ["REDPANDA_PASSWORD"]

# =========================
# Kafka Producer
# =========================

producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP_SERVERS,
    security_protocol="SASL_SSL",
    sasl_mechanism=SASL_MECHANISM,
    sasl_plain_username=USERNAME,
    sasl_plain_password=PASSWORD,
    key_serializer=lambda k: k.encode("utf-8"),
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    retries=5,
    linger_ms=100
)

hostname = socket.gethostname()

def on_success(metadata):
    print(
        f"Enviado correctamente | "
        f"topic={metadata.topic}, partition={metadata.partition}, offset={metadata.offset}"
    )

def on_error(error):
    print(f"Error enviando mensaje: {error}")

# =========================
# Generador de operaciones bancarias simuladas
# =========================

def generar_operacion():
    tipo_operacion = random.choice([
        "TRANSFERENCIA",
        "PAGO_TARJETA",
        "RETIRO_ATM",
        "DEPOSITO",
        "PAGO_SERVICIO"
    ])

    canal = random.choice([
        "APP_MOVIL",
        "WEB_BANKING",
        "ATM",
        "AGENCIA",
        "POS"
    ])

    moneda = random.choice(["PEN", "USD"])

    monto = round(random.uniform(20, 5000), 2)

    estado = random.choices(
        ["APROBADA", "RECHAZADA", "OBSERVADA"],
        weights=[85, 10, 5],
        k=1
    )[0]

    operacion = {
        "operation_id": str(uuid.uuid4()),
        "customer_id": f"CLI-{random.randint(100000, 999999)}",
        "account_id": f"CTA-{random.randint(10000000, 99999999)}",
        "operation_type": tipo_operacion,
        "channel": canal,
        "currency": moneda,
        "amount": monto,
        "status": estado,
        "origin_bank": "BANCO_DEMO",
        "destination_bank": random.choice(["BANCO_DEMO", "BANCO_EXTERNO_1", "BANCO_EXTERNO_2"]),
        "merchant_category": random.choice([
            "RETAIL",
            "SERVICIOS",
            "RESTAURANTE",
            "TRANSPORTE",
            "EDUCACION",
            "NO_APLICA"
        ]),
        "risk_score": round(random.uniform(0, 1), 4),
        "event_ts": datetime.now(timezone.utc).isoformat()
    }

    return operacion

# =========================
# Envío continuo de mensajes
# =========================

for i in range(100):
    operacion = generar_operacion()

    future = producer.send(
        TOPIC_NAME,
        key=operacion["operation_id"],
        value=operacion
    )

    future.add_callback(on_success)
    future.add_errback(on_error)

    print(f"Publicando operación #{i + 1}")
    print(json.dumps(operacion, indent=2))

    time.sleep(1)

producer.flush()
producer.close()

print("Publicación finalizada.")
