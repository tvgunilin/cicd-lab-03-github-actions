#!/usr/bin/env bash
# Probe the lab's Flask app /health endpoint and exit non-zero on failure.
# Used by the docker-compose healthcheck and as the subject of shellcheck demos.

set -euo pipefail

URL="${HEALTHCHECK_URL:-http://localhost:5051/health}"
MAX_RETRIES="${HEALTHCHECK_MAX_RETRIES:-10}"
SLEEP_SECONDS="${HEALTHCHECK_SLEEP:-2}"

for i in $(seq 1 "$MAX_RETRIES"); do
  if curl -fsS --max-time 3 "$URL" >/dev/null; then
    echo "healthcheck: ok ($URL)"
    exit 0
  fi
  echo "healthcheck: attempt $i/$MAX_RETRIES failed; retrying in ${SLEEP_SECONDS}s..."
  sleep "$SLEEP_SECONDS"
done

echo "healthcheck: FAILED after $MAX_RETRIES attempts ($URL)" >&2
exit 1
