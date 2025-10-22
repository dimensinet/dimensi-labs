#!/bin/bash
# ===========================================
# AUTO UPGRADE DEBIAN 11 → 12 (BOOKWORM)
# Non-interaktif • Keep Local Config • Auto Reboot
# ===========================================

# Pastikan dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Jalankan script ini sebagai root!"
  exit 1
fi

echo "🚀 Memulai proses upgrade Debian 11 → Debian 12 (Bookworm)..."
sleep 2

# Mode non-interaktif agar tidak ada prompt YES/NO
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

# -------------------------------------------
# 1. Update sistem awal (masih Debian 11)
# -------------------------------------------
echo "🔹 Update & upgrade paket Debian 11..."
apt update -y && apt upgrade -y && apt full-upgrade -y

# -------------------------------------------
# 2. Ganti repository ke Debian 12 (Bookworm)
# -------------------------------------------
echo "🔹 Mengganti repository ke Debian 12..."
cat <<'EOF' > /etc/apt/sources.list
deb http://kambing.ui.ac.id/debian/ bookworm main contrib non-free non-free-firmware
deb http://kambing.ui.ac.id/debian/ bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# -------------------------------------------
# 3. Update repository baru & upgrade
# -------------------------------------------
echo "🔹 Membersihkan cache APT..."
apt clean
echo "🔹 Update repository Debian 12..."
apt update -y

echo "🔹 Menjalankan dist-upgrade penuh..."
apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade

# -------------------------------------------
# 4. Bersihkan sistem setelah upgrade
# -------------------------------------------
echo "🔹 Membersihkan paket lama..."
apt autoremove -y
apt autoclean -y

# -------------------------------------------
# 5. Cek versi dan reboot otomatis
# -------------------------------------------
echo "✅ Upgrade selesai!"
echo "Versi Debian saat ini:"
cat /etc/debian_version
echo
echo "💡 Sistem akan reboot otomatis dalam 10 detik..."
sleep 10

reboot
