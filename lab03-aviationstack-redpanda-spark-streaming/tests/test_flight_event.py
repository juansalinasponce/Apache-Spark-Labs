import sys
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "producer"))

from flight_event import build_flight_event, event_key  # noqa: E402


SAMPLE_FLIGHT = {
    "flight_date": "2026-08-28",
    "flight_status": "active",
    "airline": {"name": "Demo Air", "iata": "DA", "icao": "DEM"},
    "flight": {"number": "101", "iata": "DA101", "icao": "DEM101"},
    "aircraft": {"registration": "OB-DEMO", "icao24": "E80001"},
    "departure": {"airport": "Jorge Chavez", "iata": "LIM"},
    "arrival": {"airport": "Cusco", "iata": "CUZ"},
    "live": {
        "updated": "2026-08-28T20:59:42+00:00",
        "latitude": -12.45,
        "longitude": -76.18,
        "altitude": 10363.0,
    },
}


class FlightEventTests(unittest.TestCase):
    def test_builds_the_redpanda_event(self):
        event = build_flight_event(SAMPLE_FLIGHT, "LIM", "DEPARTURE")

        self.assertEqual(event["schema_version"], 1)
        self.assertEqual(event["flight"]["key"], "DA101")
        self.assertEqual(event["airport_scope"]["airport_iata"], "LIM")
        self.assertEqual(event["position"]["altitude_meters"], 10363.0)
        self.assertEqual(event_key(event), "DA101")

    def test_event_id_is_stable_for_an_unchanged_snapshot(self):
        first = build_flight_event(SAMPLE_FLIGHT, "LIM", "DEPARTURE")
        second = build_flight_event(SAMPLE_FLIGHT, "LIM", "DEPARTURE")

        self.assertEqual(first["event_id"], second["event_id"])

    def test_rejects_a_flight_without_identity(self):
        with self.assertRaises(ValueError):
            build_flight_event({}, "LIM", "DEPARTURE")


if __name__ == "__main__":
    unittest.main()
