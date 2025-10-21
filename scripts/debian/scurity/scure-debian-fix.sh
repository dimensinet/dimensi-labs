#!/bin/bash
# ============================================================
# SECURE ROOT FIX — Debian 12
# Membenahi izin SSH, menonaktifkan login password,
# mengaktifkan auto security update, tanpa whitelist IP.
# ============================================================

set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}\n🧱 [1/5] Memperbaiki permission folder SSH root...${NC}"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys 2>/dev/null || true
chown -R root:root /root/.ssh
echo -e "${GREEN}✔ Permission SSH sudah aman.${NC}"

echo -e "${CYAN}\n🔐 [2/5] Mengamankan konfigurasi SSH...${NC}"
SSHD="/etc/ssh/sshd_config"
cp -n "$SSHD" "$SSHD.bak-$(date +%F-%H%M)" || true

# Nonaktifkan login password dan hanya izinkan key
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD"
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD"

# Pastikan port tetap sama (jangan ubah otomatis)
PORT=$(grep -E '^Port ' "$SSHD" | awk '{print $2}' || echo "22")
if [ -z "$PORT" ]; then PORT=22; fi
echo -e "${YELLOW}Port SSH aktif tetap: ${PORT}${NC}"

systemctl restart ssh || systemctl restart sshd
echo -e "${GREEN}✔ SSH dikonfigurasi ulang (key-only login aktif).${NC}"

echo -e "${CYAN}\n🚨 [3/5] Mengecek dan mengaktifkan Fail2Ban...${NC}"
if ! dpkg -s fail2ban >/dev/null 2>&1; then
  echo -e "${YELLOW}Fail2Ban belum ada, menginstal...${NC}"
  apt install -y fail2ban >/dev/null 2>&1
fi
systemctl enable --now fail2ban || echo -e "${RED}⚠️ Fail2Ban tidak bisa diaktifkan.${NC}"
echo -e "${GREEN}✔ Fail2Ban aktif.${NC}"

echo -e "${CYAN}\n🛠 [4/5] Mengaktifkan auto security update...${NC}"
apt install -y unattended-upgrades >/dev/null 2>&1
dpkg-reconfigure --priority=low unattended-upgrades
systemctl enable --now unattended-upgrades
echo -e "${GREEN}✔ Auto security update aktif.${NC}"

echo -e "${CYAN}\n🧩 [5/5] Memverifikasi kernel hardening...${NC}"
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
echo -e "${GREEN}✔ Kernel hardening diterapkan.${NC}"

echo -e "\n${GREEN}🎯 Semua perbaikan keamanan root selesai!${NC}"
echo -e "${YELLOW}SSH kini hanya menerima login menggunakan SSH key.${NC}"
echo -e "${CYAN}Jalankan: ${NC}systemctl status fail2ban ${CYAN}dan${NC} systemctl status unattended-upgrades ${CYAN}untuk verifikasi.${NC}"
