#!/bin/bash
# ==========================================
# Debian 11/12 Secure Setup Script (v2.0)
# by ChatGPT (for Eko Sulistyawan)
# ==========================================

set -e

echo "🔐 Starting Secure Setup for Debian 11/12..."
sleep 2

# ========== USER SETUP ==========
read -p "👤 Masukkan nama user admin baru: " NEWUSER
adduser --gecos "" $NEWUSER
usermod -aG sudo $NEWUSER
echo "✅ User $NEWUSER telah ditambahkan ke grup sudo."

# ========== SSH KEY SETUP ==========
read -p "🔑 Masukkan public SSH key (mulai dengan ssh-rsa atau ssh-ed25519): " SSHKEY
mkdir -p /home/$NEWUSER/.ssh
echo "$SSHKEY" > /home/$NEWUSER/.ssh/authorized_keys
chmod 700 /home/$NEWUSER/.ssh
chmod 600 /home/$NEWUSER/.ssh/authorized_keys
chown -R $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh
echo "✅ SSH key ditambahkan untuk user $NEWUSER."

# ========== DISABLE ROOT LOGIN ==========
echo "🔒 Menonaktifkan root login via SSH..."
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
echo "AllowUsers $NEWUSER" >> /etc/ssh/sshd_config
systemctl restart ssh
echo "✅ Root login dan password SSH dinonaktifkan."

# ========== UPDATE & SECURITY TOOLS ==========
echo "🧩 Mengupdate sistem dan memasang tools keamanan..."
export DEBIAN_FRONTEND=noninteractive
systemctl stop unattended-upgrades 2>/dev/null || true
apt update -y
apt -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade -yq
apt install -yq sudo curl wget nano htop ufw fail2ban unattended-upgrades auditd rkhunter chkrootkit chrony

# ========== TIMEZONE & SYNC WAKTU ==========
timedatectl set-timezone Asia/Jakarta
systemctl enable --now chronyd

# ========== FIREWALL ==========
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH Secure'
ufw allow 80,443/tcp comment 'HTTP/HTTPS'
ufw enable
ufw status verbose

# ========== FAIL2BAN ==========
systemctl enable --now fail2ban

# ========== HARDEN KERNEL ==========
cat <<EOF >> /etc/sysctl.conf

# --- Security Hardening ---
kernel.randomize_va_space = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
EOF
sysctl -p

# ========== AUTO SECURITY UPDATE ==========
dpkg-reconfigure --priority=low unattended-upgrades

# ========== CRON AUTO UPDATE ==========
echo "🕒 Menambahkan cron auto update mingguan..."
(crontab -l 2>/dev/null; echo "@weekly apt update && apt full-upgrade -y && apt autoremove -y") | crontab -

# ========== ROOTKIT CHECK INITIAL ==========
rkhunter --update
rkhunter --propupd

# ========== FINAL MESSAGE ==========
echo ""
echo "=========================================="
echo "✅ Instalasi & Hardening Selesai!"
echo "🧱 Detail:"
echo "  • User admin : $NEWUSER"
echo "  • SSH key     : sudah ditambahkan"
echo "  • Root login  : nonaktif (key-only)"
echo "  • Firewall    : aktif (UFW)"
echo "  • Fail2ban    : aktif"
echo "  • Auto update : mingguan via cron"
echo "  • Timezone    : Asia/Jakarta"
echo "=========================================="
echo "💡 Sekarang login ulang pakai:"
echo "   ssh $NEWUSER@$(hostname -I | awk '{print $1}')"
echo "   (pastikan login berhasil sebelum keluar dari root)"
echo "=========================================="
