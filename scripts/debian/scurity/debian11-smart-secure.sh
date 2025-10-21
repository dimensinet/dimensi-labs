#!/bin/bash
# ==========================================
# Debian 11/12 Secure Setup Script (v3.1)
# By ChatGPT (for dimensi.net)
# - Support custom SSH port
# - Safe for root-only SSH environments
# ==========================================
set -euo pipefail

echo "🚀 Starting Secure Setup (v3.1) for Debian 11/12..."
sleep 1

# --- Must run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Jalankan script ini sebagai root!"
  exit 1
fi

# ========== 1. Buat user baru ==========
read -p "👤 Masukkan nama user admin baru: " NEWUSER
if id "$NEWUSER" &>/dev/null; then
    echo "⚠️ User $NEWUSER sudah ada, melewati pembuatan."
else
    adduser --gecos "" "$NEWUSER"
    usermod -aG sudo "$NEWUSER"
    echo "✅ User $NEWUSER telah ditambahkan ke grup sudo."
fi

# ========== 2. Tambahkan SSH Key ==========
read -p "🔑 Masukkan public SSH key (mulai dengan ssh-rsa atau ssh-ed25519): " SSHKEY
mkdir -p /home/$NEWUSER/.ssh
echo "$SSHKEY" > /home/$NEWUSER/.ssh/authorized_keys
chmod 700 /home/$NEWUSER/.ssh
chmod 600 /home/$NEWUSER/.ssh/authorized_keys
chown -R $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh
echo "✅ SSH key berhasil ditambahkan untuk user $NEWUSER."

# ========== 3. Ganti port SSH ==========
read -p "📡 Masukkan port SSH custom (misal: 8822): " CUSTOM_PORT
if [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]] && [ "$CUSTOM_PORT" -ge 1024 ] && [ "$CUSTOM_PORT" -le 65535 ]; then
    echo "🔧 Mengubah SSH ke port $CUSTOM_PORT..."
    SSHD_CONF="/etc/ssh/sshd_config"
    cp "$SSHD_CONF" "${SSHD_CONF}.backup-$(date +%F-%H%M)"
    sed -i '/^#\?Port /d' "$SSHD_CONF"
    echo "Port $CUSTOM_PORT" >> "$SSHD_CONF"
    echo "✅ Port SSH diganti ke $CUSTOM_PORT"
else
    echo "⚠️ Port tidak valid. Gunakan default 22."
    CUSTOM_PORT=22
fi

# ========== 4. Update sistem ==========
echo "📦 Update & upgrade sistem..."
export DEBIAN_FRONTEND=noninteractive
apt update -yq
apt -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade -yq
apt install -yq sudo curl wget nano htop ufw fail2ban unattended-upgrades auditd chrony

# ========== 5. Firewall (UFW) ==========
echo "🧱 Konfigurasi firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$CUSTOM_PORT"/tcp comment "SSH Custom"
ufw allow 80,443/tcp comment "HTTP/HTTPS"
ufw --force enable

# ========== 6. Aktifkan Fail2Ban ==========
systemctl enable --now fail2ban || true

# ========== 7. Timezone & auto update ==========
timedatectl set-timezone Asia/Jakarta
systemctl enable --now chrony
dpkg-reconfigure -f noninteractive unattended-upgrades

# ========== 8. Aktifkan sudo tanpa root password ==========
echo "$NEWUSER ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$NEWUSER
chmod 440 /etc/sudoers.d/90-$NEWUSER

# ========== 9. Restart SSH service ==========
echo "🔄 Merestart service SSH..."
systemctl restart ssh || systemctl reload ssh

# ========== 10. Pesan akhir ==========
IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=========================================="
echo "✅ Instalasi & Hardening Selesai!"
echo "  • User admin : $NEWUSER"
echo "  • Port SSH    : $CUSTOM_PORT"
echo "  • Firewall    : Aktif (UFW)"
echo "  • Fail2ban    : Aktif"
echo "  • Timezone    : Asia/Jakarta"
echo "=========================================="
echo "💡 Sekarang buka koneksi baru di MobaXterm:"
echo "   ssh -p $CUSTOM_PORT $NEWUSER@$IP"
echo "   (gunakan key yang tadi kamu masukkan)"
echo ""
echo "⚠️ JANGAN keluar dari sesi root sampai kamu bisa login dengan user baru!"
echo "=========================================="
