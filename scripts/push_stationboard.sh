#!/usr/bin/env bash
set -euo pipefail

: "${TRMNL_WEBHOOK_URL:?Set TRMNL_WEBHOOK_URL to the webhook URL from your TRMNL plugin instance.}"

STATION_ID="${STATION_ID:-8503000}"
LIMIT="${LIMIT:-12}"

api_response="$(
  curl -fsS -G "https://transport.opendata.ch/v1/stationboard" \
    --data-urlencode "id=${STATION_ID}" \
    --data-urlencode "limit=${LIMIT}" \
    --data-urlencode "fields[]=stationboard/category" \
    --data-urlencode "fields[]=stationboard/number" \
    --data-urlencode "fields[]=stationboard/to" \
    --data-urlencode "fields[]=stationboard/stop/departure" \
    --data-urlencode "fields[]=stationboard/stop/prognosis/departure"
)"

curl -fsS -X POST "${TRMNL_WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -d "{\"merge_variables\":${api_response}}"

printf '\nStationboard data pushed for station %s.\n' "${STATION_ID}"
