# Auto Update Debian 11 → 12 (Bookworm)
### 🧩 by [Dimensi Labs](https://github.com/dimensinet/dimensi-labs)

Script ini dibuat untuk melakukan **upgrade otomatis dan aman dari Debian 11 (Bullseye) ke Debian 12 (Bookworm)**  
dengan tampilan **berwarna, animasi progres**, dan proteksi dari **disconnect SSH**.

---

## ✨ Fitur Utama
| Fitur | Deskripsi |
|-------|------------|
| 🎨 Warna Otomatis | Terminal otomatis aktif warna ANSI, bahkan di dalam `screen` |
| 🌀 Spinner Animasi | Menampilkan animasi saat proses panjang agar tidak membosankan |
| 📊 Progress Bar | Menampilkan status upgrade secara visual |
| 💾 Auto Backup | Semua konfigurasi penting dibackup sebelum upgrade |
| 🧠 Smart Detect | Deteksi otomatis apakah dijalankan di `screen` atau `tmux` |
| 🔒 Anti Disconnect | Aman digunakan melalui SSH |
| ☕ Friendly UX | Bahasa santai tapi tetap profesional |

---

## 📦 Instalasi

### 1️⃣ Download Script
Gunakan `wget` untuk mengunduh langsung dari repository ini:
```bash
mkdir -p /opt/dimensi-labs/debian/
wget -O /opt/dimensi-labs/debian/auto-update-debian11-to-12.sh https://raw.githubusercontent.com/dimensinet/dimensi-labs/main/scripts/debian/auto-update/auto-update-debian11-to-12.sh
```

### 2️⃣ Beri Izin Eksekusi
```bash
chmod +x /opt/dimensi-labs/debian/auto-update-debian11-to-12.sh
```

### 3️⃣ (Opsional) Buat Shortcut Command
Agar bisa dijalankan dari mana saja tanpa nulis `.sh`:
```bash
ln -sf /opt/dimensi-labs/debian/auto-update-debian11-to-12.sh /usr/local/bin/auto-update-debian11-to-12
```

---

## 🚀 Cara Menjalankan

> ⚠️ **Disarankan dijalankan di dalam `screen` atau `tmux` agar tidak disconnect saat upgrade.**

Jalankan langkah ini:

```bash
apt install screen -y
screen -S upgrade -T xterm-256color
auto-update-debian11-to-12
```

Atau jika belum membuat shortcut:

```bash
bash /opt/dimensi-labs/debian/auto-update-debian11-to-12.sh
```

---

## 🧱 Struktur Script
📁 `/opt/dimensi-labs/debian/auto-update-debian11-to-12.sh`

### 📋 Langkah-langkah dalam script:
1. **Cek root & screen**
2. **Aktifkan mode warna ANSI**
3. **Backup konfigurasi penting**
4. **Update sistem Debian 11**
5. **Deteksi mirror terbaik (lokal/global)**
6. **Ganti sources.list ke Debian 12**
7. **Update repo Debian 12**
8. **Full upgrade otomatis**
9. **Hapus paket lama**
10. **Reboot otomatis setelah sukses**

---

## 📂 Lokasi Backup
Sebelum upgrade, semua file penting disimpan di:
```
/root/backup-before-upgrade-YYYY-MM-DD_HH-MM/
```

---


## 🧑‍💻 Dibuat Oleh
**Dimensi Labs**  
> Open-source automation tools for Linux, Mikrotik, and server management.  
> https://github.com/dimensinet

---

## ⚙️ Lisensi
MIT License © 2025 [Dimensi Labs](https://github.com/dimensinet)
