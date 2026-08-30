import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "producer"))

from config import load_aviationstack_config, load_redpanda_config  # noqa: E402


AVIATION_ENV = {
    "AVIATIONSTACK_API_KEY": "test-api-key",
    "PERU_AIRPORT_IATA_CODES": "lim, CUZ,LIM,aQp",
    "AVIATIONSTACK_PAGE_LIMIT": "50",
}

REDPANDA_ENV = {
    "REDPANDA_BOOTSTRAP_SERVERS": "cluster.example:9092",
    "REDPANDA_USERNAME": "test-user",
    "REDPANDA_PASSWORD": "test-password",
}


class ConfigTests(unittest.TestCase):
    def load_aviation(self, values):
        with patch.dict(os.environ, values, clear=True), patch(
            "config.load_dotenv"
        ):
            return load_aviationstack_config()

    def load_redpanda(self, values):
        with patch.dict(os.environ, values, clear=True), patch(
            "config.load_dotenv"
        ):
            return load_redpanda_config()

    def test_normalizes_airport_codes(self):
        config = self.load_aviation(AVIATION_ENV)

        self.assertEqual(config["airport_codes"], ["LIM", "CUZ", "AQP"])
        self.assertEqual(config["flight_status"], "active")

    def test_rejects_invalid_airport_codes(self):
        values = {**AVIATION_ENV, "PERU_AIRPORT_IATA_CODES": "LIM,PERU"}

        with self.assertRaises(ValueError):
            self.load_aviation(values)

    def test_rejects_invalid_page_limit(self):
        values = {**AVIATION_ENV, "AVIATIONSTACK_PAGE_LIMIT": "101"}

        with self.assertRaises(ValueError):
            self.load_aviation(values)

    def test_uses_secure_redpanda_defaults(self):
        config = self.load_redpanda(REDPANDA_ENV)

        self.assertEqual(config["security_protocol"], "SASL_SSL")
        self.assertEqual(config["sasl_mechanism"], "SCRAM-SHA-256")

    def test_requires_redpanda_credentials(self):
        with self.assertRaises(ValueError):
            self.load_redpanda({})


if __name__ == "__main__":
    unittest.main()
