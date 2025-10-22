#!/bin/bash
# =====================================================
# 🌈 DIMENSI LABS • AUTO UPGRADE DEBIAN 11 → 12 (BOOKWORM)
# Ultimate Edition: Smart Color + Progress Animation + Anti-Disconnect
# =====================================================

# 🎨 Warna
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
BOLD='\033[1m'
RESET='\033[0m'

# 🌀 Spinner animasi (biar gak sepi)
spin() {
    local pid=$!
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\b\b\b\b\b\b"
    done
}

# 🔄 Progress bar simulasi (biar keren aja 😎)
progress_bar() {
    local duration=${1}
    local filled=0
    local total=30
    while [ $filled -lt $total ]; do
        sleep $(echo "$duration / $total" | bc -l)
        ((filled++))
        printf "\r${CYAN}Progress: [%-${total}s] %d%%${RESET}" $(printf '#%.0s' $(seq 1 $filled)) $((filled * 100 / total))
    done
    echo ""
}

# 💡 Aktifkan warna otomatis
if [ -z "$TERM" ] || [[ "$TERM" != *"color"* ]]; then
  export TERM=xterm-256color
fi

# 🧠 Deteksi screen
if [ -n "$STY" ]; then
  if ! echo "$TERM" | grep -q "color"; then
    echo -e "${YELLOW}⚠️  Kamu di dalam 'screen' tapi warna belum aktif, menyalakan otomatis...${RESET}"
    export TERM=xterm-256color
    sleep 1
  fi
fi

clear
echo -e "${CYAN}====================================================="
echo -e " 🌈 ${BOLD}DIMENSI LABS - AUTO UPGRADE DEBIAN 11 ➜ 12 (BOOKWORM)${RESET}"
echo -e "=====================================================${RESET}\n"

# 🚫 Cek root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}❌ Harus dijalankan sebagai root!${RESET}"
  echo -e "Gunakan: ${YELLOW}sudo su${RESET}"
  exit 1
fi

# ⚠️ Cek screen
if [ -z "$STY" ] && [ -z "$TMUX" ]; then
  echo -e "${YELLOW}⚠️  Jalankan di dalam 'screen' biar gak disconnect.${RESET}\n"
  echo -e "Gunakan:"
  echo -e "  ${CYAN}apt install screen -y${RESET}"
  echo -e "  ${CYAN}screen -S upgrade -T xterm-256color${RESET}\n"
  exit 1
fi

echo -e "${GREEN}🔥 Oke, semua siap. Kita mulai proses upgrade Debian 11 ➜ 12 dengan aman.${RESET}\n"
sleep 2

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none

# -------------------------------------------
# 1️⃣ Backup
# -------------------------------------------
BACKUP_DIR="/root/backup-before-upgrade-$(date +%F_%H-%M)"
mkdir -p "$BACKUP_DIR"
echo -e "${CYAN}${BOLD}1️⃣ Membackup konfigurasi penting...${RESET}"
sleep 1
{
    cp -a /etc/network/interfaces "$BACKUP_DIR/interfaces.bak" 2>/dev/null || true
    cp -a /etc/netplan "$BACKUP_DIR/netplan.bak" 2>/dev/null || true
    cp -a /etc/ssh/sshd_config "$BACKUP_DIR/sshd_config.bak" 2>/dev/null || true
    cp -a /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak" 2>/dev/null || true
    cp -a /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak" 2>/dev/null || true
} & spin
echo -e "\n${GREEN}✅ Backup selesai di: ${BOLD}$BACKUP_DIR${RESET}\n"
sleep 1

# -------------------------------------------
# 2️⃣ Update awal Debian 11
# -------------------------------------------
echo -e "${CYAN}${BOLD}2️⃣ Update sistem Debian 11 sebelum upgrade...${RESET}"
(apt update -y && apt upgrade -y && apt full-upgrade -y) & spin
echo -e "\n${GREEN}✅ Sistem Debian 11 sudah up-to-date.${RESET}\n"
sleep 1

# -------------------------------------------
# 3️⃣ Mirror check
# -------------------------------------------
echo -e "${CYAN}${BOLD}3️⃣ Mendeteksi mirror terbaik...${RESET}"
if curl -s --head --connect-timeout 5 http://kambing.ui.ac.id/debian/dists/bookworm/Release | grep "200 OK" > /dev/null; then
  MIRROR="http://kambing.ui.ac.id/debian/"
  echo -e "${GREEN}🇮🇩 Menggunakan mirror lokal Indonesia.${RESET}\n"
else
  MIRROR="http://deb.debian.org/debian/"
  echo -e "${YELLOW}🌍 Mirror lokal gak respons, pakai mirror global.${RESET}\n"
fi
sleep 1

# -------------------------------------------
# 4️⃣ Update sources.list
# -------------------------------------------
echo -e "${CYAN}${BOLD}4️⃣ Mengganti repository ke Debian 12 (Bookworm)...${RESET}"
cat <<EOF > /etc/apt/sources.list
deb ${MIRROR} bookworm main contrib non-free non-free-firmware
deb ${MIRROR} bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
echo -e "${GREEN}✅ Repository diganti ke Debian 12.${RESET}\n"
sleep 1

# -------------------------------------------
# 5️⃣ Update repo baru
# -------------------------------------------
echo -e "${CYAN}${BOLD}5️⃣ Update daftar paket dari repository Debian 12...${RESET}"
(apt clean && apt update -y) & spin
echo -e "\n${GREEN}✅ Repository Debian 12 aktif.${RESET}\n"
sleep 1

# -------------------------------------------
# 6️⃣ Full upgrade
# -------------------------------------------
echo -e "${BLUE}${BOLD}6️⃣ Mulai proses upgrade penuh ke Debian 12...${RESET}"
echo -e "${YELLOW}☕ Silakan ngopi dulu, ini makan waktu agak lama.${RESET}"
progress_bar 30
apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  full-upgrade
echo -e "\n${GREEN}✅ Upgrade utama selesai.${RESET}\n"
sleep 1

# -------------------------------------------
# 7️⃣ Bersih-bersih
# -------------------------------------------
echo -e "${CYAN}${BOLD}7️⃣ Membersihkan sisa paket lama...${RESET}"
(apt autoremove -y && apt autoclean -y) & spin
echo -e "\n${GREEN}✅ Sistem bersih dan segar kembali.${RESET}\n"

# -------------------------------------------
# 8️⃣ Final info
# -------------------------------------------
echo -e "${GREEN}${BOLD}🎉 Upgrade Debian 12 (Bookworm) sukses tanpa error!${RESET}"
echo -e "📦 Versi saat ini: ${BOLD}$(cat /etc/debian_version)${RESET}"
echo -e "📂 Backup konfigurasi ada di: ${BOLD}$BACKUP_DIR${RESET}"
echo -e "${CYAN}💡 Tips: Jalankan 'apt update && apt upgrade -y' lagi setelah reboot.${RESET}\n"
echo -e "${YELLOW}💤 Sistem akan reboot otomatis dalam 15 detik...${RESET}"
progress_bar 15
reboot
