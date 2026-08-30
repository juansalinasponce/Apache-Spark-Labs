"""Make one controlled Aviationstack request and preview the result."""

import requests

from config import load_aviationstack_config


def fetch_flights(config, airport_code, movement_type):
    """Fetch departures or arrivals for one airport."""
    if movement_type == "DEPARTURE":
        airport_filter = "dep_iata"
    elif movement_type == "ARRIVAL":
        airport_filter = "arr_iata"
    else:
        raise ValueError("movement_type must be DEPARTURE or ARRIVAL")

    parameters = {
        "access_key": config["api_key"],
        airport_filter: airport_code,
        "limit": config["page_limit"],
    }
    if config["flight_status"]:
        parameters["flight_status"] = config["flight_status"]

    try:
        response = requests.get(
            f'{config["base_url"]}/flights',
            params=parameters,
            timeout=config["request_timeout_seconds"],
        )
    except requests.RequestException:
        # Requests exceptions can include the full URL and its access_key.
        raise RuntimeError("Could not connect to Aviationstack") from None

    # Avoid response.raise_for_status(): its message can include the API key URL.
    if response.status_code != 200:
        raise RuntimeError(
            f"Aviationstack returned HTTP status {response.status_code}"
        )

    try:
        payload = response.json()
    except requests.JSONDecodeError:
        raise RuntimeError("Aviationstack returned invalid JSON") from None
    if payload.get("error"):
        error = payload["error"]
        raise RuntimeError(
            f"Aviationstack error: {error.get('type', 'unknown_error')}"
        )

    flights = payload.get("data")
    if not isinstance(flights, list):
        raise RuntimeError("Aviationstack response does not contain a data list")

    return flights


def print_preview(flights, maximum_rows=5):
    """Print a small business-friendly preview instead of the complete JSON."""
    if not flights:
        print("No flights found for this query")
        return

    print(f"Flights returned: {len(flights)}")
    print(f"Showing at most {maximum_rows} flights:\n")

    for flight_data in flights[:maximum_rows]:
        flight = flight_data.get("flight") or {}
        departure = flight_data.get("departure") or {}
        arrival = flight_data.get("arrival") or {}

        flight_code = flight.get("iata") or flight.get("icao") or "UNKNOWN"
        status = flight_data.get("flight_status") or "unknown"
        origin = departure.get("iata") or "---"
        destination = arrival.get("iata") or "---"

        print(f"{flight_code}: {origin} -> {destination} | status={status}")


def main():
    config = load_aviationstack_config()
    airport_code = config["airport_codes"][0]
    movement_type = "DEPARTURE"

    print(f"Querying {movement_type.lower()} flights for {airport_code}...")
    flights = fetch_flights(config, airport_code, movement_type)
    print_preview(flights)


if __name__ == "__main__":
    main()
