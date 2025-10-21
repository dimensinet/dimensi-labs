#!/bin/bash
# ===================================================
# 🧠 SMART AUTO SECURE DEBIAN 11 (Final Non-Interactive)
# by GPT-5 x DimensiNet
# ===================================================
# ✅ Default username: admin
# ✅ Default SSH port: 22
# ✅ Non-interactive apt (no stuck prompt)
# ✅ Full setup: SSH Key, sudo, UFW, Fail2Ban
# ✅ Animated + colorized output
# ===================================================

# === WARNA ===
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# === ANIMASI LOADING ===
loading() {
  local pid=$!
  local delay=0.15
  local spin='|/-\'
  while [ -d /proc/$pid ]; do
    for i in $(seq 0 3); do
      printf "\r${YELLOW}⏳ %s${NC}" "${spin:$i:1}"
      sleep $delay
    done
  done
  printf "\r${GREEN}✅ Done!${NC}\n"
}

# === HEADER ===
clear
echo -e "${CYAN}"
echo "=============================================="
echo " 🔐 SMART DEBIAN 11 SECURE INSTALLER"
echo "=============================================="
echo -e "${NC}"
sleep 1

# === INPUT DEFAULT DENGAN OPSI GANTI ===
read -p "🧩 Masukkan username baru (default: admin): " NEW_USER
NEW_USER=${NEW_USER:-admin}

read -p "🔐 Masukkan port SSH baru (default: 22): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

echo
read -p "🗝️  Paste isi Public Key (publickey.pub): " PUBKEY
if [[ -z "$PUBKEY" ]]; then
  echo -e "${RED}❌ Public key tidak boleh kosong! Jalankan ulang script.${NC}"
  exit 1
fi

echo
echo -e "${YELLOW}🚀 Memulai setup aman untuk user '${NEW_USER}' di port ${SSH_PORT}...${NC}"
sleep 1

# === 1️⃣ UPDATE SISTEM TANPA PROMPT ===
echo -e "${YELLOW}[1/8] Updating system packages (non-interactive)...${NC}"
(
DEBIAN_FRONTEND=noninteractive apt update -y
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"
) & loading

# === 2️⃣ PASANG TOOLS ===
echo -e "${YELLOW}[2/8] Installing essential tools...${NC}"
(
DEBIAN_FRONTEND=noninteractive apt install -y sudo ufw fail2ban curl wget nano net-tools \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"
) & loading

# === 3️⃣ TAMBAH USER ===
echo -e "${YELLOW}[3/8] Creating sudo user '${NEW_USER}'...${NC}"
(adduser --disabled-password --gecos "" $NEW_USER && usermod -aG sudo $NEW_USER) & loading

# === 4️⃣ PASANG SSH KEY ===
echo -e "${YELLOW}[4/8] Setting up SSH keys...${NC}"
mkdir -p /root/.ssh
echo "$PUBKEY" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh

mkdir -p /home/$NEW_USER/.ssh
echo "$PUBKEY" > /home/$NEW_USER/.ssh/authorized_keys
chmod 700 /home/$NEW_USER/.ssh
chmod 600 /home/$NEW_USER/.ssh/authorized_keys
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
sleep 1

# === 5️⃣ KONFIGURASI SSH ===
echo -e "${YELLOW}[5/8] Configuring SSH server...${NC}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sed -i "s/^#*Port .*/Port $SSH_PORT/g" /etc/ssh/sshd_config
sed -i "s/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#*PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/g" /etc/ssh/sshd_config
systemctl restart ssh &> /dev/null
sleep 1

# === 6️⃣ FIREWALL ===
echo -e "${YELLOW}[6/8] Configuring UFW firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow $SSH_PORT/tcp comment "SSH Access"
ufw allow 80,443/tcp comment "Web Traffic"
ufw --force enable &> /dev/null
sleep 1

# === 7️⃣ FAIL2BAN ===
echo -e "${YELLOW}[7/8] Enabling Fail2Ban...${NC}"
systemctl enable fail2ban &> /dev/null
systemctl start fail2ban &> /dev/null
sleep 1

# === 8️⃣ RINGKASAN ===
IP=$(hostname -I | awk '{print $1}')
clear
echo -e "${GREEN}"
echo "=============================================="
echo "✅ SECURE SETUP COMPLETE - DEBIAN 11"
echo "=============================================="
echo -e "${CYAN}📡 IP VPS   :${NC} $IP"
echo -e "${CYAN}🔐 SSH Port :${NC} $SSH_PORT"
echo -e "${CYAN}👤 User Sudo:${NC} $NEW_USER"
echo -e "${CYAN}🔑 SSH Key  :${NC} Aktif (Password login dinonaktifkan)"
echo -e "${GREEN}"
echo "----------------------------------------------"
echo -e "💡 Gunakan perintah login:"
echo -e "${YELLOW}ssh -i id_rsa $NEW_USER@$IP -p $SSH_PORT${NC}"
echo "----------------------------------------------"
echo -e "${CYAN}🔥 Server sudah diamankan & siap digunakan.${NC}"
echo -e "${GREEN}==============================================${NC}"
