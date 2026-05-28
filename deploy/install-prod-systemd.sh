#!/bin/bash
set -euo pipefail

SYSTEMD_DIR="${SYSTEMD_DIR:-/etc/systemd/system}"
DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/nexora/deploy}"
RUN_AS_USER="${RUN_AS_USER:-nexora}"
RUN_AS_GROUP="${RUN_AS_GROUP:-$RUN_AS_USER}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

require_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        echo "run as root: sudo $0" >&2
        exit 1
    fi
}

install_unit() {
    local source_file="$1"
    local target_file="$2"
    sed \
        -e "s|/opt/nexora/deploy|${DEPLOY_ROOT}|g" \
        -e "s|User=nexora|User=${RUN_AS_USER}|g" \
        -e "s|Group=nexora|Group=${RUN_AS_GROUP}|g" \
        "$source_file" >"$target_file"
    chmod 644 "$target_file"
}

require_root

install_unit "${SCRIPT_DIR}/nexora-backup.service" "${SYSTEMD_DIR}/nexora-backup.service"
install_unit "${SCRIPT_DIR}/nexora-monitor.service" "${SYSTEMD_DIR}/nexora-monitor.service"
cp "${SCRIPT_DIR}/nexora-backup.timer" "${SYSTEMD_DIR}/nexora-backup.timer"
cp "${SCRIPT_DIR}/nexora-monitor.timer" "${SYSTEMD_DIR}/nexora-monitor.timer"
chmod 644 \
    "${SYSTEMD_DIR}/nexora-backup.timer" \
    "${SYSTEMD_DIR}/nexora-monitor.timer"

systemctl daemon-reload
systemctl enable --now nexora-backup.timer nexora-monitor.timer

echo "installed systemd timers:"
echo "  nexora-backup.timer"
echo "  nexora-monitor.timer"
echo "inspect with:"
echo "  systemctl status nexora-backup.timer nexora-monitor.timer"
echo "  systemctl list-timers --all | grep nexora"
