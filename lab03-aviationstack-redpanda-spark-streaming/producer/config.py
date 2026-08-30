"""Load the producer configuration from producer/.env."""

import os
from pathlib import Path

from dotenv import load_dotenv


ENV_FILE = Path(__file__).with_name(".env")


def load_aviationstack_config():
    """Return only the settings needed to call Aviationstack."""
    load_dotenv(ENV_FILE)

    api_key = os.getenv("AVIATIONSTACK_API_KEY", "").strip()
    if not api_key or api_key == "replace-me":
        raise ValueError("Configure AVIATIONSTACK_API_KEY in producer/.env")

    airport_codes = [
        code.strip().upper()
        for code in os.getenv("PERU_AIRPORT_IATA_CODES", "").split(",")
        if code.strip()
    ]
    airport_codes = list(dict.fromkeys(airport_codes))

    if not airport_codes:
        raise ValueError("Configure PERU_AIRPORT_IATA_CODES in producer/.env")
    if any(len(code) != 3 or not code.isalpha() for code in airport_codes):
        raise ValueError("Every airport code must contain exactly three letters")

    page_limit = int(os.getenv("AVIATIONSTACK_PAGE_LIMIT", "100"))
    if page_limit < 1 or page_limit > 100:
        raise ValueError("AVIATIONSTACK_PAGE_LIMIT must be between 1 and 100")

    return {
        "api_key": api_key,
        "base_url": os.getenv(
            "AVIATIONSTACK_BASE_URL", "https://api.aviationstack.com/v1"
        ).rstrip("/"),
        "airport_codes": airport_codes,
        "flight_status": os.getenv(
            "AVIATIONSTACK_FLIGHT_STATUS", "active"
        ).strip(),
        "poll_interval_seconds": int(
            os.getenv("AVIATIONSTACK_POLL_INTERVAL_SECONDS", "60")
        ),
        "max_requests": int(os.getenv("AVIATIONSTACK_MAX_REQUESTS", "12")),
        "page_limit": page_limit,
        "request_timeout_seconds": int(
            os.getenv("AVIATIONSTACK_REQUEST_TIMEOUT_SECONDS", "20")
        ),
    }


def load_redpanda_config():
    """Return only the settings needed to connect to Redpanda."""
    load_dotenv(ENV_FILE)

    required_variables = [
        "REDPANDA_BOOTSTRAP_SERVERS",
        "REDPANDA_USERNAME",
        "REDPANDA_PASSWORD",
    ]
    missing_variables = [
        name
        for name in required_variables
        if os.getenv(name, "").strip() in ("", "replace-me")
    ]
    if missing_variables:
        raise ValueError(
            "Configure these variables in producer/.env: "
            + ", ".join(missing_variables)
        )

    return {
        "bootstrap_servers": os.getenv("REDPANDA_BOOTSTRAP_SERVERS").strip(),
        "security_protocol": os.getenv(
            "REDPANDA_SECURITY_PROTOCOL", "SASL_SSL"
        ).strip(),
        "sasl_mechanism": os.getenv(
            "REDPANDA_SASL_MECHANISM", "SCRAM-SHA-256"
        ).strip(),
        "username": os.getenv("REDPANDA_USERNAME").strip(),
        "password": os.getenv("REDPANDA_PASSWORD").strip(),
        "topic": os.getenv(
            "REDPANDA_TOPIC", "viation-peru"
        ).strip(),
        "topic_partitions": int(os.getenv("REDPANDA_TOPIC_PARTITIONS", "3")),
        "max_messages": int(os.getenv("REDPANDA_MAX_MESSAGES", "5")),
    }
