#!/usr/bin/env bash
set -Eeuo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${GOOGLE_CLOUD_PROJECT:?Export GOOGLE_CLOUD_PROJECT before running this script}"

REGION="${GCP_REGION:-us-central1}"
BIGQUERY_LOCATION="${BIGQUERY_LOCATION:-US}"
PUBSUB_TOPIC_ID="${PUBSUB_TOPIC_ID:-aviationstack-flights}"
BIGQUERY_DATASET="${BIGQUERY_DATASET:-aviation_realtime}"
BIGQUERY_TABLE="${BIGQUERY_TABLE:-flight_events}"
RUNTIME_SERVICE_ACCOUNT="${RUNTIME_SERVICE_ACCOUNT:-aviation-bq-writer}"
TRIGGER_SERVICE_ACCOUNT="${TRIGGER_SERVICE_ACCOUNT:-aviation-eventarc}"

for command in gcloud bq; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "Missing required command: ${command}" >&2
    exit 1
  fi
done

PROJECT_ID="${GOOGLE_CLOUD_PROJECT}"
RUNTIME_SA="${RUNTIME_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
TRIGGER_SA="${TRIGGER_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Enabling Google Cloud APIs in ${PROJECT_ID}..."
gcloud services enable \
  run.googleapis.com \
  eventarc.googleapis.com \
  eventarcpublishing.googleapis.com \
  pubsub.googleapis.com \
  bigquery.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  logging.googleapis.com \
  --project="${PROJECT_ID}"

PROJECT_NUMBER="$(
  gcloud projects describe "${PROJECT_ID}" \
    --format='value(projectNumber)'
)"
BUILD_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Cloud Build uses this identity for `gcloud run deploy --source` by default.
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${BUILD_SA}" \
  --role="roles/run.builder" \
  --condition=None >/dev/null

for service_account in "${RUNTIME_SERVICE_ACCOUNT}" "${TRIGGER_SERVICE_ACCOUNT}"; do
  email="${service_account}@${PROJECT_ID}.iam.gserviceaccount.com"
  if ! gcloud iam service-accounts describe "${email}" \
    --project="${PROJECT_ID}" >/dev/null 2>&1; then
    gcloud iam service-accounts create "${service_account}" \
      --display-name="Lab 04 ${service_account}" \
      --project="${PROJECT_ID}"
  fi
done

if ! bq --project_id="${PROJECT_ID}" show --dataset \
  "${PROJECT_ID}:${BIGQUERY_DATASET}" >/dev/null 2>&1; then
  bq --project_id="${PROJECT_ID}" mk --dataset \
    --location="${BIGQUERY_LOCATION}" \
    --description="Aviationstack near-real-time flight observations" \
    "${PROJECT_ID}:${BIGQUERY_DATASET}"
fi

sed \
  -e "s/{{PROJECT_ID}}/${PROJECT_ID}/g" \
  -e "s/{{BIGQUERY_DATASET}}/${BIGQUERY_DATASET}/g" \
  -e "s/{{BIGQUERY_TABLE}}/${BIGQUERY_TABLE}/g" \
  "${LAB_DIR}/schema/create_table.sql" \
  | bq --project_id="${PROJECT_ID}" query \
      --location="${BIGQUERY_LOCATION}" \
      --use_legacy_sql=false

bq --project_id="${PROJECT_ID}" add-iam-policy-binding --dataset \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/bigquery.dataEditor" \
  "${PROJECT_ID}:${BIGQUERY_DATASET}" >/dev/null

if ! gcloud pubsub topics describe "${PUBSUB_TOPIC_ID}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  gcloud pubsub topics create "${PUBSUB_TOPIC_ID}" --project="${PROJECT_ID}"
fi

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TRIGGER_SA}" \
  --role="roles/eventarc.eventReceiver" \
  --condition=None >/dev/null

ACTIVE_ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n 1)"
if [[ -n "${ACTIVE_ACCOUNT}" ]]; then
  if [[ "${ACTIVE_ACCOUNT}" == *"gserviceaccount.com" ]]; then
    ACTIVE_MEMBER="serviceAccount:${ACTIVE_ACCOUNT}"
  else
    ACTIVE_MEMBER="user:${ACTIVE_ACCOUNT}"
  fi
  gcloud pubsub topics add-iam-policy-binding "${PUBSUB_TOPIC_ID}" \
    --project="${PROJECT_ID}" \
    --member="${ACTIVE_MEMBER}" \
    --role="roles/pubsub.publisher" >/dev/null

  for service_account_email in "${RUNTIME_SA}" "${TRIGGER_SA}"; do
    gcloud iam service-accounts add-iam-policy-binding \
      "${service_account_email}" \
      --project="${PROJECT_ID}" \
      --member="${ACTIVE_MEMBER}" \
      --role="roles/iam.serviceAccountUser" >/dev/null
  done
fi

echo
echo "Base infrastructure is ready:"
echo "  topic: projects/${PROJECT_ID}/topics/${PUBSUB_TOPIC_ID}"
echo "  table: ${PROJECT_ID}.${BIGQUERY_DATASET}.${BIGQUERY_TABLE}"
echo "  region: ${REGION}"
echo "Run scripts/deploy_cloud_run.sh next."
