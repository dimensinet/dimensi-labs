#!/bin/bash
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; RESET='\033[0m'

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none
export SYSTEMD_RESTART_NO_BLOCK=yes

mkdir -p /usr/lib/needrestart/restart.d
echo 'exit 0' > /usr/lib/needrestart/restart.d/sshd
chmod +x /usr/lib/needrestart/restart.d/sshd

MSG_ID_START="Memulai peningkatan sistem Debian 11 ke Debian 12..."
MSG_ID_GLIBC="Memperbarui pustaka sistem (GLIBC dan locales)..."
MSG_ID_REPO="Memeriksa dan mengubah repository ke Debian 12..."
MSG_ID_KEY="Menambahkan kunci GPG untuk repository Debian 12..."
MSG_ID_UPDATE="Memperbarui daftar paket..."
MSG_ID_UPGRADE="Menjalankan peningkatan sistem penuh..."
MSG_ID_REPAIR="Memeriksa dan memperbaiki GLIBC jika diperlukan..."
MSG_ID_CLEAN="Membersihkan paket lama dan cache..."
MSG_ID_REBOOT="Sistem akan reboot otomatis dalam"
MSG_ID_DONE="Selesai! Sistem berhasil ditingkatkan ke Debian 12."

MSG_EN_START="Starting system upgrade from Debian 11 to Debian 12..."
MSG_EN_GLIBC="Upgrading core libraries (GLIBC and locales)..."
MSG_EN_REPO="Checking and switching repositories to Debian 12..."
MSG_EN_KEY="Adding Debian 12 repository GPG keys..."
MSG_EN_UPDATE="Updating package list..."
MSG_EN_UPGRADE="Running full system upgrade..."
MSG_EN_REPAIR="Checking and repairing GLIBC if needed..."
MSG_EN_CLEAN="Cleaning old packages and cache..."
MSG_EN_REBOOT="The system will reboot automatically in"
MSG_EN_DONE="Done! System successfully upgraded to Debian 12."

fade_line(){ echo -e "$1"; sleep 0.25; }

run_with_spinner(){
  local cmd="$1"; local msg="$2"; local spinstr='|/-\'; local cols=$(tput cols)
  echo -ne "${CYAN}${msg}${RESET}"
  eval "$cmd" >/dev/null 2>&1 &
  local pid=$!
  while kill -0 $pid 2>/dev/null; do
    for (( i=0; i<${#spinstr}; i++ )); do
      local spinner_pos=$((cols - 4))
      printf "\r${CYAN}%s${RESET}%*s${YELLOW}%c${RESET}" "$msg" $((spinner_pos - ${#msg})) "" "${spinstr:$i:1}"
      sleep 0.15
    done
  done
  wait $pid
  printf "\r${GREEN}%s ... Done!%*s${RESET}\n" "$msg" $((cols - ${#msg} - 12)) ""
}

countdown_reboot(){
  local seconds=10; local spinstr='|/-\'; local cols=$(tput cols)
  local msg="$REBOOT"; local unit; if [ "$LANG" = "EN" ]; then unit="seconds"; else unit="detik"; fi
  local end_time=$((SECONDS + seconds))
  while [ $SECONDS -lt $end_time ]; do
    for (( i=0; i<${#spinstr}; i++ )); do
      local remaining=$((end_time - SECONDS))
      [ $remaining -lt 0 ] && break
      local spinner_pos=$((cols - 4))
      printf "\r${YELLOW}%s ${RESET}%2d %s %*s${CYAN}%c${RESET}" "$msg" "$remaining" "$unit" $((spinner_pos - ${#msg} - 14)) "" "${spinstr:$i:1}"
      sleep 0.15
    done
  done
  printf "\r${GREEN}%s${RESET}\n" "$DONE"
  sleep 1
  reboot
}

clear
fade_line "==============================================="
fade_line " DIMENSI LABS — Debian 11 ➜ 12"
fade_line "===============================================\n"
fade_line "${YELLOW}Silakan pilih bahasa tampilan / Please select display language.${RESET}"
fade_line "${CYAN}-----------------------------------------------${RESET}"
fade_line " [1] Bahasa Indonesia"
fade_line " [2] English"
fade_line "${CYAN}-----------------------------------------------${RESET}\n"
read -p "Pilih [1/2]: " LANG_CHOICE; echo ""
if [ "$LANG_CHOICE" = "2" ]; then LANG="EN"; else LANG="ID"; fi

if [ "$LANG" = "EN" ]; then
  START=$MSG_EN_START; GLIBC=$MSG_EN_GLIBC; REPO=$MSG_EN_REPO; KEY=$MSG_EN_KEY
  UPDATE=$MSG_EN_UPDATE; UPGRADE=$MSG_EN_UPGRADE; REPAIR=$MSG_EN_REPAIR
  CLEAN=$MSG_EN_CLEAN; REBOOT=$MSG_EN_REBOOT; DONE=$MSG_EN_DONE
else
  START=$MSG_ID_START; GLIBC=$MSG_ID_GLIBC; REPO=$MSG_ID_REPO; KEY=$MSG_ID_KEY
  UPDATE=$MSG_ID_UPDATE; UPGRADE=$MSG_ID_UPGRADE; REPAIR=$MSG_ID_REPAIR
  CLEAN=$MSG_ID_CLEAN; REBOOT=$MSG_ID_REBOOT; DONE=$MSG_ID_DONE
fi

fade_line "${CYAN}$START${RESET}\n"
sleep 1

run_with_spinner "sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list" "$REPO"
run_with_spinner "apt install -y debian-archive-keyring" "$KEY"
run_with_spinner "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6ED0E7B82643E131 78DBA3BC47EF2265 F8D2585B8783D481" "$KEY"

fade_line "${CYAN}$GLIBC${RESET}"
apt update -y >/dev/null 2>&1
apt install -y libc6 locales >/dev/null 2>&1
sleep 1

run_with_spinner "apt update -y" "$UPDATE"
run_with_spinner "apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" full-upgrade" "$UPGRADE"

fade_line "${CYAN}$REPAIR${RESET}"
if ! ldd --version 2>/dev/null | grep -q "2\.3[5-6]"; then
  LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/lib64 apt -f install -y >/dev/null 2>&1
  LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/lib64 dpkg --configure -a >/dev/null 2>&1
  apt install --reinstall -y libc6 >/dev/null 2>&1
fi

run_with_spinner "apt autoremove -y && apt autoclean -y" "$CLEAN"
countdown_reboot
