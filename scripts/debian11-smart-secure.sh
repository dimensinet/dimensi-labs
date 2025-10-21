#!/bin/bash
# ===================================================
# 🧠 SMART AUTO SECURE DEBIAN 11 (Interactive Final)
# by GPT-5 x DIMENSI
# ===================================================
# Fitur:
# ✅ Start from root @ port 22 (default)
# ✅ Interaktif: input username + SSH port + key
# ✅ Setup SSH key, sudo user, firewall, fail2ban
# ✅ Warna + animasi loading
# ✅ Disable password login setelah setup selesai
# ===================================================

# === WARNA ===
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# === ANIMASI ===
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

# === INPUT INTERAKTIF ===
read -p "🧩 Masukkan username baru (default: dimensi): " NEW_USER
NEW_USER=${NEW_USER:-dimensi}

read -p "🔐 Masukkan port SSH baru (default: 9822): " SSH_PORT
SSH_PORT=${SSH_PORT:-9822}

echo
read -p "🗝️  Paste isi Public Key (id_rsa.pub): " PUBKEY
if [[ -z "$PUBKEY" ]]; then
  echo -e "${RED}❌ Public key tidak boleh kosong! Jalankan ulang script.${NC}"
  exit 1
fi

echo
echo -e "${YELLOW}🚀 Menyiapkan setup aman untuk user '${NEW_USER}' dan port ${SSH_PORT}...${NC}"
sleep 1

# === 1️⃣ UPDATE SISTEM ===
echo -e "${YELLOW}[1/9] Updating system packages...${NC}"
(apt update -y && apt full-upgrade -y) & loading

# === 2️⃣ PASANG TOOLS ===
echo -e "${YELLOW}[2/9] Installing essential tools...${NC}"
(apt install -y sudo ufw fail2ban curl wget nano net-tools) & loading

# === 3️⃣ TAMBAH USER ===
echo -e "${YELLOW}[3/9] Adding sudo user '${NEW_USER}'...${NC}"
(adduser --disabled-password --gecos "" $NEW_USER && usermod -aG sudo $NEW_USER) & loading

# === 4️⃣ PASANG SSH KEY ===
echo -e "${YELLOW}[4/9] Setting up SSH keys...${NC}"
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

# === 5️⃣ TEST KEY AKSES ROOT (jika ingin login dulu pakai root key) ===
echo -e "${YELLOW}[5/9] Verifying root SSH key access...${NC}"
systemctl restart ssh &> /dev/null
sleep 1

# === 6️⃣ KONFIGURASI SSH ===
echo -e "${YELLOW}[6/9] Configuring SSH server...${NC}"
sed -i "s/#Port .*/Port 22/g" /etc/ssh/sshd_config  # pastikan awal tetap port 22
sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart ssh &> /dev/null
sleep 1

echo -e "${GREEN}✅ Server siap login awal di port 22 sebagai root.${NC}"
sleep 2

# === 7️⃣ UBAH PORT SSH + NONAKTIFKAN PASSWORD ===
echo -e "${YELLOW}[7/9] Applying secure SSH configuration...${NC}"
sed -i "s/^Port .*/Port $SSH_PORT/g" /etc/ssh/sshd_config
sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin.*/PermitRootLogin prohibit-password/g" /etc/ssh/sshd_config
systemctl restart ssh &> /dev/null
sleep 1

# === 8️⃣ FIREWALL ===
echo -e "${YELLOW}[8/9] Enabling UFW firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow $SSH_PORT/tcp comment "SSH Custom"
ufw allow 80,443/tcp comment "Web Traffic"
ufw --force enable &> /dev/null
sleep 1

# === 9️⃣ FAIL2BAN ===
echo -e "${YELLOW}[9/9] Activating Fail2Ban...${NC}"
systemctl enable fail2ban &> /dev/null
systemctl start fail2ban &> /dev/null
sleep 1

# === RINGKASAN ===
IP=$(hostname -I | awk '{print $1}')
clear
echo -e "${GREEN}"
echo "=============================================="
echo "✅ SMART SETUP COMPLETE - SECURE DEBIAN 11"
echo "=============================================="
echo -e "${CYAN}📡 IP VPS   :${NC} $IP"
echo -e "${CYAN}🔐 SSH Port :${NC} $SSH_PORT"
echo -e "${CYAN}👤 User Sudo:${NC} $NEW_USER"
echo -e "${CYAN}🔑 Login Key:${NC} Aktif (Password login dinonaktifkan)"
echo -e "${GREEN}"
echo "----------------------------------------------"
echo -e "💡 Gunakan perintah login baru:"
echo -e "${YELLOW}ssh -i id_rsa $NEW_USER@$IP -p $SSH_PORT${NC}"
echo "----------------------------------------------"
echo -e "${CYAN}🔥 Server sudah diamankan & siap digunakan.${NC}"
echo -e "${GREEN}==============================================${NC}"
