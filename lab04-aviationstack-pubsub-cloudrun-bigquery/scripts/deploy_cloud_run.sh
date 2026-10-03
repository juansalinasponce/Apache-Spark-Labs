#!/usr/bin/env bash
set -Eeuo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${GOOGLE_CLOUD_PROJECT:?Export GOOGLE_CLOUD_PROJECT before running this script}"

PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
REGION="${GCP_REGION:-us-central1}"
PUBSUB_TOPIC_ID="${PUBSUB_TOPIC_ID:-aviationstack-flights}"
BIGQUERY_DATASET="${BIGQUERY_DATASET:-aviation_realtime}"
BIGQUERY_TABLE="${BIGQUERY_TABLE:-flight_events}"
SERVICE_NAME="${CLOUD_RUN_SERVICE:-aviation-to-bigquery}"
TRIGGER_NAME="${EVENTARC_TRIGGER:-aviation-pubsub-trigger}"
RUNTIME_SERVICE_ACCOUNT="${RUNTIME_SERVICE_ACCOUNT:-aviation-bq-writer}"
TRIGGER_SERVICE_ACCOUNT="${TRIGGER_SERVICE_ACCOUNT:-aviation-eventarc}"

RUNTIME_SA="${RUNTIME_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
TRIGGER_SA="${TRIGGER_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
TABLE_ID="${PROJECT_ID}.${BIGQUERY_DATASET}.${BIGQUERY_TABLE}"
TOPIC_PATH="projects/${PROJECT_ID}/topics/${PUBSUB_TOPIC_ID}"

gcloud run deploy "${SERVICE_NAME}" \
  --source="${LAB_DIR}/cloud_run" \
  --function=process_flight \
  --base-image=python314 \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --service-account="${RUNTIME_SA}" \
  --set-env-vars="BIGQUERY_TABLE_ID=${TABLE_ID}" \
  --no-allow-unauthenticated

gcloud run services add-iam-policy-binding "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --member="serviceAccount:${TRIGGER_SA}" \
  --role="roles/run.invoker" >/dev/null

if gcloud eventarc triggers describe "${TRIGGER_NAME}" \
  --location="${REGION}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Eventarc trigger ${TRIGGER_NAME} already exists; leaving it unchanged."
else
  gcloud eventarc triggers create "${TRIGGER_NAME}" \
    --location="${REGION}" \
    --project="${PROJECT_ID}" \
    --destination-run-service="${SERVICE_NAME}" \
    --destination-run-region="${REGION}" \
    --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished" \
    --transport-topic="${TOPIC_PATH}" \
    --service-account="${TRIGGER_SA}"
fi

echo
echo "Cloud Run and Eventarc are ready."
echo "Service: ${SERVICE_NAME}"
echo "Trigger: ${TRIGGER_NAME}"
echo "BigQuery table: ${TABLE_ID}"
