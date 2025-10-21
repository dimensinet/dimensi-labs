#!/bin/bash
# ==========================================================
# 🧩 MikroTik CHR QEMU Manager Ultimate++ (Debian 12)
# ==========================================================
# Author : Eko Sulistyawan × GPT-5
# Version: 6.0 Final
# Fitur :
# - Install / Uninstall / Check / Console / Restart
# - Auto-detect interface publik
# - Auto-Repair saat boot
# - Network Tools (ping, port, NAT info, reset)
# ==========================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

progress() {
  local msg=$1
  echo -e "\n${YELLOW}${msg}${NC}"
  for i in $(seq 0 5 100); do
    printf "\r${CYAN}[%-20s] %d%%${NC}" $(printf '#%.0s' $(seq 1 $((i/5)))) $i
    sleep 0.03
  done
  echo -e " ${GREEN}✓${NC}"
}
pause() { echo -e "\n${CYAN}Tekan ENTER untuk kembali ke menu...${NC}"; read -r; }

# ==========================================================
# 🌐 AUTO DETECT INTERFACE PUBLIK
# ==========================================================
detect_iface() {
  IFACE=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'dev \K\S+' | head -n1)
  [[ -z "$IFACE" ]] && IFACE=$(ip -o link show | awk -F': ' '!/lo/ {print $2; exit}')
  echo "$IFACE"
}

# ==========================================================
# 🧱 INSTALL CHR
# ==========================================================
install_chr() {
  clear
  echo -e "${GREEN}${BOLD}🚀 Instalasi MikroTik CHR QEMU Bridge-NAT /28${NC}"
  progress "📦 Menginstal dependensi..."
  apt update -y >/dev/null 2>&1
  apt install -y qemu-system-x86 qemu-utils bridge-utils iptables iptables-persistent unzip wget curl net-tools >/dev/null 2>&1
  modprobe tun bridge br_netfilter
  sysctl -w net.ipv4.ip_forward=1 >/dev/null

  progress "🧹 Membersihkan instalasi lama..."
  systemctl stop chr.service 2>/dev/null || true
  systemctl disable chr.service 2>/dev/null || true
  rm -rf /etc/systemd/system/chr.service /root/chr
  mkdir -p /root/chr

  progress "🌐 Mendeteksi interface publik..."
  PUB_IFACE=$(detect_iface)
  echo -e "${CYAN}Interface publik terdeteksi: ${GREEN}${PUB_IFACE}${NC}"

  progress "⬇️ Mengunduh image MikroTik CHR..."
  cd /root/chr
  wget -q https://github.com/elseif/MikroTikPatch/releases/download/7.20.1/chr-7.20.1-legacy-bios.qcow2.zip
  unzip -o chr-7.20.1-legacy-bios.qcow2.zip >/dev/null
  qemu-img create -f qcow2 chr-disk.qcow2 512M >/dev/null

  progress "🧱 Membuat Bridge NAT..."
  cat > /root/chr/setup-bridge-nat.sh <<EOF
#!/bin/bash
set -e
IFACE="${PUB_IFACE}"
CHR_IP="10.0.0.2"
ip link set tap0 down 2>/dev/null || true
brctl delif bridge-nat tap0 2>/dev/null || true
ip tuntap del dev tap0 mode tap 2>/dev/null || true
ip link set bridge-nat down 2>/dev/null || true
brctl delbr bridge-nat 2>/dev/null || true
brctl addbr bridge-nat
ip addr add 10.0.0.1/28 dev bridge-nat
ip link set bridge-nat up
sysctl -w net.ipv4.ip_forward=1 >/dev/null
sleep 2
iptables -t nat -C POSTROUTING -s 10.0.0.0/28 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.0.0.0/28 -j MASQUERADE
ip tuntap add dev tap0 mode tap user root
ip link set tap0 up
brctl addif bridge-nat tap0
# Port publik
iptables -t nat -A PREROUTING -i \${IFACE} -p tcp --dport 6921 -j DNAT --to \${CHR_IP}:8291
iptables -t nat -A PREROUTING -i \${IFACE} -p tcp --dport 6928 -j DNAT --to \${CHR_IP}:8728
iptables -t nat -A PREROUTING -i \${IFACE} -p tcp --dport 6922 -j DNAT --to \${CHR_IP}:22
iptables -t nat -A PREROUTING -i \${IFACE} -p tcp --dport 6980 -j DNAT --to \${CHR_IP}:80
netfilter-persistent save >/dev/null 2>&1
EOF
  chmod +x /root/chr/setup-bridge-nat.sh

  progress "💾 Membuat runner & service..."
  cat > /root/chr/run-chr.sh <<'EOF'
#!/bin/bash
set -e
ip tuntap add dev tap0 mode tap user root 2>/dev/null || true
ip link set tap0 up 2>/dev/null || true
brctl addif bridge-nat tap0 2>/dev/null || true
exec qemu-system-x86_64 -m 256M \
  -drive file=/root/chr/chr-7.20.1-legacy-bios.qcow2,if=virtio,media=disk \
  -drive file=/root/chr/chr-disk.qcow2,if=virtio,media=disk \
  -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
  -device virtio-net-pci,netdev=net0 -nographic
EOF
  chmod +x /root/chr/run-chr.sh

  cat > /etc/systemd/system/chr.service <<'EOF'
[Unit]
Description=MikroTik CHR (QEMU Bridge-NAT)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/usr/bin/sleep 10
ExecStartPre=/root/chr/setup-bridge-nat.sh
ExecStart=/root/chr/run-chr.sh
ExecStop=/bin/pkill -f qemu-system-x86_64
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

  progress "⚙️ Menambahkan Auto-Repair on Boot..."
  cat > /etc/systemd/system/chr-auto-repair.service <<'EOF'
[Unit]
Description=Auto Repair CHR Bridge and NAT at Boot
After=network-online.target
Requires=network-online.target

[Service]
Type=oneshot
ExecStart=/root/chr-tools/install.sh --auto-repair
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable chr.service chr-auto-repair.service >/dev/null
  systemctl restart chr.service

  echo -e "\n${GREEN}${BOLD}✅ Instalasi CHR selesai!${NC}"
  echo -e "${CYAN}Bridge: 10.0.0.1/28 | CHR: 10.0.0.2"
  echo -e "Interface publik: ${PUB_IFACE}"
  echo -e "Auto-Repair aktif setiap boot 🔁"
  pause
}

