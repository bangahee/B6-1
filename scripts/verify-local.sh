#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${1:-http://localhost:3000}"

printf 'Checking %s\n' "$BASE_URL"
curl --fail --silent --show-error --output /dev/null "$BASE_URL/"
HEALTH_RESPONSE="$(curl --fail --silent --show-error "$BASE_URL/health")"

if [[ "$HEALTH_RESPONSE" != "OK" ]]; then
  printf 'Expected health response OK, received: %s\n' "$HEALTH_RESPONSE" >&2
  exit 1
fi

printf 'Home page: OK\nHealth endpoint: 200 OK (%s)\n' "$HEALTH_RESPONSE"
