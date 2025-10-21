#!/bin/bash
# ============================================================
#  Reset CHR QEMU Aman (hapus lama + install baru)
#  Auto Config included
# ============================================================

set -e
CONFIG_FILE="/opt/chr-installer/config.conf"
WORK_DIR="/opt/chr-installer"
IMAGE_DIR="$WORK_DIR/chr-image"
LOG_DIR="$WORK_DIR/logs"
SERVICE_PATH="/etc/systemd/system/chr.service"

mkdir -p "$WORK_DIR" "$IMAGE_DIR" "$LOG_DIR"
source "$CONFIG_FILE"

echo "🧹 Menghapus instalasi lama..."
systemctl stop chr 2>/dev/null || true
systemctl disable chr 2>/dev/null || true
pkill -f qemu-system-x86_64 || true
rm -f "$SERVICE_PATH"
rm -rf "$IMAGE_DIR"
mkdir -p "$IMAGE_DIR"

cd "$IMAGE_DIR"
wget -q "$IMAGE_URL" -O chr.zip
unzip -o chr.zip >/dev/null 2>&1
rm -f chr.zip
qemu-img resize "$IMAGE_FILE" "$DISK_SIZE"

qemu-system-x86_64 \
  -name "$VM_NAME" -machine accel=kvm -cpu host -m "$RAM" \
  -drive file="$IMAGE_DIR/$IMAGE_FILE",if=virtio \
  -net nic -net user,hostfwd=tcp::$SSH_PORT-:22,hostfwd=tcp::$WINBOX_PORT-:8291,hostfwd=tcp::$API_PORT-:8728 \
  -nographic -daemonize

bash /opt/chr-installer/auto-config-chr.sh >> "$LOG_DIR/install.log" 2>&1 || true

clear
echo "✅ CHR berhasil di-reset dan diinstal ulang!"
echo "SSH (CLI): ssh -p $SSH_PORT admin@<IP_PUBLIK>"
echo "Winbox: <IP_PUBLIK>:$WINBOX_PORT"
echo "API: <IP_PUBLIK>:$API_PORT"
