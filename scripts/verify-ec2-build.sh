#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-4173}"
BASE_URL="http://127.0.0.1:${PORT}"
SERVER_LOG="$(mktemp -t b6-cloud-static-server.XXXXXX)"
SERVER_PID=""

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -f "$SERVER_LOG"
}

trap cleanup EXIT INT TERM

npm run build:ec2

if [[ ! -f out/index.html || ! -f out/health ]]; then
  printf 'EC2 build is incomplete: out/index.html and out/health are required.\n' >&2
  exit 1
fi

python3 -m http.server "$PORT" --bind 127.0.0.1 --directory out >"$SERVER_LOG" 2>&1 &
SERVER_PID="$!"

for _ in {1..20}; do
  if curl --fail --silent --output /dev/null "$BASE_URL/"; then
    break
  fi
  sleep 0.25
done

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
  printf 'The local static server failed to start.\n' >&2
  sed -n '1,120p' "$SERVER_LOG" >&2
  exit 1
fi

bash scripts/verify-local.sh "$BASE_URL"
printf 'EC2 static package: READY (out/)\n'
