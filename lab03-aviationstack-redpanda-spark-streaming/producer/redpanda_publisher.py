"""Fetch one flight page and publish a small sample to Redpanda."""

import json

from kafka import KafkaProducer

from aviationstack_client import fetch_flights
from config import load_aviationstack_config, load_redpanda_config
from flight_event import build_flight_event, event_key


def create_producer(config):
    return KafkaProducer(
        bootstrap_servers=config["bootstrap_servers"],
        security_protocol=config["security_protocol"],
        sasl_mechanism=config["sasl_mechanism"],
        sasl_plain_username=config["username"],
        sasl_plain_password=config["password"],
        client_id="peru-flight-producer",
        key_serializer=lambda value: value.encode("utf-8"),
        value_serializer=lambda value: json.dumps(
            value, ensure_ascii=False, separators=(",", ":")
        ).encode("utf-8"),
        acks="all",
        retries=5,
        compression_type="gzip",
    )


def main():
    aviation_config = load_aviationstack_config()
    redpanda_config = load_redpanda_config()

    airport_code = aviation_config["airport_codes"][0]
    movement_type = "DEPARTURE"

    print(f"Fetching {movement_type.lower()} flights for {airport_code}...")
    flights = fetch_flights(aviation_config, airport_code, movement_type)
    flights = flights[: redpanda_config["max_messages"]]

    producer = create_producer(redpanda_config)
    published = 0

    try:
        for flight_data in flights:
            try:
                event = build_flight_event(
                    flight_data, airport_code, movement_type
                )
            except ValueError as error:
                print(f"Skipped flight: {error}")
                continue

            metadata = producer.send(
                redpanda_config["topic"],
                key=event_key(event),
                value=event,
            ).get(timeout=30)

            published += 1
            print(
                f"Published flight={event['flight']['key']} "
                f"partition={metadata.partition} offset={metadata.offset}"
            )
    finally:
        producer.flush(timeout=30)
        producer.close(timeout=30)

    print(f"Published events: {published}")


if __name__ == "__main__":
    main()
