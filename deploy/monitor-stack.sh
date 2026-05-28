#!/bin/bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-./runtime/.env.production}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
STATE_FILE="${STATE_FILE:-./runtime/monitor-state}"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"

if [ ! -f "$ENV_FILE" ]; then
    echo "missing env file: $ENV_FILE" >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

READYZ_URL="${READYZ_URL:-http://127.0.0.1:${SERVER_PORT:-8080}/readyz}"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:-${MONITOR_ALERT_WEBHOOK_URL:-}}"

mkdir -p "$(dirname "$STATE_FILE")"

status="ok"
details=()

append_detail() {
    details+=("$1")
}

if ! curl -fsS --max-time 10 "$READYZ_URL" >/tmp/nexora-readyz.$$ 2>/tmp/nexora-readyz.err; then
    status="failed"
    append_detail "readyz check failed"
fi
rm -f /tmp/nexora-readyz.$$ /tmp/nexora-readyz.err

for container in nexora nexora-postgres nexora-redis; do
    inspect_status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || true)"
    if [ -z "$inspect_status" ] || { [ "$inspect_status" != "healthy" ] && [ "$inspect_status" != "running" ]; }; then
        status="failed"
        append_detail "$container=$inspect_status"
    fi
done

if ! docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T postgres sh -ceu '
    export PGPASSWORD="$(cat /run/secrets/postgres_password)"
    pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
' >/dev/null 2>&1; then
    status="failed"
    append_detail "postgres pg_isready failed"
fi

last_status=""
if [ -f "$STATE_FILE" ]; then
    last_status="$(cat "$STATE_FILE" 2>/dev/null || true)"
fi

printf '%s' "$status" >"$STATE_FILE"

if [ "$status" = "failed" ]; then
    message="nexora production monitor failed: ${details[*]}"
    echo "$message" >&2
    if [ "$last_status" != "failed" ] && [ -n "$ALERT_WEBHOOK_URL" ]; then
        curl -fsS -X POST "$ALERT_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"text\":\"${message//\"/\\\"}\"}" >/dev/null || true
    fi
    exit 1
fi

if [ "$last_status" = "failed" ] && [ -n "$ALERT_WEBHOOK_URL" ]; then
    curl -fsS -X POST "$ALERT_WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d '{"text":"nexora production monitor recovered"}' >/dev/null || true
fi

echo "monitor ok"
