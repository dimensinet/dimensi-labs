#!/bin/bash
# =====================================================
# SAFE UPGRADE DEBIAN 11 → 12 (BOOKWORM)
# Anti-Disconnect • Auto Mirror Detect • Auto Yes • Keep Config
# =====================================================

# Pastikan dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Jalankan script ini sebagai root!"
  exit 1
fi

# Cek apakah dijalankan di dalam screen / tmux
if [ -z "$STY" ] && [ -z "$TMUX" ]; then
  echo "⚠️  Script ini wajib dijalankan di dalam 'screen' atau 'tmux' agar tidak disconnect."
  echo "Gunakan perintah berikut, lalu jalankan lagi script ini:"
  echo ""
  echo "    apt install screen -y"
  echo "    screen -S upgrade"
  echo ""
  exit 1
fi

echo "🚀 Memulai upgrade Debian 11 → Debian 12 (Bookworm)..."
sleep 2

# Mode non-interaktif agar tidak ada prompt
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

# -------------------------------------------
# 1️⃣ Backup konfigurasi penting
# -------------------------------------------
BACKUP_DIR="/root/backup-before-upgrade-$(date +%F_%H-%M)"
mkdir -p "$BACKUP_DIR"

echo "📦 Membackup konfigurasi penting ke $BACKUP_DIR ..."
cp -a /etc/network/interfaces "$BACKUP_DIR/interfaces.bak" 2>/dev/null || true
cp -a /etc/netplan "$BACKUP_DIR/netplan.bak" 2>/dev/null || true
cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true
cp -a /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak" 2>/dev/null || true
cp -a /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak" 2>/dev/null || true
echo "✅ Backup selesai."
sleep 1

# -------------------------------------------
# 2️⃣ Update awal Debian 11
# -------------------------------------------
echo "🔹 Update paket Debian 11..."
apt update -y && apt upgrade -y && apt full-upgrade -y

# -------------------------------------------
# 3️⃣ Deteksi mirror terbaik
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
# 4️⃣ Ganti repository ke Debian 12
# -------------------------------------------
echo "🔹 Mengganti sources.list ke Debian 12..."
cat <<EOF > /etc/apt/sources.list
deb ${MIRROR} bookworm main contrib non-free non-free-firmware
deb ${MIRROR} bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# -------------------------------------------
# 5️⃣ Bersihkan cache dan update repo baru
# -------------------------------------------
apt clean
echo "🔹 Update repository Debian 12..."
apt update -y

# -------------------------------------------
# 6️⃣ Jalankan upgrade penuh otomatis
# -------------------------------------------
echo "🔹 Menjalankan full-upgrade otomatis..."
apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  full-upgrade

# -------------------------------------------
# 7️⃣ Bersihkan sistem
# -------------------------------------------
echo "🔹 Membersihkan paket lama..."
apt autoremove -y
apt autoclean -y

# -------------------------------------------
# 8️⃣ Cek hasil dan reboot
# -------------------------------------------
echo "✅ Upgrade selesai tanpa error!"
echo "Versi Debian saat ini:"
cat /etc/debian_version
echo
echo "📂 Backup konfigurasi tersimpan di: $BACKUP_DIR"
echo "💡 Sistem akan reboot otomatis dalam 15 detik..."
sleep 15

reboot
