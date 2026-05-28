#!/bin/bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-./runtime/.env.production}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

if [ ! -f "$ENV_FILE" ]; then
    echo "missing env file: $ENV_FILE" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
output="${BACKUP_DIR}/postgres_${timestamp}.sql.gz"

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T postgres sh -ceu '
    export PGPASSWORD="$(cat /run/secrets/postgres_password)"
    pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"
' | gzip -9 > "$output"

if [ "$BACKUP_RETENTION_DAYS" -gt 0 ] 2>/dev/null; then
    find "$BACKUP_DIR" -maxdepth 1 -type f -name 'postgres_*.sql.gz' -mtime "+$BACKUP_RETENTION_DAYS" -delete
fi

echo "backup written to $output"
