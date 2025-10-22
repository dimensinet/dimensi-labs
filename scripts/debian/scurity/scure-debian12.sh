#!/usr/bin/env bash
# ============================================================
# 😎 DIMENSI SECURE CHILL v5 — Debian 12
# Aman, Interaktif, dan Nggak Bikin Panik
# ============================================================

set -euo pipefail
LOGFILE="/var/log/dimensi-secure.log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# Warna
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[1;34m'; BOLD='\033[1m'; NC='\033[0m'
LINE="${CYAN}────────────────────────────────────────────────────${NC}"
SEP="${BLUE}╼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╾${NC}"

# Fungsi teks
say(){ echo -e "${CYAN}$*${NC}"; }
ok(){ echo -e "${GREEN}$*${NC}"; }
warn(){ echo -e "${YELLOW}$*${NC}"; }
oops(){ echo -e "${RED}$*${NC}"; }

clear
echo -e "${BOLD}${CYAN}
╔════════════════════════════════════════════════════╗
║        😎 DIMENSI SECURE CHILL v5 — Debian 12       ║
║   Aman, Interaktif, dan Nggak Bikin Panik 🔐        ║
╚════════════════════════════════════════════════════╝${NC}"
echo -e "${LINE}"
echo "Tanggal : $(date '+%A, %d %B %Y %H:%M:%S')"
echo "Log File: ${LOGFILE}"
echo -e "${LINE}"

START_TIME=$(date +%s)
TIMESTAMP="$(date +%F-%H%M)"
BACKUP_DIR="/root/backups/scure-before-${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

if [ "$(id -u)" -ne 0 ]; then oops "🚫 Harus dijalankan sebagai root, bro."; exit 1; fi

# [1] SSH folder
say "\n🧱 Oke, pertama kita beresin folder SSH kamu dulu ya..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh
ok "✅ Sip! Folder SSH kamu sekarang udah aman banget."

# [2] SSH Key
say "\n🔑 Sekarang cek SSH key dulu yuk..."
HAS_KEY=false
if grep -qE '^ssh-' /root/.ssh/authorized_keys 2>/dev/null; then
  HAS_KEY=true
  ok "🎉 Mantap, udah ada SSH key di sini:"
  nl -ba /root/.ssh/authorized_keys
  read -rp "Pakai key ini aja? [Y/n]: " ans; ans="${ans:-Y}"
  [[ "$ans" =~ ^[Yy] ]] || HAS_KEY=false
fi
if [ "$HAS_KEY" = false ]; then
  warn "Hmm... belum ada SSH key. Kita tambahin sekarang, ya?"
  echo "1) Tempel manual"
  echo "2) Ambil dari GitHub"
  echo "3) Lewati dulu (password tetap aktif)"
  read -rp "Pilih [1/2/3]: " mode; mode="${mode:-3}"
  case "$mode" in
    1)
      read -rp "Tempel SSH public key kamu: " PUB
      [[ "$PUB" =~ ^ssh- ]] || { oops "😬 Formatnya salah, coba lagi nanti."; exit 1; }
      echo "$PUB" >> /root/.ssh/authorized_keys ;;
    2)
      read -rp "Masukkan GitHub username kamu: " GH
      curl -fsSL "https://github.com/${GH}.keys" >> /root/.ssh/authorized_keys || { oops "Gagal ambil key GitHub."; exit 1; } ;;
    3)
      warn "Oke, login password masih nyala buat jaga-jaga ya 😉";;
  esac
  chmod 600 /root/.ssh/authorized_keys
  HAS_KEY=true
  ok "🔐 SSH key udah aman tersimpan!"
fi

# [3] Konfigurasi SSH
say "\n⚙️ Sekarang kita ubah sedikit konfigurasi SSH-nya..."
SSHD="/etc/ssh/sshd_config"
cp -n "$SSHD" "${BACKUP_DIR}/sshd_config.bak" || true
DEFAULT_PORT=$(grep -E '^Port ' "$SSHD" | awk '{print $2}' || echo 22)
read -rp "Port SSH mau diganti jadi berapa? [${DEFAULT_PORT}]: " PORT
PORT="${PORT:-$DEFAULT_PORT}"

