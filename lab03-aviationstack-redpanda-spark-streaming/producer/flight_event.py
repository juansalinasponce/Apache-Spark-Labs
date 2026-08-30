"""Convert one Aviationstack flight into the event sent to Redpanda."""

import hashlib
import json
from datetime import datetime, timezone


def build_flight_event(flight_data, airport_code, movement_type):
    airline = flight_data.get("airline") or {}
    flight = flight_data.get("flight") or {}
    aircraft = flight_data.get("aircraft") or {}
    departure = flight_data.get("departure") or {}
    arrival = flight_data.get("arrival") or {}
    live = flight_data.get("live") or {}

    flight_key = (
        flight.get("iata")
        or flight.get("icao")
        or aircraft.get("registration")
        or aircraft.get("icao24")
    )
    if not flight_key:
        raise ValueError("The flight has no usable identity")

    # collected_at is not part of the fingerprint. Repeated identical snapshots
    # therefore produce the same event_id.
    fingerprint = json.dumps(
        flight_data, sort_keys=True, separators=(",", ":"), default=str
    )
    event_id = hashlib.sha256(fingerprint.encode("utf-8")).hexdigest()

    return {
        "event_id": event_id,
        "schema_version": 1,
        "event_type": "flight_observed",
        "collected_at": datetime.now(timezone.utc).isoformat(),
        "source": "aviationstack",
        "airport_scope": {
            "airport_iata": airport_code,
            "movement_type": movement_type,
        },
        "flight_date": flight_data.get("flight_date"),
        "flight_status": flight_data.get("flight_status"),
        "airline": {
            "name": airline.get("name"),
            "iata": airline.get("iata"),
            "icao": airline.get("icao"),
        },
        "flight": {
            "key": flight_key,
            "number": flight.get("number"),
            "iata": flight.get("iata"),
            "icao": flight.get("icao"),
        },
        "aircraft": {
            "registration": aircraft.get("registration"),
            "iata": aircraft.get("iata"),
            "icao": aircraft.get("icao"),
            "icao24": aircraft.get("icao24"),
        },
        "departure": {
            "airport": departure.get("airport"),
            "iata": departure.get("iata"),
            "timezone": departure.get("timezone"),
            "terminal": departure.get("terminal"),
            "gate": departure.get("gate"),
            "delay_minutes": departure.get("delay"),
            "scheduled_at": departure.get("scheduled"),
            "estimated_at": departure.get("estimated"),
            "actual_at": departure.get("actual"),
        },
        "arrival": {
            "airport": arrival.get("airport"),
            "iata": arrival.get("iata"),
            "timezone": arrival.get("timezone"),
            "terminal": arrival.get("terminal"),
            "gate": arrival.get("gate"),
            "baggage": arrival.get("baggage"),
            "delay_minutes": arrival.get("delay"),
            "scheduled_at": arrival.get("scheduled"),
            "estimated_at": arrival.get("estimated"),
            "actual_at": arrival.get("actual"),
        },
        "position": {
            "updated_at": live.get("updated"),
            "latitude": live.get("latitude"),
            "longitude": live.get("longitude"),
            "altitude_meters": live.get("altitude"),
            "direction_degrees": live.get("direction"),
            "horizontal_speed_kmh": live.get("speed_horizontal"),
            "vertical_speed_kmh": live.get("speed_vertical"),
            "is_ground": live.get("is_ground"),
        },
    }


def event_key(event):
    return str(event["flight"]["key"])
