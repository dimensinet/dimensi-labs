#!/usr/bin/env bash
# ============================================================
# 🔐 DIMENSI SECURE PRO v4 — Debian 12 (Safe Edition)
# Anti-lockout • Strong Password Policy • Fail2Ban • Hardening
# ============================================================

set -euo pipefail
LOGFILE="/var/log/dimensi-secure.log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[1;34m'; BOLD='\033[1m'; NC='\033[0m'
LINE="${CYAN}────────────────────────────────────────────────────────────${NC}"
SEP="${BLUE}╼━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╾${NC}"
# ────────────────────────────────────────────────────────────────

progress(){ local msg=$1; echo -ne "${CYAN}$msg${NC}"; for i in {1..3}; do echo -ne "."; sleep 0.4; done; echo ""; }
ok(){ echo -e "${GREEN}$*${NC}"; }
warn(){ echo -e "${YELLOW}$*${NC}"; }
err(){ echo -e "${RED}$*${NC}"; }

clear
echo -e "${BOLD}${CYAN}
╔════════════════════════════════════════════════════════════╗
║          🔐 DIMENSI SECURE PRO v4 — Debian 12 (Safe)         ║
║  Aman dari lockout • Password kuat • Fail2Ban • Logging     ║
╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${LINE}"
echo "Tanggal : $(date '+%A, %d %B %Y %H:%M:%S')"
echo "Log File: ${LOGFILE}"
echo -e "${LINE}"

START_TIME=$(date +%s)
TIMESTAMP="$(date +%F-%H%M)"
BACKUP_DIR="/root/backups/scure-before-${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

if [ "$(id -u)" -ne 0 ]; then err "❌ Jalankan sebagai root."; exit 1; fi

# [1] SSH folder
echo -e "\n${BLUE}🔹 [1/7] Memeriksa folder SSH root...${NC}"
progress "Menyiapkan direktori SSH"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh
ok "✔ Permission SSH aman."

# [2] SSH Key check
echo -e "\n${BLUE}🔹 [2/7] Pemeriksaan SSH key...${NC}"
HAS_KEY=false
if grep -qE '^ssh-' /root/.ssh/authorized_keys 2>/dev/null; then
  HAS_KEY=true
  warn "Ditemukan SSH key di /root/.ssh/authorized_keys:"
  nl -ba /root/.ssh/authorized_keys
  read -rp "Gunakan key ini? [Y/n]: " ans; ans="${ans:-Y}"
  [[ "$ans" =~ ^[Yy] ]] || HAS_KEY=false
fi
if [ "$HAS_KEY" = false ]; then
  echo -e "${YELLOW}Tidak ada key valid.${NC}"
  echo "1) Paste manual"
  echo "2) Ambil dari GitHub username"
  echo "3) Lewati (login password tetap aktif)"
  read -rp "Pilih [1/2/3]: " mode; mode="${mode:-3}"
  case "$mode" in
    1)
      read -rp "Masukkan SSH public key: " PUB
      [[ "$PUB" =~ ^ssh- ]] || { err "❌ Format key tidak valid."; exit 1; }
      echo "$PUB" >> /root/.ssh/authorized_keys ;;
    2)
      read -rp "Masukkan GitHub username: " GH
      curl -fsSL "https://github.com/${GH}.keys" >> /root/.ssh/authorized_keys || { err "Gagal ambil key."; exit 1; } ;;
    3) warn "➡️  Melewati. Password login akan tetap diaktifkan."; ;;
  esac
  chmod 600 /root/.ssh/authorized_keys
  HAS_KEY=true
  ok "✔ SSH key berhasil ditambahkan."
fi

