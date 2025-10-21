# 🛡️ Debian Secure Setup v3.3-UI
### Hardened Debian 11/12 Auto Configuration Script  
> By [dimensi.net](https://dimensi.net) — with ❤️ powered by ChatGPT

---

## 🎯 Tujuan
Script ini mengonfigurasi VPS Debian 11/12 agar **aman, optimal, dan siap produksi** secara otomatis.  
Cocok untuk server pribadi, hosting, API, atau VPN gateway.

---

## 🚀 Fitur Utama

| Fitur | Deskripsi |
|--------|------------|
| 🔑 **SSH Key Only Login** | Hanya login dengan SSH key (tanpa password) |
| 🔒 **Disable Root SSH** | Menonaktifkan login root setelah setup |
| 📡 **Custom SSH Port** | Mengganti port SSH default (misal `9822`) |
| 🧱 **Firewall UFW** | Menutup semua port kecuali 80, 443, dan port SSH custom |
| 🚫 **Fail2Ban** | Memblok IP otomatis saat gagal login berkali-kali |
| 🔄 **Auto Security Update** | Update otomatis paket keamanan |
| 🕓 **Chrony + Timezone** | Sinkronisasi waktu otomatis ke `Asia/Jakarta` |
| 🎨 **Tampilan Berwarna & Progress Bar** | UI terminal interaktif dengan animasi & delay |

---

## 🧰 Fitur Keamanan Aktif
| Komponen | Status |
|-----------|---------|
| SSH Root Login | ❌ Dinonaktifkan otomatis |
| SSH Key Login | ✅ Aktif |
| Firewall UFW | ✅ Aktif (default deny) |
| Fail2Ban | ✅ Aktif |
| Auto Update | ✅ Aktif |
| Timezone | ✅ Asia/Jakarta |
| User Admin | ✅ Punya sudo tanpa password |

---

## ⚙️ Persiapan

Sebelum mulai:
- Login sebagai **root**
- Pastikan sistem menggunakan **Debian 11 atau 12**
- Siapkan **SSH public key**
- Pastikan **koneksi internet aktif**
- Punya akses **console VPS** (untuk jaga-jaga jika SSH terputus)

---

## 📦 Instalasi Lengkap

### 1️⃣ Login ke VPS sebagai root
```bash
ssh root@<IP_SERVER>
```

---

### 2️⃣ Unduh script

Gunakan `wget` atau `curl`:

```bash
wget -O install-secure-v3.3-ui.sh https://raw.githubusercontent.com/dimensinet/secure-debian/main/install-secure-v3.3-ui.sh
```

> 💡 Ganti URL sesuai lokasi repositori kamu jika berbeda.

---

### 3️⃣ Jalankan script

```bash
chmod +x install-secure-v3.3-ui.sh
bash install-secure-v3.3-ui.sh
```

---

### 4️⃣ Ikuti wizard interaktif
Script akan meminta input:
```
👤 Masukkan nama user admin baru: dimensi
🔑 Masukkan public SSH key: ssh-ed25519 AAAA...
📡 Masukkan port SSH custom (misal: 9822)
```

Kemudian akan tampil animasi progress seperti ini:
```
=== Mengaktifkan firewall UFW ===
Mengaktifkan UFW.......... done.
✅ Firewall aktif dan port 9822 terbuka.
```

---

### 5️⃣ Tunggu hingga selesai  
Script akan otomatis:
- Membuat user sudo baru  
- Mengganti port SSH  
- Mengaktifkan firewall & Fail2Ban  
- Menonaktifkan root SSH login (setelah tes login sukses)

---

## ✅ Hasil Akhir (contoh output)

```
==========================================
✅ Instalasi & Hardening Selesai!
  • User admin : dimensi
  • Port SSH   : 9822
  • Root login : DINONAKTIFKAN ✅
  • Firewall   : Aktif (UFW)
  • Fail2Ban   : Aktif
  • AutoUpdate : Aktif
  • Timezone   : Asia/Jakarta
==========================================
💡 Tes login di MobaXterm:
   ssh -p 9822 dimensi@41.216.178.67

📁 Jika root login masih aktif, jalankan:
   sudo /root/disable-root-ssh.sh
==========================================
```

---

## 🔍 Verifikasi Hasil

Login menggunakan user baru:
```bash
ssh -p 9822 dimensi@<IP_SERVER>
```

Cek status keamanan:
```bash
sudo ufw status verbose
sudo fail2ban-client status sshd
sudo systemctl status unattended-upgrades
sudo timedatectl
```

---

## 📊 Contoh Output Verifikasi

```
Status: active
To                         Action      From
--                         ------      ----
9822/tcp                   ALLOW IN    Anywhere                   # SSH Custom
80,443/tcp                 ALLOW IN    Anywhere                   # HTTP/HTTPS

Status for the jail: sshd
|- Currently banned: 0
|- Total failed:     4

Local time: Wed 2025-10-22 01:28:41 WIB
Time zone: Asia/Jakarta (WIB, +0700)
NTP service: active
```

---

## 💾 Backup Snapshot VPS

Setelah instalasi sukses, **buat snapshot VPS** dengan nama:
```
secure-base-2025-10-22
```
Tujuannya agar kamu bisa restore kapan pun tanpa setup ulang.

---

## 🧩 Troubleshooting

| Masalah | Solusi |
|----------|---------|
| ❌ SSH tidak bisa login | Akses **console VPS**, ubah `/etc/ssh/sshd_config` → `PermitRootLogin yes`, lalu `systemctl restart ssh` |
| ⚠️ UFW inactive | Jalankan `sudo ufw --force enable` |
| ⏰ Waktu salah | Jalankan `sudo timedatectl set-timezone Asia/Jakarta` |
| 🔒 Root masih bisa login | Jalankan `sudo /root/disable-root-ssh.sh` |

---

## 🗂️ Struktur File yang Dibuat

```
├── install-secure-v3.3-ui.sh
├── /root/disable-root-ssh.sh
└── /etc/sudoers.d/90-<user>
```

---

## 👨‍💻 Pengembang

| Info | Detail |
|------|--------|
| Author | ChatGPT x dimensi.net |
| Versi | v3.3-UI |
| Kompatibilitas | Debian 11 / Debian 12 |
| Lisensi | MIT License |

---

## 🖥️ Tampilan Demo (Terminal)

```
🚀 Memulai konfigurasi keamanan Debian 11/12 (v3.3-UI)...
=== Membuat user admin baru ===
Menambahkan user dimensi.......... done.
✅ User dimensi berhasil dibuat.
=== Mengatur port SSH custom ===
Mengubah konfigurasi SSH.......... done.
✅ Firewall aktif dan port 9822 terbuka.
🔒 Menonaktifkan root login otomatis...
✅ Root SSH login telah dinonaktifkan.
```

---

## ⚡ Ringkasan Cepat

| Langkah | Perintah |
|----------|-----------|
| Unduh script | `wget -O install-secure-v3.3-ui.sh <URL>` |
| Jalankan script | `bash install-secure-v3.3-ui.sh` |
| Tes login SSH | `ssh -p 9822 dimensi@<IP_SERVER>` |
| Cek firewall | `sudo ufw status verbose` |
| Disable root manual | `sudo /root/disable-root-ssh.sh` |

---

## 🏁 Hasil Akhir
🎉 Server kamu sekarang:
- Aman dari brute-force  
- Diperbarui otomatis  
- Root login nonaktif  
- Siap digunakan untuk produksi  

---

## 🌐 Repositori
📦 [https://github.com/dimensinet/secure-debian](https://github.com/dimensinet/secure-debian)

---

> © 2025 [dimensi.net](https://dimensi.net) — crafted with ❤️ and shell magic.
