"""Tests for the simplified local producer."""

import unittest

from producer.publisher import build_event


class PublisherTest(unittest.TestCase):
    def test_build_event_is_flat(self) -> None:
        flight = {
            "flight_date": "2026-09-02",
            "flight_status": "active",
            "flight": {"iata": "LA123"},
            "airline": {"name": "LATAM"},
            "departure": {"iata": "CUZ"},
            "arrival": {"iata": "LIM"},
            "live": {"latitude": -12.0, "altitude": 8000},
        }
        config = {"airport_iata": "LIM", "movement_type": "ARRIVAL"}

        event = build_event(flight, config)

        self.assertEqual(event["flight_iata"], "LA123")
        self.assertEqual(event["arrival_iata"], "LIM")
        self.assertEqual(event["altitude_meters"], 8000)
        self.assertEqual(len(event["event_id"]), 64)


if __name__ == "__main__":
    unittest.main()

