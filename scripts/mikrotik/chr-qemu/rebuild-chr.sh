#!/bin/bash
# ============================================================
#  Uninstall CHR Aman
# ============================================================
set -e
WORK_DIR="/opt/chr-installer"
SERVICE_PATH="/etc/systemd/system/chr.service"

systemctl stop chr 2>/dev/null || true
systemctl disable chr 2>/dev/null || true
rm -f "$SERVICE_PATH"
pkill -f qemu-system-x86_64 || true
rm -rf "$WORK_DIR"
systemctl daemon-reload
echo "✅ CHR dan semua komponennya telah dihapus."
