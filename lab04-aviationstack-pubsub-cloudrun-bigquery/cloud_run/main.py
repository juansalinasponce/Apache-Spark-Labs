"""Cloud Run function: Pub/Sub CloudEvent -> BigQuery."""

import base64
import json
import logging
import os
from datetime import datetime, timezone

import functions_framework
from google.cloud import bigquery


@functions_framework.cloud_event
def process_flight(cloud_event) -> None:
    """Decode one Pub/Sub message and insert it into BigQuery."""
    try:
        message = cloud_event.data["message"]
        event = json.loads(base64.b64decode(message["data"]).decode("utf-8"))
        event_id = event["event_id"]
    except (KeyError, TypeError, ValueError, json.JSONDecodeError):
        # Returning normally acknowledges a permanently malformed message.
        logging.exception("Mensaje Pub/Sub inválido; se descarta")
        return

    row = {
        **event,
        "ingested_at": datetime.now(timezone.utc).isoformat(),
        "pubsub_message_id": message.get("messageId"),
        "payload": event,
    }
    table_id = os.environ["BIGQUERY_TABLE_ID"]

    client = bigquery.Client()
    errors = client.insert_rows_json(
        table_id,
        [row],
        row_ids=[event_id],
        timeout=15,
    )
    if errors:
        # Raising lets Eventarc retry transient delivery failures.
        raise RuntimeError(f"BigQuery rechazó la fila: {errors}")

    logging.info("Insertado event_id=%s", event_id)
