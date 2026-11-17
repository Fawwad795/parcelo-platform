#!/usr/bin/env bash
# Smoke test: a short, fast check that a running Parcelo tracker actually works.
#
# A smoke test answers one question after a deploy: "is the thing we just
# shipped alive and doing its job?" It is not a test suite. It exercises the
# few paths that must work for the release to count as healthy, and it exits
# non-zero on the first failure so a pipeline can stop or roll back.
#
# Usage:
#   scripts/smoke.sh http://localhost:8000
#   scripts/smoke.sh http://localhost:8000 abc1234     # also assert the build
#
# The optional second argument is the git SHA you expect to be serving. Use it
# in your deploy pipeline: a deploy that "succeeds" while the old build keeps
# serving traffic is a failed deploy.
#
# Requires: bash, curl, python3 (only to read JSON; no extra packages).

set -euo pipefail

BASE_URL="${1:?usage: smoke.sh BASE_URL [EXPECTED_GIT_SHA]}"
EXPECTED_SHA="${2:-}"
BASE_URL="${BASE_URL%/}"

# How long to wait for the service to become ready before giving up. A fresh
# pod or instance needs a moment; a pipeline should wait, not sleep blindly.
READY_TIMEOUT_SECONDS="${READY_TIMEOUT_SECONDS:-60}"

pass() { printf 'PASS  %s\n' "$1"; }
fail() {
  printf 'FAIL  %s\n' "$1" >&2
  exit 1
}

# json_field FILE KEY: print one top-level field of a JSON document.
json_field() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2"
}

BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT

# request METHOD PATH [JSON_BODY]: perform a request, save the body in $BODY,
# print the HTTP status code.
request() {
  local method="$1" path="$2" data="${3:-}"
  if [[ -n "$data" ]]; then
    curl -sS -o "$BODY" -w '%{http_code}' -X "$method" "$BASE_URL$path" \
      -H 'Content-Type: application/json' -d "$data"
  else
    curl -sS -o "$BODY" -w '%{http_code}' -X "$method" "$BASE_URL$path"
  fi
}

echo "Smoke testing $BASE_URL"

# 1. Wait for readiness (database reachable, instance accepting traffic).
deadline=$((SECONDS + READY_TIMEOUT_SECONDS))
until [[ "$(request GET /health/ready 2>/dev/null || true)" == "200" ]]; do
  if ((SECONDS >= deadline)); then
    fail "service not ready after ${READY_TIMEOUT_SECONDS}s (GET /health/ready)"
  fi
  sleep 2
done
pass "ready"

# 2. Liveness.
[[ "$(request GET /health)" == "200" ]] || fail "GET /health"
pass "health"

# 3. The build that is serving traffic.
[[ "$(request GET /version)" == "200" ]] || fail "GET /version"
SERVING_SHA="$(json_field "$BODY" git_sha)"
if [[ -n "$EXPECTED_SHA" && "$SERVING_SHA" != "$EXPECTED_SHA" ]]; then
  fail "wrong build is serving: expected $EXPECTED_SHA, got $SERVING_SHA"
fi
pass "version (git_sha=$SERVING_SHA)"

# 4. One real write and read through the database.
[[ "$(request POST /api/v1/parcels \
  '{"sender_name":"Smoke Test","recipient_name":"Smoke Test","origin_city":"Islamabad","destination_city":"Lahore","weight_kg":1.0}')" == "201" ]] ||
  fail "POST /api/v1/parcels"
TRACKING_ID="$(json_field "$BODY" tracking_id)"
pass "create parcel ($TRACKING_ID)"

[[ "$(request POST "/api/v1/parcels/$TRACKING_ID/events" \
  '{"status":"PICKED_UP","location":"Islamabad hub","note":"smoke test"}')" == "201" ]] ||
  fail "POST /api/v1/parcels/$TRACKING_ID/events"
pass "add event"

[[ "$(request GET "/api/v1/parcels/$TRACKING_ID")" == "200" ]] || fail "GET parcel"
[[ "$(json_field "$BODY" status)" == "PICKED_UP" ]] || fail "parcel status was not persisted"
pass "read parcel back"

# 5. An illegal move must be rejected, proving business rules are live.
[[ "$(request POST "/api/v1/parcels/$TRACKING_ID/events" \
  '{"status":"DELIVERED","location":"Lahore"}')" == "409" ]] ||
  fail "illegal transition was not rejected with 409"
pass "illegal transition rejected"

# 6. Metrics are exposed for Prometheus.
[[ "$(request GET /metrics)" == "200" ]] || fail "GET /metrics"
grep -q '^parcels_created_total' "$BODY" || fail "/metrics has no parcels_created_total"
pass "metrics"

echo "All smoke checks passed."