# [3] Konfigurasi SSH
echo -e "\n${BLUE}🔹 [3/7] Konfigurasi SSH...${NC}"
SSHD="/etc/ssh/sshd_config"
cp -n "$SSHD" "${BACKUP_DIR}/sshd_config.bak" || true
DEFAULT_PORT=$(grep -E '^Port ' "$SSHD" | awk '{print $2}' || echo 22)
read -rp "Masukkan port SSH baru [${DEFAULT_PORT}] (Enter = default): " PORT
PORT="${PORT:-$DEFAULT_PORT}"
[[ "$PORT" =~ ^[0-9]+$ ]] || { err "Port tidak valid."; exit 1; }

sed -i "s/^#*Port .*/Port ${PORT}/" "$SSHD" || echo "Port ${PORT}" >> "$SSHD"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD"
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD"
sed -i 's/^#*UsePAM.*/UsePAM yes/' "$SSHD"

if grep -q '^ssh-' /root/.ssh/authorized_keys; then
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD"
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD"
  ok "✔ Key ditemukan, login password dinonaktifkan."
else
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD"
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$SSHD"
  warn "⚠️  Key tidak valid, password login tetap aktif (aman sementara)."
fi

systemctl restart ssh || systemctl restart sshd
ok "✔ SSH dikonfigurasi & aktif di port ${PORT}"

# [4] Fail2Ban
echo -e "\n${BLUE}🔹 [4/7] Mengaktifkan Fail2Ban...${NC}"
progress "Memeriksa paket Fail2Ban"
if ! dpkg -s fail2ban >/dev/null 2>&1; then apt update -y && apt install -y fail2ban; fi
systemctl enable --now fail2ban
ok "✔ Fail2Ban aktif."

# [5] Password Policy
echo -e "\n${BLUE}🔹 [5/7] Kebijakan Password Kuat...${NC}"
progress "Menerapkan pwquality"
apt install -y libpam-pwquality >/dev/null 2>&1
cp -n /etc/security/pwquality.conf /etc/security/pwquality.conf.bak || true
cat >/etc/security/pwquality.conf <<'EOF'
# Dimensi Labs — Password Policy
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
ok "✔ Password minimal 15 karakter + simbol wajib diterapkan."

# [6] Auto Update + Hardening
echo -e "\n${BLUE}🔹 [6/7] Auto Security Update & Hardening...${NC}"
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
ok "✔ Auto update & kernel hardening aktif."

# [7] Ringkasan
END_TIME=$(date +%s); RUNTIME=$((END_TIME - START_TIME))
echo -e "\n${SEP}"
echo -e "${BOLD}${CYAN}📋 RINGKASAN HASIL AKHIR${NC}"
echo -e "${SEP}"
printf "${BOLD} %-32s ${NC}│ %s\n" "📁 Backup konfigurasi" "$BACKUP_DIR"
printf "${BOLD} %-32s ${NC}│ %s\n" "🔑 SSH key ditemukan" "$(grep -q '^ssh-' /root/.ssh/authorized_keys && echo 'Ya' || echo 'Tidak')"
printf "${BOLD} %-32s ${NC}│ %s\n" "⚙️  Port SSH aktif" "$PORT"
printf "${BOLD} %-32s ${NC}│ %s\n" "🔐 Mode Login" "$(grep -q '^ssh-' /root/.ssh/authorized_keys && echo 'Key-only' || echo 'Password+Key')"
printf "${BOLD} %-32s ${NC}│ %s\n" "🚨 Fail2Ban" "$(systemctl is-active fail2ban)"
printf "${BOLD} %-32s ${NC}│ %s\n" "🧠 Password Policy" "≥15 char + simbol"
printf "${BOLD} %-32s ${NC}│ %s\n" "🛠 Auto Update" "$(systemctl is-active unattended-upgrades)"
printf "${BOLD} %-32s ${NC}│ %s detik\n" "⏱ Waktu Eksekusi" "$RUNTIME"
printf "${BOLD} %-32s ${NC}│ %s\n" "🪵 Log hasil" "$LOGFILE"
echo -e "${SEP}"
ok "🎯 Semua langkah keamanan selesai dengan sukses!"
warn "⚠️  Uji login SSH key sekarang. Gunakan port ${PORT}."
echo -e "${LINE}"
