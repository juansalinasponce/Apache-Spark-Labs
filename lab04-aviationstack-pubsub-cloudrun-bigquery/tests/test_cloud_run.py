"""Tests for the source-based Cloud Run function."""

import base64
import json
import os
import unittest
from types import SimpleNamespace
from unittest.mock import patch

from cloud_run.main import process_flight


EVENT = {
    "event_id": "a" * 64,
    "collected_at": "2026-09-02T15:00:00+00:00",
    "flight_date": "2026-09-02",
    "flight_status": "active",
    "flight_iata": "LA123",
}


def cloud_event(event: dict) -> SimpleNamespace:
    encoded = base64.b64encode(json.dumps(event).encode()).decode()
    return SimpleNamespace(
        data={"message": {"data": encoded, "messageId": "message-123"}}
    )


class CloudRunFunctionTest(unittest.TestCase):
    @patch("cloud_run.main.bigquery.Client")
    def test_inserts_valid_event(self, client_class) -> None:
        os.environ["BIGQUERY_TABLE_ID"] = "project.dataset.table"
        client_class.return_value.insert_rows_json.return_value = []

        process_flight(cloud_event(EVENT))

        call = client_class.return_value.insert_rows_json.call_args
        self.assertEqual(call.args[0], "project.dataset.table")
        self.assertEqual(call.kwargs["row_ids"], [EVENT["event_id"]])

    @patch("cloud_run.main.bigquery.Client")
    def test_discards_invalid_message(self, client_class) -> None:
        invalid_event = SimpleNamespace(data={"message": {"data": "%%%"}})

        process_flight(invalid_event)

        client_class.assert_not_called()


if __name__ == "__main__":
    unittest.main()