# ==========================================================
# 🧯 AUTO REPAIR SYSTEM
# ==========================================================
auto_repair() {
  PUB_IFACE=$(detect_iface)
  echo -e "${YELLOW}🧯 Auto-Repair: memperbaiki bridge & NAT (iface=${PUB_IFACE})...${NC}"
  systemctl stop chr.service 2>/dev/null || true
  IFACE="${PUB_IFACE}" bash /root/chr/setup-bridge-nat.sh 2>/dev/null || true
  systemctl restart chr.service
  echo -e "${GREEN}✅ CHR telah diperbaiki & aktif kembali.${NC}"
  exit 0
}
[[ "$1" == "--auto-repair" ]] && auto_repair

# ==========================================================
# 🔁 MENU UTAMA
# ==========================================================
uninstall_chr() { systemctl stop chr.service; rm -rf /etc/systemd/system/chr* /root/chr; echo -e "${GREEN}✅ Uninstalled.${NC}"; pause; }
check_chr() { systemctl status chr.service --no-pager | grep Active; ip -br addr show bridge-nat || echo "Bridge hilang"; pause; }
console_chr() { systemctl stop chr.service; bash /root/chr/run-chr.sh; systemctl start chr.service; pause; }
restart_chr() { systemctl restart chr.service; sleep 2; echo -e "${GREEN}✅ CHR restarted.${NC}"; pause; }

network_tools() {
  clear
  echo -e "${CYAN}${BOLD}========== NETWORK TOOLS ==========${NC}"
  echo -e "1. Ping CHR (10.0.0.2)"
  echo -e "2. Ping Internet (8.8.8.8)"
  echo -e "3. Lihat NAT Table"
  echo -e "4. Reset NAT"
  echo -e "0. Kembali"
  read -p "Pilih: " x
  case $x in
    1) ping -c 3 10.0.0.2 || echo -e "${RED}CHR tidak merespons.${NC}" ;;
    2) ping -c 3 8.8.8.8 || echo -e "${RED}Tidak ada akses internet.${NC}" ;;
    3) iptables -t nat -L -n ;;
    4) iptables -t nat -F && echo -e "${GREEN}NAT direset.${NC}" ;;
  esac
  pause
}

while true; do
  clear
  echo -e "${CYAN}${BOLD}============================================"
  echo -e "🧩 MIKROTIK CHR QEMU MANAGER ULTIMATE++"
  echo -e "============================================${NC}"
  echo -e "${YELLOW}1.${NC} Install CHR"
  echo -e "${YELLOW}2.${NC} Uninstall CHR"
  echo -e "${YELLOW}3.${NC} Check Status"
  echo -e "${YELLOW}4.${NC} Console Access"
  echo -e "${YELLOW}5.${NC} Restart Service"
  echo -e "${YELLOW}6.${NC} Network Tools"
  echo -e "${YELLOW}7.${NC} Auto Repair (Manual)"
  echo -e "${YELLOW}0.${NC} Keluar"
  echo -ne "\n${CYAN}Pilih menu: ${NC}"
  read -r opt
  case $opt in
    1) install_chr ;;
    2) uninstall_chr ;;
    3) check_chr ;;
    4) console_chr ;;
    5) restart_chr ;;
    6) network_tools ;;
    7) auto_repair ;;
    0) clear; exit 0 ;;
    *) echo "Pilihan salah"; sleep 1 ;;
  esac
done
