#!/bin/bash
# ==========================================
# Debian 11/12 Secure Setup Script (v3.0)
# Fixes: ufw prompt, chrony service name, AllowUsers check,
#        full noninteractive upgrades, safer rkhunter, etc.
# ==========================================
set -euo pipefail

echo "🔐 Starting Secure Setup for Debian 11/12 (v3.0)..."
sleep 1

# --- helper: check running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Please run this script as root." >&2
  exit 2
fi

# ========== USER SETUP ==========
read -p "👤 Masukkan nama user admin baru: " NEWUSER
adduser --gecos "" $NEWUSER
usermod -aG sudo $NEWUSER
echo "✅ User $NEWUSER telah ditambahkan ke grup sudo."

# ========== CUSTOM SSH PORT SETUP ==========
read -p "📡 Masukkan port SSH custom (misal: 9822): " CUSTOM_PORT
if [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]] && [ "$CUSTOM_PORT" -ge 1 ] && [ "$CUSTOM_PORT" -le 65535 ]; then
    echo "🔧 Mengubah port SSH menjadi $CUSTOM_PORT..."
    SSHD_CONF="/etc/ssh/sshd_config"
    if [ ! -f "${SSHD_CONF}.bak_custom" ]; then
        cp "$SSHD_CONF" "${SSHD_CONF}.bak_custom"
    fi
    sed -i '/^#\?Port /d' "$SSHD_CONF"
    echo "Port $CUSTOM_PORT" >> "$SSHD_CONF"
    ufw allow "$CUSTOM_PORT"/tcp comment "Custom SSH Port $CUSTOM_PORT"
    ufw delete allow 22/tcp 2>/dev/null || true
    systemctl restart ssh
    echo "✅ Port SSH berhasil diubah ke $CUSTOM_PORT"
else
    echo "⚠️ Port tidak valid. Menggunakan port default 22."
    CUSTOM_PORT=22
fi


# ========== SSH KEY SETUP ==========
read -p "🔑 Masukkan public SSH key (mulai dengan ssh-rsa atau ssh-ed25519): " SSHKEY
mkdir -p /home/"$NEWUSER"/.ssh
echo "$SSHKEY" > /home/"$NEWUSER"/.ssh/authorized_keys
chmod 700 /home/"$NEWUSER"/.ssh
chmod 600 /home/"$NEWUSER"/.ssh/authorized_keys
chown -R "$NEWUSER":"$NEWUSER" /home/"$NEWUSER"/.ssh
echo "✅ SSH key ditambahkan untuk user $NEWUSER."

# ========== SAFELY MODIFY sshd_config ==========
SSHD_CONF="/etc/ssh/sshd_config"
# backup original once
if [ ! -f "${SSHD_CONF}.orig_v3" ]; then
  cp "$SSHD_CONF" "${SSHD_CONF}.orig_v3"
fi

# ensure no duplicate AllowUsers and set PermitRootLogin & password auth off
# Use sed to replace or append in safe way
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONF" || true
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONF" || true
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD_CONF" || true

# Add AllowUsers only if not present
if ! grep -qE '^\s*AllowUsers\s+' "$SSHD_CONF"; then
  echo "AllowUsers $NEWUSER" >> "$SSHD_CONF"
else
  # replace existing AllowUsers line to include NEWUSER safely
  awk -v u="$NEWUSER" '
    BEGIN{p=0}
    /^\s*AllowUsers\s+/ {
      $0 = $0 " " u
      p=1
    }
    {print}
    END{ if(p==0) print "AllowUsers " u }
  ' "$SSHD_CONF" > "${SSHD_CONF}.tmp" && mv "${SSHD_CONF}.tmp" "$SSHD_CONF"
fi

# restart sshd (safe restart)
systemctl reload ssh || systemctl restart ssh

# ========== UPDATE & SECURITY TOOLS (non-interactive) ==========
echo "🧩 Mengupdate sistem dan memasang tools keamanan (non-interactive)..."
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
# stop any unattended-upgrades to avoid dpkg locks
systemctl stop unattended-upgrades 2>/dev/null || true

apt update -yq

# non-interactive full-upgrade while keeping old config files
apt -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade -yq

# install packages quietly
apt install -yq sudo curl wget nano htop ufw fail2ban unattended-upgrades auditd rkhunter chkrootkit chrony || true

# ========== TIMEZONE & SYNC WAKTU ==========
timedatectl set-timezone Asia/Jakarta
# enable chrony service (chrony is the systemd unit on Debian)
systemctl enable --now chrony || true

# ========== FIREWALL (UFW) ==========
# allow custom ssh port if user set custom port in sshd_config
SSH_PORT=$(awk '/^\s*Port\s+/{print $2; exit}' "$SSHD_CONF" || echo "22")
if [ -z "$SSH_PORT" ]; then SSH_PORT=22; fi

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT"/tcp comment 'SSH (custom)'
ufw allow 80,443/tcp comment 'HTTP/HTTPS'
ufw --force enable
ufw status verbose || true

# ========== FAIL2BAN ==========
systemctl enable --now fail2ban || true

# ========== KERNEL HARDENING ==========
cat <<'EOF' >> /etc/sysctl.conf

# --- Security Hardening v3 ---
kernel.randomize_va_space = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
sysctl -p || true

# ========== AUTO SECURITY UPDATE ==========
# noninteractive reconfigure for unattended-upgrades
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive unattended-upgrades || true

# ========== CRON AUTO UPDATE ==========
( crontab -l 2>/dev/null | grep -v '@weekly apt update' || true
) >/tmp/cron.$$ || true
echo "@weekly DEBIAN_FRONTEND=noninteractive apt update && apt -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' full-upgrade -y && apt autoremove -y" >> /tmp/cron.$$
crontab /tmp/cron.$$
rm -f /tmp/cron.$$

# ========== ROOTKIT CHECK INITIAL (non-blocking) ==========
rkhunter --update || true
rkhunter --propupd || true

# ========== FINAL MESSAGE ==========
echo ""
echo "=========================================="
echo "✅ Instalasi & Hardening v3 selesai!"
echo "  • User admin : $NEWUSER"
echo "  • SSH port   : $SSH_PORT"
echo "  • SSH key    : sudah ditambahkan"
echo "  • Root login : dinonaktifkan"
echo "  • Firewall   : aktif (UFW) - port $SSH_PORT allowed"
echo "  • Fail2ban   : aktif"
echo "  • Auto update: mingguan via cron"
echo "  • Timezone   : Asia/Jakarta"
echo "=========================================="
echo "🔎 NOTES:"
echo " - Jika kamu memakai port SSH custom, pastikan MobaXterm / client pakai port $SSH_PORT"
echo " - Backup file /etc/ssh/sshd_config.orig_v3 jika perlu rollback"
echo ""
echo "Login ulang menggunakan:"
echo "ssh -p $SSH_PORT $NEWUSER@$(hostname -I | awk '{print $1}')"
echo ""
