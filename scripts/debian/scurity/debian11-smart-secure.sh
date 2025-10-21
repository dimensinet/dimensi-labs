#!/bin/bash
# ==========================================
# Debian 11/12 Secure Setup Script (v3.3)
# By ChatGPT (for dimensi.net)
# ==========================================
set -euo pipefail

echo "🚀 Memulai konfigurasi keamanan Debian 11/12 (v3.3)..."
sleep 1

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Jalankan sebagai root!"
  exit 1
fi

# ========== 1️⃣ Buat user baru ==========
read -p "👤 Masukkan nama user admin baru: " NEWUSER
if id "$NEWUSER" &>/dev/null; then
    echo "⚠️ User $NEWUSER sudah ada, melewati pembuatan."
else
    adduser --gecos "" "$NEWUSER"
    usermod -aG sudo "$NEWUSER"
    echo "✅ User $NEWUSER berhasil dibuat dan ditambahkan ke sudo."
fi

# ========== 2️⃣ Tambahkan SSH key ==========
read -p "🔑 Masukkan public SSH key (mulai dengan ssh-rsa atau ssh-ed25519): " SSHKEY
mkdir -p /home/$NEWUSER/.ssh
echo "$SSHKEY" > /home/$NEWUSER/.ssh/authorized_keys
chmod 700 /home/$NEWUSER/.ssh
chmod 600 /home/$NEWUSER/.ssh/authorized_keys
chown -R $NEWUSER:$NEWUSER /home/$NEWUSER/.ssh
echo "✅ SSH key berhasil ditambahkan untuk user $NEWUSER."

# ========== 3️⃣ Custom SSH Port ==========
read -p "📡 Masukkan port SSH custom (misal: 2222): " CUSTOM_PORT
if [[ "$CUSTOM_PORT" =~ ^[0-9]+$ ]] && [ "$CUSTOM_PORT" -ge 1024 ] && [ "$CUSTOM_PORT" -le 65535 ]; then
    echo "🔧 Mengubah SSH ke port $CUSTOM_PORT..."
    SSHD_CONF="/etc/ssh/sshd_config"
    cp "$SSHD_CONF" "${SSHD_CONF}.backup-$(date +%F-%H%M)"
    sed -i '/^#\?Port /d' "$SSHD_CONF"
    echo "Port $CUSTOM_PORT" >> "$SSHD_CONF"
else
    echo "⚠️ Port tidak valid. Menggunakan default 22."
    CUSTOM_PORT=22
fi

# ========== 4️⃣ Update & install tools ==========
export DEBIAN_FRONTEND=noninteractive
apt update -yq
apt -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade -yq
apt install -yq sudo curl wget nano htop ufw fail2ban unattended-upgrades auditd chrony

# ========== 5️⃣ Firewall ==========
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$CUSTOM_PORT"/tcp comment "SSH Custom"
ufw allow 80,443/tcp comment "HTTP/HTTPS"
ufw --force enable
echo "✅ Firewall aktif dan port $CUSTOM_PORT terbuka."

# ========== 6️⃣ Fail2Ban & Auto Update ==========
systemctl enable --now fail2ban || true
timedatectl set-timezone Asia/Jakarta
systemctl enable --now chrony
dpkg-reconfigure -f noninteractive unattended-upgrades

# ========== 7️⃣ Sudo tanpa password ==========
echo "$NEWUSER ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$NEWUSER
chmod 440 /etc/sudoers.d/90-$NEWUSER

# ========== 8️⃣ Restart SSH ==========
systemctl restart ssh || systemctl reload ssh
sleep 2

# ========== 9️⃣ Uji login SSH user baru ==========
IP=$(hostname -I | awk '{print $1}')
echo "🧪 Menguji koneksi SSH user baru..."
echo "   → $NEWUSER@$IP di port $CUSTOM_PORT"

# Uji port terbuka (tanpa login)
if nc -z 127.0.0.1 "$CUSTOM_PORT"; then
  echo "✅ Port $CUSTOM_PORT terbuka."
else
  echo "❌ Port $CUSTOM_PORT tidak terbuka! Batalkan disable root."
  exit 2
fi

# Uji koneksi SSH lokal (simulasi)
if su -c "ssh -o StrictHostKeyChecking=no -p $CUSTOM_PORT -T $NEWUSER@127.0.0.1 'echo ✅ Login test berhasil'" -s /bin/bash root; then
  echo "✅ Tes SSH user baru berhasil (login internal sukses)."
  AUTO_DISABLE_ROOT="yes"
else
  echo "⚠️ Tes SSH gagal — root login tidak akan dinonaktifkan otomatis."
  AUTO_DISABLE_ROOT="no"
fi

# ========== 🔟 Buat script disable root SSH ==========
cat <<EOF > /root/disable-root-ssh.sh
#!/bin/bash
# Nonaktifkan login root SSH
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh
echo "✅ Root SSH login telah dinonaktifkan."
EOF
chmod +x /root/disable-root-ssh.sh

# Jika auto test berhasil, langsung disable root
if [ "$AUTO_DISABLE_ROOT" == "yes" ]; then
  echo "🔒 Menonaktifkan root login otomatis..."
  /root/disable-root-ssh.sh
else
  echo "⚠️ Root login dibiarkan aktif agar kamu bisa perbaiki SSH manual."
fi

# ========== 🔚 Pesan Akhir ==========
echo ""
echo "=========================================="
echo "✅ Instalasi & Hardening Selesai!"
echo "  • User admin : $NEWUSER"
echo "  • Port SSH   : $CUSTOM_PORT"
echo "  • Root login : $( [ "$AUTO_DISABLE_ROOT" == "yes" ] && echo 'DINONAKTIFKAN ✅' || echo 'MASIH AKTIF ⚠️' )"
echo "  • Firewall   : Aktif (UFW)"
echo "  • Fail2Ban   : Aktif"
echo "  • AutoUpdate : Aktif"
echo "  • Timezone   : Asia/Jakarta"
echo "=========================================="
echo "💡 Tes login di MobaXterm:"
echo "   ssh -p $CUSTOM_PORT $NEWUSER@$IP"
echo ""
echo "📁 Jika root login masih aktif, kamu bisa manual jalankan:"
echo "   sudo /root/disable-root-ssh.sh"
echo "=========================================="
