#!/bin/bash
# =============================================================================
# Nexora Production Deployment Preparation Script
# =============================================================================
# Prepares ./runtime for production:
#   - copies .env.production.example to ./runtime/.env.production
#   - generates secret files under ./runtime/secrets
#   - creates data / backup directories with restrictive permissions
#
# After running:
#   docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml up -d --build
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RUNTIME_DIR="./runtime"
SECRETS_DIR="${RUNTIME_DIR}/secrets"
ENV_OUTPUT="${RUNTIME_DIR}/.env.production"
ENV_TEMPLATE=".env.production.example"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

generate_hex() {
    local bytes="$1"
    openssl rand -hex "$bytes"
}

write_secret_file() {
    local path="$1"
    local value="$2"
    printf '%s' "$value" >"$path"
    chmod 600 "$path"
}

main() {
    echo ""
    echo "=========================================="
    echo "  Nexora Production Preparation"
    echo "=========================================="
    echo ""

    if ! command_exists openssl; then
        print_error "openssl is not installed. Please install openssl first."
        exit 1
    fi

    if [ ! -f "$ENV_TEMPLATE" ] || [ ! -f "docker-compose.prod.yml" ]; then
        print_error "$ENV_TEMPLATE or docker-compose.prod.yml is missing."
        print_error "Run this script from the deploy directory of the Nexora source tree."
        exit 1
    fi

    if [ -f "$ENV_OUTPUT" ]; then
        print_warning "$ENV_OUTPUT already exists."
        read -p "Recreate runtime env and overwrite generated secrets? (y/N): " -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cancelled."
            exit 0
        fi
    fi

    mkdir -p "$RUNTIME_DIR" "$SECRETS_DIR" data postgres_data redis_data backups
    chmod 700 "$RUNTIME_DIR" "$SECRETS_DIR" data postgres_data redis_data backups

    cp "$ENV_TEMPLATE" "$ENV_OUTPUT"
    chmod 600 "$ENV_OUTPUT"
    print_success "Created $ENV_OUTPUT from template"

    print_info "Generating runtime secret files..."
    postgres_password="$(generate_hex 32)"
    redis_password="$(generate_hex 32)"
    admin_password="$(generate_hex 20)"
    jwt_secret="$(generate_hex 32)"
    totp_key="$(generate_hex 32)"

    write_secret_file "${SECRETS_DIR}/postgres_password" "$postgres_password"
    write_secret_file "${SECRETS_DIR}/redis_password" "$redis_password"
    write_secret_file "${SECRETS_DIR}/admin_password" "$admin_password"
    write_secret_file "${SECRETS_DIR}/jwt_secret" "$jwt_secret"
    write_secret_file "${SECRETS_DIR}/totp_encryption_key" "$totp_key"
    : >"${SECRETS_DIR}/turnstile_secret_key"
    : >"${SECRETS_DIR}/smtp_password"
    chmod 600 "${SECRETS_DIR}/turnstile_secret_key" "${SECRETS_DIR}/smtp_password"

    echo ""
    echo "Initial bootstrap credentials"
    echo "  ADMIN_EMAIL:    review in ${ENV_OUTPUT}"
    echo "  ADMIN_PASSWORD: ${admin_password}"
    echo ""
    print_warning "This admin password is only for first login/bootstrap."
    print_warning "Change it in the UI, then run ./finalize-production-bootstrap.sh."
    echo ""
    echo "Next steps:"
    echo "  1. Review ${ENV_OUTPUT} and fill PUBLIC_DOMAIN / URLs / allowlist / optional SMTP"
    echo "  2. Put Turnstile or SMTP secrets into ${SECRETS_DIR} if you enable them"
    echo "  3. Start stack:"
    echo "     docker compose --env-file ${ENV_OUTPUT} -f docker-compose.prod.yml up -d --build"
    echo "  4. Check readiness:"
    echo "     curl -fsS http://127.0.0.1:8080/readyz"
    echo "  5. Put Nginx/Caddy in front and terminate TLS on 80/443"
    echo ""
}

main "$@"
