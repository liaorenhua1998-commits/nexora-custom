#!/bin/bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-./runtime/.env.production}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
INPUT_FILE="${1:-}"
CONFIRM="${CONFIRM:-}"

if [ -z "$INPUT_FILE" ]; then
    echo "usage: $0 <backup.sql.gz>" >&2
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo "missing env file: $ENV_FILE" >&2
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "missing backup file: $INPUT_FILE" >&2
    exit 1
fi

if [ "$CONFIRM" != "ERASE_PUBLIC_SCHEMA" ]; then
    echo "refusing restore without CONFIRM=ERASE_PUBLIC_SCHEMA" >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

echo "stopping nexora before restore..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" stop nexora

echo "resetting public schema..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T postgres sh -ceu '
    export PGPASSWORD="$(cat /run/secrets/postgres_password)"
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO CURRENT_USER;
GRANT ALL ON SCHEMA public TO public;
EOF
'

echo "restoring backup from $INPUT_FILE ..."
gzip -dc "$INPUT_FILE" | docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T postgres sh -ceu '
    export PGPASSWORD="$(cat /run/secrets/postgres_password)"
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"
'

echo "starting nexora after restore..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" start nexora

echo "restore completed"
