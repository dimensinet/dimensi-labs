#!/bin/bash
# ==========================================================
# SAFE UPGRADE DEBIAN 11 → 12 (BOOKWORM)
# No Screen • No SSH Disconnect • Auto Mirror Detect
# ==========================================================

# Pastikan root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Jalankan script ini sebagai root!"
  exit 1
fi

echo "🚀 Memulai upgrade Debian 11 → 12 (Bookworm) tanpa screen..."
sleep 2

# Non-interaktif penuh
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

# -------------------------------------------
# 1️⃣ Backup konfigurasi
# -------------------------------------------
BACKUP_DIR="/root/backup-before-upgrade-$(date +%F_%H-%M)"
mkdir -p "$BACKUP_DIR"

echo "📦 Membackup konfigurasi ke $BACKUP_DIR ..."
cp -a /etc/network/interfaces "$BACKUP_DIR/interfaces.bak" 2>/dev/null || true
cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true
cp -a /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak" 2>/dev/null || true
cp -a /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak" 2>/dev/null || true
echo "✅ Backup selesai."

# -------------------------------------------
# 2️⃣ Cegah SSH restart saat upgrade
# -------------------------------------------
echo "🛑 Menahan paket openssh agar tidak restart selama upgrade..."
apt-mark hold openssh-server openssh-client openssh-sftp-server

# -------------------------------------------
# 3️⃣ Update Debian 11 dulu
# -------------------------------------------
echo "🔹 Update sistem Debian 11..."
apt update -y && apt upgrade -y && apt full-upgrade -y

# -------------------------------------------
# 4️⃣ Deteksi mirror terbaik
# -------------------------------------------
echo "🌐 Mengecek koneksi mirror kambing.ui.ac.id..."
if curl -s --head --connect-timeout 5 http://kambing.ui.ac.id/debian/dists/bookworm/Release | grep "200 OK" > /dev/null; then
  MIRROR="http://kambing.ui.ac.id/debian/"
  echo "✅ Menggunakan mirror lokal Indonesia: $MIRROR"
else
  MIRROR="http://deb.debian.org/debian/"
  echo "⚠️ Mirror kambing.ui.ac.id tidak merespons, berpindah ke global mirror: $MIRROR"
fi
sleep 1

# -------------------------------------------
# 5️⃣ Ganti repository ke Debian 12
# -------------------------------------------
echo "🔹 Mengganti sources.list ke Debian 12..."
cat <<EOF > /etc/apt/sources.list
deb ${MIRROR} bookworm main contrib non-free non-free-firmware
deb ${MIRROR} bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# -------------------------------------------
# 6️⃣ Upgrade ke Debian 12
# -------------------------------------------
echo "🔹 Menjalankan full-upgrade ke Debian 12..."
apt clean
apt update -y
apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  full-upgrade

# -------------------------------------------
# 7️⃣ Lepas hold SSH & upgrade ulang
# -------------------------------------------
echo "🔓 Melepaskan hold SSH dan update ulang..."
apt-mark unhold openssh-server openssh-client openssh-sftp-server
apt install --reinstall openssh-server -y

# -------------------------------------------
# 8️⃣ Bersihkan & reboot
# -------------------------------------------
echo "🧹 Membersihkan paket lama..."
apt autoremove -y
apt autoclean -y

echo "✅ Upgrade selesai tanpa memutus SSH!"
echo "Versi Debian saat ini:"
cat /etc/debian_version
echo
echo "📂 Backup konfigurasi: $BACKUP_DIR"
echo "💡 Sistem akan reboot otomatis dalam 20 detik..."
sleep 20
reboot
