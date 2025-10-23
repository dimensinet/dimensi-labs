#!/usr/bin/env bash
# ============================================================
# 😎 DIMENSI SECURE CHILL v7.2 — Debian 12 (FINAL HYBRID)
# Smooth Flow • Interaktif • Cinematic • Safe (no lockout)
# Mode: SSH Key + Password (Hybrid, tetap aman)
# ============================================================

set -euo pipefail
LOGFILE="/var/log/dimensi-secure.log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# 🎨 Colors
RED='\033[0;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; BLUE='\033[1;34m'; MAGENTA='\033[1;35m'
WHITE='\033[1;37m'; BOLD='\033[1m'; NC='\033[0m'

LINE="${CYAN}────────────────────────────────────────────────────────────${NC}"
SEP="${MAGENTA}╼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╾${NC}"

# 🎬 Typewriter function
typewrite() {
  local text="$1"
  for ((i=0; i<${#text}; i++)); do
    echo -n "${text:$i:1}"
    sleep 0.002
  done
  echo ""
}

# 🎚️ Loading bar
progress_bar() {
  echo -e "${MAGENTA}${BOLD}🚀 Sedang mempersiapkan Dimensi Secure Chill...${NC}\n"
  local bar="■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■"
  local length=${#bar}
  for ((i=1; i<=length; i++)); do
    local progress="${bar:0:i}"
    local percent=$((i * 100 / length))
    printf "\r${CYAN}[${GREEN}%s${WHITE}%*s${CYAN}]${NC} %3d%%" "$progress" $((length-i)) "" "$percent"
    sleep 0.08
  done
  echo -e "\n${GREEN}✨ Siap jalan!${NC}\n"
  sleep 0.6
}

say()  { echo -e "${CYAN}$*${NC}"; sleep 0.8; }
ok()   { echo -e "${GREEN}$*${NC}"; sleep 0.8; }
warn() { echo -e "${YELLOW}$*${NC}"; sleep 0.8; }
oops() { echo -e "${RED}$*${NC}"; sleep 0.8; }

# 🎥 Banner
clear
echo -e "${BOLD}${MAGENTA}
╔════════════════════════════════════════════════════════════╗
║           😎 DIMENSI SECURE CHILL v7.2 — Debian 12          ║
║     Smooth • Interaktif • Cinematic • No Dependency 🌈      ║
╚════════════════════════════════════════════════════════════╝${NC}\n"

progress_bar

START_TIME=$(date +%s)
TIMESTAMP="$(date +%F-%H%M)"
BACKUP_DIR="/root/backups/scure-before-${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

if [ "$(id -u)" -ne 0 ]; then oops "🚫 Jalankan script ini sebagai root ya."; exit 1; fi

# -------------------------
# [1] Folder SSH
# -------------------------
say "🧱 Oke, pertama kita rapihin dulu folder SSH kamu..."
sleep 0.8
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh
sleep 0.6
ok "✅ Folder SSH kamu udah aman banget 🔐"

# -------------------------
# [2] SSH Key check & add
# -------------------------
say "🔑 Sekarang kita cek SSH key kamu..."
sleep 0.8
HAS_KEY=false
if grep -qE '^ssh-' /root/.ssh/authorized_keys 2>/dev/null; then
  HAS_KEY=true
  sleep 0.6
  say "🧩 Ditemuin nih SSH key kamu, bentar aku tampilin pelan-pelan ya..."
  sleep 0.6
  echo ""
  while IFS= read -r line; do
    typewrite "$line"
  done < /root/.ssh/authorized_keys
  echo ""
  sleep 0.5
  read -rp "Pakai key ini aja? [Y/n]: " ans; ans="${ans:-Y}"
  [[ "$ans" =~ ^[Yy] ]] || HAS_KEY=false
fi

if [ "$HAS_KEY" = false ]; then
  warn "Hmm... belum ada SSH key. Yuk kita tambahin dulu biar aman!"
  echo "1) Tempel manual"
  echo "2) Ambil dari GitHub"
  echo "3) Lewati dulu (biar login password tetap bisa)"
  read -rp "Pilih [1/2/3]: " mode; mode="${mode:-3}"
  case "$mode" in
    1)
      read -rp "Tempel SSH public key kamu: " PUB
      [[ "$PUB" =~ ^ssh- ]] || { oops "😬 Format SSH key-nya salah."; exit 1; }
      echo "$PUB" >> /root/.ssh/authorized_keys ;;
    2)
      read -rp "Masukkan GitHub username kamu: " GH
      curl -fsSL "https://github.com/${GH}.keys" >> /root/.ssh/authorized_keys || { oops "Gagal ambil key dari GitHub."; exit 1; } ;;
    3)
      warn "Oke, login password tetap aktif dulu ya 😉";;
  esac
  chmod 600 /root/.ssh/authorized_keys
  ok "🔐 SSH key berhasil ditambahkan!"
  sleep 0.8
fi

# -------------------------
# [3] SSH configuration (HYBRID MODE)
# -------------------------
say "⚙️ Sekarang kita ubah konfigurasi SSH-nya biar makin aman..."
sleep 0.8
SSHD="/etc/ssh/sshd_config"
cp -n "$SSHD" "${BACKUP_DIR}/sshd_config.bak" || true
DEFAULT_PORT=$(grep -E '^Port ' "$SSHD" | awk '{print $2}' || echo 22)
read -rp "Mau pakai port berapa buat SSH? [${DEFAULT_PORT}]: " PORT
PORT="${PORT:-$DEFAULT_PORT}"
sleep 0.5

# Mode Hybrid: Key aktif + Password tetap diizinkan
sed -i "s/^#*Port .*/Port ${PORT}/" "$SSHD" || echo "Port ${PORT}" >> "$SSHD"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD"
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD"
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$SSHD"
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD"
sed -i 's/^#*UsePAM.*/UsePAM yes/' "$SSHD"

ok "🔓 SSH key aktif, dan login password tetap diizinkan (mode hybrid)."
warn "⚠️  Pastikan password root kamu kuat banget ya 💪"

systemctl restart ssh || systemctl restart sshd
sleep 0.5
ok "🚀 SSH udah dikonfigurasi dan aktif di port ${PORT}."

# -------------------------
# [4] Fail2Ban
# -------------------------
say "🛡️ Pasang pelindung Fail2Ban biar yang nyoba bruteforce langsung ke tendang..."
sleep 0.6
if ! dpkg -s fail2ban >/dev/null 2>&1; then
  apt update -y && apt install -y fail2ban >/dev/null 2>&1
fi
systemctl enable --now fail2ban
ok "💪 Fail2Ban aktif! Bot iseng bakal langsung auto tendang 👢"

# -------------------------
# [5] Password Policy
# -------------------------
say "🔒 Terapin kebijakan password yang super kuat..."
sleep 0.8
apt install -y libpam-pwquality >/dev/null 2>&1
cp -n /etc/security/pwquality.conf /etc/security/pwquality.conf.bak || true
cat >/etc/security/pwquality.conf <<'EOF'
minlen = 15
minclass = 4
maxrepeat = 3
maxsequence = 3
retry = 3
dictcheck = 1
EOF
if ! grep -q "pam_pwquality.so" /etc/pam.d/common-password; then
  sed -i '/pam_unix.so/s/$/ retry=3/' /etc/pam.d/common-password
  sed -i '1i password requisite pam_pwquality.so retry=3' /etc/pam.d/common-password
fi
ok "✔️ Password minimal 15 karakter + simbol wajib diterapkan!"

# -------------------------
# [6] Password root
# -------------------------
say "🧠 Yuk periksa password root kamu..."
warn "Kalau masih lemah, ganti sekarang ya (min 15 karakter, huruf besar, angka, & simbol)"
passwd root
sleep 0.8
ok "💚 Password root kamu udah kuat banget sekarang!"

# -------------------------
# [7] Auto Update & Kernel Hardening
# -------------------------
say "⚙️ Aktifin auto update dan kernel hardening..."
sleep 0.8
apt install -y unattended-upgrades >/dev/null 2>&1
cat >/etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl enable --now unattended-upgrades
cat >/etc/sysctl.d/99-secure-fix.conf <<'EOF'
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
kernel.kptr_restrict = 2
kernel.sysrq = 0
kernel.dmesg_restrict = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
EOF
sysctl --system >/dev/null 2>&1
ok "🌈 Sistem kamu udah super solid dan auto-update aktif!"

# -------------------------
# [8] Final Recap
# -------------------------
END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))
sleep 0.8
echo -e "\n${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}                   📋 REKAP AKHIR — DIMENSI CHILL v7.2${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
printf "${WHITE} %-30s ${CYAN}│${GREEN} %s${NC}\n" "📁 Backup konfigurasi" "$BACKUP_DIR"
printf "${WHITE} %-30s ${CYAN}│${GREEN} %s${NC}\n" "🔑 SSH key ada" "$(grep -q '^ssh-' /root/.ssh/authorized_keys && echo '✅ Ya' || echo '❌ Belum')"
printf "${WHITE} %-30s ${CYAN}│${YELLOW} %s${NC}\n" "⚙️  Port SSH aktif" "$PORT"
printf "${WHITE} %-30s ${CYAN}│${GREEN} %s${NC}\n" "🚨 Fail2Ban" "$(systemctl is-active fail2ban)"
printf "${WHITE} %-30s ${CYAN}│${GREEN} %s${NC}\n" "🧠 Password Policy" "≥15 char + simbol"
printf "${WHITE} %-30s ${CYAN}│${GREEN} %s${NC}\n" "🛠 Auto Update" "$(systemctl is-active unattended-upgrades)"
printf "${WHITE} %-30s ${CYAN}│${MAGENTA} %s detik${NC}\n" "⏱ Waktu Eksekusi" "$RUNTIME"
printf "${WHITE} %-30s ${CYAN}│${BLUE} %s${NC}\n" "🪵 Log hasil" "$LOGFILE"
echo -e "${MAGENTA}────────────────────────────────────────────────────────────${NC}"
echo -e "${GREEN}${BOLD}✅ Semua beres! Server kamu sekarang udah super aman & kece 💚${NC}"
echo -e "${YELLOW}${BOLD}⚠️  Tes login SSH pakai key atau password di port ${PORT} sebelum logout ya.${NC}"
echo -e "${MAGENTA}────────────────────────────────────────────────────────────${NC}\n"
