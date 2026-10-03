"""Simple local producer: Aviationstack -> Google Cloud Pub/Sub."""

import argparse
import hashlib
import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
from dotenv import load_dotenv
from google.cloud import pubsub_v1


load_dotenv(Path(__file__).with_name(".env"))
AVIATIONSTACK_URL = "https://api.aviationstack.com/v1/flights"


def configuration() -> dict[str, object]:
    """Read the few settings needed by this producer."""
    api_key = os.getenv("AVIATIONSTACK_API_KEY", "").strip()
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT", "").strip()

    if not api_key or api_key.startswith("REEMPLAZAR_"):
        raise ValueError("Reemplaza AVIATIONSTACK_API_KEY en producer/.env")
    if not project_id or project_id.startswith("REEMPLAZAR_"):
        raise ValueError("Reemplaza GOOGLE_CLOUD_PROJECT en producer/.env")

    movement_type = os.getenv("MOVEMENT_TYPE", "ARRIVAL").strip().upper()
    if movement_type not in {"ARRIVAL", "DEPARTURE"}:
        raise ValueError("MOVEMENT_TYPE debe ser ARRIVAL o DEPARTURE")

    return {
        "api_key": api_key,
        "project_id": project_id,
        "topic_id": os.getenv("PUBSUB_TOPIC_ID", "aviationstack-flights").strip(),
        "airport_iata": os.getenv("AIRPORT_IATA", "LIM").strip().upper(),
        "movement_type": movement_type,
        "flight_status": os.getenv("FLIGHT_STATUS", "active").strip(),
        "limit": int(os.getenv("AVIATIONSTACK_LIMIT", "5")),
        "only_live": os.getenv("ONLY_LIVE_FLIGHTS", "true").lower() == "true",
        "interval": int(os.getenv("PUBLISH_INTERVAL_SECONDS", "60")),
    }


def get_flights(config: dict[str, object]) -> list[dict]:
    """Request one page from Aviationstack without logging the secret URL."""
    airport_filter = (
        "arr_iata" if config["movement_type"] == "ARRIVAL" else "dep_iata"
    )
    params = {
        "access_key": config["api_key"],
        airport_filter: config["airport_iata"],
        "flight_status": config["flight_status"],
        "limit": config["limit"],
    }

    try:
        response = requests.get(AVIATIONSTACK_URL, params=params, timeout=20)
    except requests.RequestException:
        raise RuntimeError("No se pudo conectar con Aviationstack") from None

    if response.status_code != 200:
        raise RuntimeError(f"Aviationstack respondió HTTP {response.status_code}")

    payload = response.json()
    if payload.get("error"):
        error_type = payload["error"].get("type", "unknown_error")
        raise RuntimeError(f"Aviationstack respondió: {error_type}")

    flights = payload.get("data", [])
    if config["only_live"]:
        flights = [flight for flight in flights if flight.get("live")]
    return flights


def build_event(flight: dict, config: dict[str, object]) -> dict:
    """Flatten one Aviationstack response for Pub/Sub and BigQuery."""
    airline = flight.get("airline") or {}
    flight_info = flight.get("flight") or {}
    departure = flight.get("departure") or {}
    arrival = flight.get("arrival") or {}
    live = flight.get("live") or {}

    flight_iata = flight_info.get("iata") or flight_info.get("icao")
    if not flight_iata:
        raise ValueError("El vuelo no tiene identificador IATA/ICAO")

    fingerprint = json.dumps(
        {
            "airport_iata": config["airport_iata"],
            "movement_type": config["movement_type"],
            "flight": flight,
        },
        sort_keys=True,
        separators=(",", ":"),
    )

    return {
        "event_id": hashlib.sha256(fingerprint.encode()).hexdigest(),
        "collected_at": datetime.now(timezone.utc).isoformat(),
        "airport_iata": config["airport_iata"],
        "movement_type": config["movement_type"],
        "flight_date": flight.get("flight_date"),
        "flight_status": flight.get("flight_status"),
        "flight_iata": flight_iata,
        "airline_name": airline.get("name"),
        "departure_airport": departure.get("airport"),
        "departure_iata": departure.get("iata"),
        "arrival_airport": arrival.get("airport"),
        "arrival_iata": arrival.get("iata"),
        "latitude": live.get("latitude"),
        "longitude": live.get("longitude"),
        "altitude_meters": live.get("altitude"),
        "speed_kmh": live.get("speed_horizontal"),
        "position_updated_at": live.get("updated"),
    }


def publish_once(
    config: dict[str, object],
    publisher: pubsub_v1.PublisherClient,
    topic_path: str,
) -> int:
    flights = get_flights(config)
    published = 0

    for flight in flights:
        try:
            event = build_event(flight, config)
        except ValueError as error:
            print(f"Omitido: {error}")
            continue

        data = json.dumps(event, ensure_ascii=False).encode("utf-8")
        message_id = publisher.publish(topic_path, data).result(timeout=30)
        published += 1
        print(f"Publicado vuelo={event['flight_iata']} message_id={message_id}")

    print(f"Total publicado: {published}")
    return published


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--continuous",
        action="store_true",
        help="Consulta y publica continuamente hasta presionar Ctrl+C.",
    )
    args = parser.parse_args()

    config = configuration()
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(config["project_id"], config["topic_id"])

    try:
        while True:
            publish_once(config, publisher, topic_path)
            if not args.continuous:
                break
            time.sleep(config["interval"])
    except KeyboardInterrupt:
        print("Producer detenido")
    finally:
        publisher.stop()


if __name__ == "__main__":
    main()

