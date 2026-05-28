#!/bin/sh
set -e

file_env() {
    var="$1"
    def="${2:-}"
    file_var="${var}_FILE"

    eval "val=\${$var:-}"
    eval "file=\${$file_var:-}"

    if [ -n "$val" ] && [ -n "$file" ]; then
        echo "error: both $var and $file_var are set" >&2
        exit 1
    fi

    if [ -n "$file" ]; then
        if [ ! -f "$file" ]; then
            echo "error: $file_var points to missing file: $file" >&2
            exit 1
        fi
        val="$(cat "$file")"
    fi

    export "$var=${val:-$def}"
    unset "$file_var"
}

# Fix data directory permissions when running as root.
# Docker named volumes / host bind-mounts may be owned by root,
# preventing the non-root sub2api user from writing files.
if [ "$(id -u)" = "0" ]; then
    mkdir -p /app/data
    # Use || true to avoid failure on read-only mounted files (e.g. config.yaml:ro)
    chown -R sub2api:sub2api /app/data 2>/dev/null || true
    # Re-invoke this script as sub2api so the flag-detection below
    # also runs under the correct user.
    exec su-exec sub2api "$0" "$@"
fi

# Compatibility: if the first arg looks like a flag (e.g. --help),
# prepend the default binary so it behaves the same as the old
# ENTRYPOINT ["/app/sub2api"] style.
if [ "${1#-}" != "$1" ]; then
    set -- /app/sub2api "$@"
fi

file_env DATABASE_PASSWORD
file_env REDIS_PASSWORD
file_env ADMIN_PASSWORD
file_env JWT_SECRET
file_env TOTP_ENCRYPTION_KEY
file_env BOOTSTRAP_TURNSTILE_SECRET_KEY
file_env BOOTSTRAP_SMTP_PASSWORD

exec "$@"
