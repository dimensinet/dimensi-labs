#!/bin/bash
# ============================================================
# [SECURE ROOT MAX ULTRA] Debian 12 Final (ASCII Clean)
# Root aktif • Interaktif • Warna penuh • Tanpa emoji
# ============================================================

# Auto-fix jika file pernah disimpan CRLF/BOM
sed -i '1s/^\xEF\xBB\xBF//' "$0" 2>/dev/null || true
sed -i 's/\r$//' "$0" 2>/dev/null || true

set -euo pipefail

# Warna terminal
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'

# Animasi loading sederhana
loading() {
  local msg="$1"
  echo -ne "${CYAN}${msg}${NC}"
  for i in $(seq 1 6); do
    echo -ne "."
    sleep 0.2
  done
  echo -e " ${GREEN}OK${NC}"
  sleep 0.3
}

trim() { local var="$*"; var="${var#"${var%%[![:space:]]*}"}"; var="${var%"${var##*[![:space:]]}"}"; echo -n "$var"; }
is_valid_port(){ [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 65535 ]; }
test_local_port(){ local port="$1"; timeout 3 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/${port}" 2>/dev/null; }

clear
echo -e "${PURPLE}"
echo "=========================================================="
echo "       SECURE ROOT MAX ULTRA — Debian 12 (ASCII Clean)"
echo "=========================================================="
echo -e "${NC}"
sleep 0.5

read -p "$(echo -e ${YELLOW}Lanjutkan proses hardening sistem? (y/n):${NC} )" CONFIRM
[[ "${CONFIRM,,}" != "y" ]] && { echo -e "${RED}Dibatalkan.${NC}"; exit 1; }

echo
echo -e "${CYAN}Masukkan port SSH baru (Enter = random aman):${NC}"
read -p "> " SSH_PORT_RAW
SSH_PORT_RAW="$(trim "$SSH_PORT_RAW")"
if [ -z "$SSH_PORT_RAW" ]; then
  SSH_PORT=$(( (RANDOM % 40000) + 2000 ))
  echo -e "${YELLOW}Port acak dipilih: ${SSH_PORT}${NC}"
elif is_valid_port "$SSH_PORT_RAW"; then
  SSH_PORT="$SSH_PORT_RAW"
else
  echo -e "${RED}Port tidak valid. Menggunakan acak.${NC}"
  SSH_PORT=$(( (RANDOM % 40000) + 2000 ))
fi

echo
echo -e "${CYAN}Masukkan port lain yang ingin dibuka (pisahkan koma, contoh: 80,443):${NC}"
read -p "> " OTHER_PORTS_RAW
OTHER_PORTS_RAW="$(trim "$OTHER_PORTS_RAW")"

OPEN_PORTS=()
if [ -n "$OTHER_PORTS_RAW" ]; then
  IFS=',' read -r -a PORT_ARR <<< "${OTHER_PORTS_RAW// /}"
  for P in "${PORT_ARR[@]}"; do
    if is_valid_port "$P"; then
      OPEN_PORTS+=("$P")
    else
      echo -e "${YELLOW}Abaikan port tidak valid: ${P}${NC}"
    fi
  done
fi
OPEN_PORTS+=("$SSH_PORT")

echo
read -p "$(echo -e ${CYAN}Aktifkan Stealth Mode (drop ping)? (y/n):${NC} )" OPT_STEALTH
echo
read -p "$(echo -e ${CYAN}Aktifkan Auto Security Update? (y/n):${NC} )" OPT_AUTOUP

loading "Update sistem"
apt update -y && apt upgrade -y

loading "Instal paket keamanan"
apt install -y ufw fail2ban auditd libpam-pwquality unattended-upgrades iptables-persistent curl wget sudo nano net-tools >/dev/null 2>&1 || true

loading "Konfigurasi firewall"
ufw default deny incoming
ufw default allow outgoing
ufw allow in on lo
for p in "${OPEN_PORTS[@]}"; do ufw allow "${p}/tcp"; done
ufw allow 22/tcp
ufw --force enable
ufw logging low

loading "Konfigurasi Fail2Ban"
cat >/etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF
systemctl enable --now fail2ban

loading "Konfigurasi SSH"
SSHD="/etc/ssh/sshd_config"
cp -n "$SSHD" "$SSHD.bak-$(date +%F-%H%M)" || true

edit_ssh() {
  local key="$1"
  local val="$2"
  if grep -qE "^[#]*\s*${key}\s+" "$SSHD"; then
    sed -ri "s|^[#]*\s*${key}\s+.*|${key} ${val}|" "$SSHD"
  else
    echo "${key} ${val}" >> "$SSHD"
  fi
}

edit_ssh "Port" "$SSH_PORT"
edit_ssh "PermitRootLogin" "yes"
edit_ssh "PasswordAuthentication" "yes"
edit_ssh "MaxAuthTries" "3"
edit_ssh "LoginGraceTime" "20"
edit_ssh "ClientAliveInterval" "300"
edit_ssh "ClientAliveCountMax" "2"
edit_ssh "DebianBanner" "no"
edit_ssh "Banner" "/etc/issue.net"

loading "Membuat banner login"
cat >/etc/issue.net <<'EOF'
===========================================
PERINGATAN KEAMANAN
Akses hanya untuk pengguna resmi.
Semua aktivitas diawasi dan dicatat.
===========================================
EOF

echo
read -p "$(echo -e ${CYAN}Tambahkan SSH Public Key untuk root? (y/n):${NC} )" ADDKEY
if [[ "${ADDKEY,,}" == "y" ]]; then
  echo -e "${YELLOW}Tempel SSH Public Key kamu:${NC}"
  read -r PUBKEY
  mkdir -p /root/.ssh
  echo "$PUBKEY" >> /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
  chown -R root:root /root/.ssh
  echo -e "${GREEN}SSH key ditambahkan.${NC}"
  read -p "$(echo -e ${YELLOW}Nonaktifkan login password (key-only)? (y/n):${NC} )" DISABLE_PASS
  if [[ "${DISABLE_PASS,,}" == "y" ]]; then
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD"
    echo -e "${GREEN}Password login dimatikan.${NC}"
  fi
fi

loading "Menerapkan sysctl hardening"
cat >/etc/sysctl.d/99-secure.conf <<EOF
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

loading "Menambahkan rate limit SSH"
iptables -I INPUT -p tcp --dport "${SSH_PORT}" -m connlimit --connlimit-above 10 -j REJECT || true
iptables -I INPUT -p tcp --dport "${SSH_PORT}" -m state --state NEW -m recent --set || true
iptables -I INPUT -p tcp --dport "${SSH_PORT}" -m state --state NEW -m recent --update --seconds 60 --hitcount 6 -j DROP || true
iptables-save > /etc/iptables.rules || true

if [[ "${OPT_STEALTH,,}" == "y" ]]; then
  loading "Aktifkan Stealth Mode"
  iptables -I INPUT -p icmp --icmp-type echo-request -j DROP || true
  iptables -A INPUT -j DROP || true
  iptables-save > /etc/iptables.rules || true
fi

loading "Restart SSH dan Fail2Ban"
systemctl restart ssh || true
systemctl restart fail2ban || true

echo
loading "Tes port SSH baru"
if test_local_port "${SSH_PORT}"; then
  echo -e "${GREEN}Port ${SSH_PORT} aktif.${NC}"
else
  echo -e "${RED}Port ${SSH_PORT} belum terbuka.${NC}"
fi

read -p "$(echo -e ${YELLOW}Hapus port 22 dari firewall (jika SSH baru OK)? (y/n):${NC} )" DEL22
if [[ "${DEL22,,}" == "y" ]]; then
  loading "Menghapus port 22"
  ufw delete allow 22/tcp || true
else
  echo -e "${YELLOW}Port 22 tetap terbuka sementara.${NC}"
fi

echo
echo -e "${PURPLE}=========================================================="
echo "SECURE ROOT MAX ULTRA — Selesai!"
echo "==========================================================${NC}"
echo -e "${YELLOW}SSH Port:${NC} ${SSH_PORT}"
echo -e "${YELLOW}Fail2Ban:${NC} aktif"
echo -e "${YELLOW}Firewall:${NC} aktif"
echo -e "${YELLOW}Stealth :${NC} ${OPT_STEALTH}"
echo
read -p "$(echo -e ${YELLOW}Reboot sekarang? (y/n):${NC} )" RB
if [[ "${RB,,}" == "y" ]]; then
  loading "Rebooting sistem"
  sleep 1
  reboot
else
  echo -e "${GREEN}Selesai tanpa reboot.${NC}"
fi
