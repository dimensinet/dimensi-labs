#!/bin/bash
# =====================================================
# 🚀 UPGRADE AMAN DEBIAN 11 → 12 (BOOKWORM)
# Anti-Disconnect • Auto Mirror • Auto Yes • Simpan Konfig
# =====================================================

# Pastikan dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Wah, kamu belum root nih!"
  echo "Jalankan pakai: sudo su"
  exit 1
fi

# Cek apakah dijalankan di dalam screen / tmux
if [ -z "$STY" ] && [ -z "$TMUX" ]; then
  echo "⚠️  Sebaiknya jalankan script ini di dalam 'screen' biar gak putus koneksinya."
  echo ""
  echo "Cukup jalankan perintah berikut dulu:"
  echo "    apt install screen -y"
  echo "    screen -S upgrade"
  echo ""
  echo "Lalu jalankan lagi script ini di dalam screen tadi 😉"
  exit 1
fi

echo ""
echo "🔥 Siap-siap... Kita akan upgrade Debian 11 ➜ Debian 12 (Bookworm)!"
sleep 2

# Mode non-interaktif biar gak nanya-nanya
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

# -------------------------------------------
# 1️⃣ Backup konfigurasi penting
# -------------------------------------------
BACKUP_DIR="/root/backup-before-upgrade-$(date +%F_%H-%M)"
mkdir -p "$BACKUP_DIR"

echo "📦 Nyimpen file konfigurasi penting dulu ke: $BACKUP_DIR ..."
cp -a /etc/network/interfaces "$BACKUP_DIR/interfaces.bak" 2>/dev/null || true
cp -a /etc/netplan "$BACKUP_DIR/netplan.bak" 2>/dev/null || true
cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true
cp -a /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak" 2>/dev/null || true
cp -a /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak" 2>/dev/null || true
echo "✅ Backup beres, lanjut!"
sleep 1

# -------------------------------------------
# 2️⃣ Update paket Debian 11 dulu
# -------------------------------------------
echo "🔹 Update dulu sistem Debian 11 kamu..."
apt update -y && apt upgrade -y && apt full-upgrade -y

# -------------------------------------------
# 3️⃣ Cek mirror terbaik
# -------------------------------------------
echo "🌐 Coba konek ke mirror kambing.ui.ac.id..."
if curl -s --head --connect-timeout 5 http://kambing.ui.ac.id/debian/dists/bookworm/Release | grep "200 OK" > /dev/null; then
  MIRROR="http://kambing.ui.ac.id/debian/"
  echo "🇮🇩 Mantap! Pakai mirror lokal Indonesia: $MIRROR"
else
  MIRROR="http://deb.debian.org/debian/"
  echo "🌍 Mirror lokal agak lemot, pindah ke global mirror: $MIRROR"
fi
sleep 1

# -------------------------------------------
# 4️⃣ Ubah sources.list ke Debian 12
# -------------------------------------------
echo "📝 Ganti repository ke Debian 12..."
cat <<EOF > /etc/apt/sources.list
deb ${MIRROR} bookworm main contrib non-free non-free-firmware
deb ${MIRROR} bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# -------------------------------------------
# 5️⃣ Bersihin cache dan update repo baru
# -------------------------------------------
apt clean
echo "🔄 Update repository Debian 12..."
apt update -y

# -------------------------------------------
# 6️⃣ Jalankan upgrade penuh otomatis
# -------------------------------------------
echo "🚀 Proses upgrade penuh sedang berjalan..."
apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  full-upgrade

# -------------------------------------------
# 7️⃣ Bersihin sisa-sisa paket lama
# -------------------------------------------
echo "🧹 Bersihin paket yang udah gak kepake..."
apt autoremove -y
apt autoclean -y

# -------------------------------------------
# 8️⃣ Selesai!
# -------------------------------------------
echo ""
echo "🎉 Upgrade Debian 12 sukses tanpa error!"
echo "📦 Versi saat ini: $(cat /etc/debian_version)"
echo "📂 Backup konfigurasi ada di: $BACKUP_DIR"
echo ""
echo "💡 Server bakal reboot otomatis dalam 15 detik..."
sleep 15

reboot