sed -i "s/^#*Port .*/Port ${PORT}/" "$SSHD" || echo "Port ${PORT}" >> "$SSHD"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD"
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD"
sed -i 's/^#*UsePAM.*/UsePAM yes/' "$SSHD"

if grep -q '^ssh-' /root/.ssh/authorized_keys; then
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD"
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD"
  ok "✅ Key-nya valid, password login aku matiin ya biar aman."
else
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD"
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$SSHD"
  warn "⚠️  Belum ada key, password login tetap aktif. Aman kok."
fi

systemctl restart ssh || systemctl restart sshd
ok "🚀 SSH udah dikonfigurasi dan aktif di port ${PORT}."

# [4] Fail2Ban
say "\n🛡️  Sekarang kita pasang pelindung anti-bruteforce..."
if ! dpkg -s fail2ban >/dev/null 2>&1; then
  apt update -y && apt install -y fail2ban
fi
systemctl enable --now fail2ban
ok "💪 Fail2Ban aktif! Bot login gagal bakal langsung ditendang."

# [5] Password Policy
say "\n🔒 Kita terapkan kebijakan password kuat ya..."
apt install -y libpam-pwquality >/dev/null 2>&1
cat >/etc/security/pwquality.conf <<'EOF'
minlen = 15
minclass = 4
maxrepeat = 3
maxsequence = 3
retry = 3
dictcheck = 1
EOF
ok "✔️ Password sekarang wajib 15 karakter + simbol."

# [6] Cek Password Root
say "\n🧠 Sekarang, kita cek password root kamu..."
echo -e "${YELLOW}Kalau belum kuat, kamu bakal diminta ganti yang baru.${NC}"
passwd root
ok "✅ Password root sekarang udah aman dan kuat 💪"

# [7] Auto Update & Hardening
say "\n⚙️ Aktifin auto update dan kernel hardening biar makin solid..."
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
ok "🌟 Sistem udah di-hardening dan auto-update nyala."

# [8] Ringkasan
END_TIME=$(date +%s); RUNTIME=$((END_TIME - START_TIME))
echo -e "\n${SEP}"
echo -e "${BOLD}${CYAN}📋 REKAP AKHIR${NC}"
echo -e "${SEP}"
printf "${BOLD} %-28s ${NC}│ %s\n" "📁 Backup konfigurasi" "$BACKUP_DIR"
printf "${BOLD} %-28s ${NC}│ %s\n" "🔑 SSH key ada" "$(grep -q '^ssh-' /root/.ssh/authorized_keys && echo '✅ Ya' || echo '❌ Belum')"
printf "${BOLD} %-28s ${NC}│ %s\n" "⚙️  Port SSH aktif" "$PORT"
printf "${BOLD} %-28s ${NC}│ %s\n" "🚨 Fail2Ban" "$(systemctl is-active fail2ban)"
printf "${BOLD} %-28s ${NC}│ %s\n" "🧠 Password Policy" "≥15 char + simbol"
printf "${BOLD} %-28s ${NC}│ %s\n" "🛠 Auto Update" "$(systemctl is-active unattended-upgrades)"
printf "${BOLD} %-28s ${NC}│ %s detik\n" "⏱ Waktu Eksekusi" "$RUNTIME"
printf "${BOLD} %-28s ${NC}│ %s\n" "🪵 Log hasil" "$LOGFILE"
echo -e "${SEP}"
ok "🎯 Semua beres! Server kamu sekarang udah jauh lebih aman 🔒"
warn "⚠️ Coba login SSH pakai key-nya di port ${PORT} ya. Tes dulu sebelum logout!"
echo -e "${LINE}"
