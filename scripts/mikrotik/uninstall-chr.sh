#!/usr/bin/env bash
# tidy-clean.sh — safe cleanup for previous CHR installs
# Will stop/disable chr.service, kill qemu processes that match our pattern,
# remove default install dirs under /opt/dimensi-labs/mikrotik but will NOT remove
# any file named scure-debian12.sh anywhere under /opt/dimensi-labs/mikrotik.
set -euo pipefail
IFS=$'\n\t'

WORK_DIR="/opt/dimensi-labs/mikrotik"
SERVICE_NAME="chr"
echo ">>> Running tidy-clean (will NOT touch scure-debian12.sh) ..."

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this as root."
  exit 1
fi

# Stop and disable systemd service
if systemctl list-unit-files | grep -q "^${SERVICE_NAME}\.service"; then
  echo "Stopping and disabling ${SERVICE_NAME}.service ..."
  systemctl stop "${SERVICE_NAME}" 2>/dev/null || true
  systemctl disable "${SERVICE_NAME}" 2>/dev/null || true
  systemctl daemon-reload || true
fi

# Kill qemu processes that look like CHR (best-effort)
echo "Killing QEMU processes related to CHR (best-effort) ..."
pgrep -af qemu-system | while read -r pidline; do
  pid=$(echo "$pidline" | awk '{print $1}')
  cmd=$(echo "$pidline" | cut -d' ' -f2-)
  if echo "$cmd" | grep -Ei "chr|mikrotik|chr-vm|dimensi" >/dev/null 2>&1; then
    echo "  killing pid=$pid ($cmd)"
    kill "$pid" 2>/dev/null || pkill -9 -P "$pid" 2>/dev/null || true
  fi
done || true

# Remove systemd unit file if exists
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
if [ -f "$SERVICE_PATH" ]; then
  echo "Removing $SERVICE_PATH"
  rm -f "$SERVICE_PATH"
  systemctl daemon-reload || true
fi

# Cleanup files under WORK_DIR but protect scure-debian12.sh
if [ -d "$WORK_DIR" ]; then
  echo "Cleaning $WORK_DIR contents except scure-debian12.sh ..."
  # Move files we want to keep temporarily (only scure-debian12.sh)
  KEEP="$WORK_DIR/scure-debian12.sh"
  TMP_SAVE="/tmp/_scure_save_$$.sh"
  if [ -f "$KEEP" ]; then
    cp -a "$KEEP" "$TMP_SAVE"
  fi

  # Remove everything under WORK_DIR
  rm -rf "${WORK_DIR:?}/"* || true

  # Restore scure script if it existed
  if [ -f "$TMP_SAVE" ]; then
    mkdir -p "$WORK_DIR"
    mv "$TMP_SAVE" "$KEEP"
    chmod 644 "$KEEP"
    echo "Restored preserved file: $KEEP"
  fi
else
  echo "No $WORK_DIR dir found; nothing to delete there."
fi

# Remove expect temp files and leftover qemu pid files (best-effort)
echo "Cleaning /tmp/chr-* and leftover qemu pid files ..."
rm -f /tmp/chr-ssh-* /tmp/chr-telnet-* /tmp/expect-* || true
rm -f /var/run/qemu-*-* /var/run/qemu-pid* 2>/dev/null || true

echo ">>> tidy-clean finished. Nothing else removed. You can now run the fresh installer."
