#!/bin/bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-./runtime/.env.production}"
ADMIN_SECRET_FILE="${ADMIN_SECRET_FILE:-./runtime/secrets/admin_password}"

if [ ! -f "$ENV_FILE" ]; then
    echo "missing env file: $ENV_FILE" >&2
    exit 1
fi

replace_env_value() {
    local key="$1"
    local value="$2"

    if sed --version >/dev/null 2>&1; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
        sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    fi
}

replace_env_value "AUTO_SETUP" "false"

if [ -f "$ADMIN_SECRET_FILE" ]; then
    openssl rand -hex 20 >"$ADMIN_SECRET_FILE"
    chmod 600 "$ADMIN_SECRET_FILE"
fi

echo "AUTO_SETUP disabled in $ENV_FILE"
echo "bootstrap admin secret rotated in $ADMIN_SECRET_FILE"
echo "restart the app so future boots skip admin bootstrap:"
echo "  docker compose --env-file $ENV_FILE -f docker-compose.prod.yml up -d --build nexora"
