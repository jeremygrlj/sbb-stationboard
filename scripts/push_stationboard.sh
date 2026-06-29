#!/usr/bin/env bash
set -euo pipefail

: "${TRMNL_WEBHOOK_URL:?Set TRMNL_WEBHOOK_URL to the webhook URL from your TRMNL plugin instance.}"

STATION_ID="${STATION_ID:-8503000}"
LIMIT="${LIMIT:-12}"
FETCH_LIMIT="${FETCH_LIMIT:-30}"
MIN_DEPARTURE_OFFSET="${MIN_DEPARTURE_OFFSET:-10}"
MAX_PAYLOAD_BYTES="${MAX_PAYLOAD_BYTES:-2048}"

api_response="$(
  curl -fsS -G "https://transport.opendata.ch/v1/stationboard" \
    --data-urlencode "id=${STATION_ID}" \
    --data-urlencode "limit=${FETCH_LIMIT}" \
    --data-urlencode "fields[]=stationboard/category" \
    --data-urlencode "fields[]=stationboard/number" \
    --data-urlencode "fields[]=stationboard/to" \
    --data-urlencode "fields[]=stationboard/stop/departure" \
    --data-urlencode "fields[]=stationboard/stop/prognosis/departure"
)"

filtered_response="$(
  printf '%s' "${api_response}" | ruby -rjson -rtime -e '
    data = JSON.parse(STDIN.read)
    min_departure = Time.now + Integer(ENV.fetch("MIN_DEPARTURE_OFFSET", "10")) * 60
    limit = Integer(ENV.fetch("LIMIT", "12"))

    rows = Array(data["stationboard"]).select do |row|
      raw = row.dig("stop", "departure")
      raw && Time.parse(raw) >= min_departure
    rescue ArgumentError
      false
    end.first(limit)

    puts JSON.generate("stationboard" => rows)
  '
)"

payload="{\"merge_variables\":${filtered_response}}"
payload_bytes="$(printf '%s' "${payload}" | wc -c | tr -d ' ')"
if [ "${payload_bytes}" -gt "${MAX_PAYLOAD_BYTES}" ]; then
  printf 'Payload is %s bytes, which exceeds the %s byte limit. Lower LIMIT or reduce fields.\n' "${payload_bytes}" "${MAX_PAYLOAD_BYTES}" >&2
  exit 1
fi

curl -fsS -X POST "${TRMNL_WEBHOOK_URL}" \
  -H "Content-Type: application/json" \
  -d "${payload}"

printf '\nStationboard data pushed for station %s (%s bytes).\n' "${STATION_ID}" "${payload_bytes}"
