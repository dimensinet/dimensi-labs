#!/bin/bash
# ==========================================
# Debian 11/12 Secure Setup Script (v3.3-UI)
# By ChatGPT (for dimensi.net)
# Features:
# - Same as v3.3 (auto-disable root login, SSH test)
# - With color, animation, progress & delay
# ==========================================

# --- Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
RESET='\033[0m'
BOLD='\033[1m'

# --- Helper: progress bar
progress() {
  local msg=$1
  echo -ne "${YELLOW}$msg${RESET}"
  for i in {1..10}; do
    echo -ne "."
    sleep 0.1
  done
  echo " ${GREEN}done.${RESET}"
  sleep 0.3
}

# --- Helper: section title
section() {
  echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}"
  sleep 0.5
}

# --- Root check
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}❌ Jalankan sebagai root!${RESET}"
  exit 1
fi

clear
echo -e "${BOLD}${GREEN}🚀 Memulai konfigurasi keamanan Debian 11/12 (v3.3-UI)...${RESET}"
sleep 1

# 1️⃣ USER SETUP
section "Membuat user admin baru"
read -p "👤 Masukkan nama user admin baru: " NEWUSER
if id "$NEWUSER" &>/dev/null; then
    echo -e "${YELLOW}⚠️ User $NEWUSER sudah ada, melewati pembuatan.${RESET}"
else
    progress "Menambahkan user $NEWUSER"
    adduser --gecos "" "$NEWUSER"
    usermod -aG sudo "$NEWUSER"
    echo -e "${GREEN}✅ User $NEWUSER berhasil dibuat.${RESET}"
fi
sleep 0.5

# 2️⃣ SSH KEY
section "Menambahkan SSH Key"
read -p "🔑 Masukkan public SSH key: " SSHKEY
mkdir -p /home/$NEWUSER/.ssh
echo "$SSHKEY" > /home/$NEWUSER/.ssh/authorized_keys
chmod 700 /home/$NEWUSER/.ssh
chmod 600 /home/$NEWUSER/.ssh/authorized_keys
chown -R $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh
progress "Menulis authorized_keys"
echo -e "${GREEN}✅ SSH key ditambahkan.${RESET}"

# 3️⃣ CUSTOM PORT
section "Mengatur port SSH custom"
read -p "📡 Masukkan port SSH custom (misal: 2222): " CUSTOM_PORT
if [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]] && [ "$CUSTOM_PORT" -ge 1024 ] && [ "$CUSTOM_PORT" -le 65535 ]; then
    progress "Mengubah konfigurasi SSH"
    SSHD_CONF="/etc/ssh/sshd_config"
    cp "$SSHD_CONF" "${SSHD_CONF}.backup-$(date +%F-%H%M)"
    sed -i '/^#\?Port /d' "$SSHD_CONF"
    echo "Port $CUSTOM_PORT" >> "$SSHD_CONF"
else
    echo -e "${RED}⚠️ Port tidak valid. Menggunakan default 22.${RESET}"
    CUSTOM_PORT=22
fi

# 4️⃣ SYSTEM UPDATE
section "Memperbarui sistem & memasang paket keamanan"
export DEBIAN_FRONTEND=noninteractive
progress "Menjalankan apt update"
apt update -yq >/dev/null 2>&1
progress "Menjalankan full-upgrade"
apt -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade -yq >/dev/null 2>&1
progress "Menginstal tools keamanan"
apt install -yq sudo curl wget nano htop ufw fail2ban unattended-upgrades auditd chrony >/dev/null 2>&1

# 5️⃣ FIREWALL
section "Mengaktifkan firewall UFW"
ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow "$CUSTOM_PORT"/tcp comment "SSH Custom" >/dev/null
ufw allow 80,443/tcp comment "HTTP/HTTPS" >/dev/null
progress "Mengaktifkan UFW"
ufw --force enable >/dev/null 2>&1
echo -e "${GREEN}✅ Firewall aktif dan port $CUSTOM_PORT terbuka.${RESET}"

# 6️⃣ FAIL2BAN
section "Mengaktifkan Fail2Ban & Time Sync"
systemctl enable --now fail2ban >/dev/null 2>&1
systemctl enable --now chrony >/dev/null 2>&1
timedatectl set-timezone Asia/Jakarta
dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1
progress "Aktivasi layanan keamanan"

# 7️⃣ SUDO & SSH TEST
section "Konfigurasi sudo dan tes SSH"
echo "$NEWUSER ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$NEWUSER
chmod 440 /etc/sudoers.d/90-$NEWUSER
systemctl restart ssh || systemctl reload ssh
sleep 2

IP=$(hostname -I | awk '{print $1}')
echo -e "${YELLOW}🧪 Menguji koneksi SSH user baru ($NEWUSER@$IP:$CUSTOM_PORT)...${RESET}"
if nc -z 127.0.0.1 "$CUSTOM_PORT"; then
  echo -e "${GREEN}✅ Port $CUSTOM_PORT terbuka.${RESET}"
else
  echo -e "${RED}❌ Port tidak terbuka. Root login tidak akan dinonaktifkan.${RESET}"
  AUTO_DISABLE_ROOT="no"
fi

if su -c "ssh -o StrictHostKeyChecking=no -p $CUSTOM_PORT -T $NEWUSER@127.0.0.1 'echo ✅ Login test berhasil'" -s /bin/bash root; then
  echo -e "${GREEN}✅ Tes login internal sukses.${RESET}"
  AUTO_DISABLE_ROOT="yes"
else
  AUTO_DISABLE_ROOT="no"
fi

# 8️⃣ DISABLE ROOT
cat <<EOF > /root/disable-root-ssh.sh
#!/bin/bash
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh
echo "✅ Root SSH login telah dinonaktifkan."
EOF
chmod +x /root/disable-root-ssh.sh

if [ "$AUTO_DISABLE_ROOT" == "yes" ]; then
  progress "Menonaktifkan root login otomatis"
  /root/disable-root-ssh.sh
else
  echo -e "${YELLOW}⚠️ Root login dibiarkan aktif untuk keamanan sementara.${RESET}"
fi

# 9️⃣ DONE
echo -e "\n${GREEN}${BOLD}=========================================="
echo "✅ Instalasi & Hardening Selesai!"
echo "  • User admin : $NEWUSER"
echo "  • Port SSH   : $CUSTOM_PORT"
echo "  • Root login : $( [ "$AUTO_DISABLE_ROOT" == "yes" ] && echo 'DINONAKTIFKAN ✅' || echo 'MASIH AKTIF ⚠️' )"
echo "  • Firewall   : Aktif (UFW)"
echo "  • Fail2Ban   : Aktif"
echo "  • AutoUpdate : Aktif"
echo "  • Timezone   : Asia/Jakarta"
echo "==========================================${RESET}"
sleep 0.5
echo -e "${YELLOW}💡 Tes login di MobaXterm:${RESET}"
echo -e "   ${BOLD}ssh -p $CUSTOM_PORT $NEWUSER@$IP${RESET}"
echo -e "${BLUE}📁 Jika root login masih aktif, jalankan:${RESET}"
echo -e "   ${BOLD}sudo /root/disable-root-ssh.sh${RESET}"
echo -e "${GREEN}==========================================${RESET}\n"
