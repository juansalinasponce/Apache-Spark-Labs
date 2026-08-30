import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_NOTEBOOK = PROJECT_ROOT / "databricks" / "00_config.py"


class FakeWidgets:
    def __init__(self, overrides=None):
        self.values = dict(overrides or {})

    def text(self, name, default, label):
        self.values.setdefault(name, default)

    def get(self, name):
        return self.values[name]


class FakeDbutils:
    def __init__(self, overrides=None):
        self.widgets = FakeWidgets(overrides)


class FakeSparkConf:
    def set(self, key, value):
        return None


class FakeSpark:
    def __init__(self):
        self.conf = FakeSparkConf()


def load_config(overrides=None):
    namespace = {
        "dbutils": FakeDbutils(overrides),
        "spark": FakeSpark(),
    }
    source = CONFIG_NOTEBOOK.read_text(encoding="utf-8")
    exec(compile(source, CONFIG_NOTEBOOK.name, "exec"), namespace)
    return namespace


class DatabricksTaxonomyTests(unittest.TestCase):
    def test_builds_development_catalogs_and_s3_prefixes(self):
        config = load_config()

        self.assertEqual(config["BRONZE_CATALOG"], "bronze_dev")
        self.assertEqual(config["SILVER_CATALOG"], "silver_dev")
        self.assertEqual(config["GOLD_CATALOG"], "gold_dev")
        self.assertEqual(config["BRONZE_SCHEMA"], "aviationstack")
        self.assertEqual(config["SILVER_SCHEMA"], "aviation")
        self.assertEqual(config["GOLD_SCHEMA"], "peru_flight_tracking")
        self.assertIn(
            "/dev/bronze/aviationstack/flights",
            config["BRONZE_AVIATIONSTACK_FLIGHTS_LOCATION"],
        )
        self.assertIn(
            "/dev/operations/checkpoints/",
            config["BRONZE_CHECKPOINT_LOCATION"],
        )

    def test_rejects_an_unknown_environment(self):
        with self.assertRaises(ValueError):
            load_config({"environment": "qa"})


if __name__ == "__main__":
    unittest.main()
