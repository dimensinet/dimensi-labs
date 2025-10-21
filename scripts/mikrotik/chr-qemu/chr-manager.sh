#!/bin/bash
# ============================================================
# CHR Manager (Menu Interaktif)
# ============================================================

set -e
WORK_DIR="/opt/chr-installer"

if ! command -v dialog &>/dev/null; then
  apt update -y && apt install dialog -y
fi

while true; do
  CHOICE=$(dialog --clear --backtitle "CHR Manager - Dimensi Labs" \
  --title "Menu Utama" --menu "Pilih aksi:" 20 60 10 \
  1 "Install CHR" 2 "Rebuild Cepat" 3 "Reset (Full)" \
  4 "Uninstall" 5 "Status" 6 "Restart" 7 "Stop" 0 "Keluar" \
  3>&1 1>&2 2>&3)
  clear
  case $CHOICE in
    1) bash "$WORK_DIR/install.sh";;
    2) bash "$WORK_DIR/rebuild-chr.sh";;
    3) bash "$WORK_DIR/reset-chr.sh";;
    4) bash "$WORK_DIR/uninstall-chr.sh";;
    5) systemctl status chr;;
    6) systemctl restart chr;;
    7) systemctl stop chr;;
    0) clear; exit 0;;
  esac
done
