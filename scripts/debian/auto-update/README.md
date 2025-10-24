# DIMENSI LABS — Debian 11 ➜ 12 (Fail-Safe Upgrade Mode)

---

## 🇮🇩 Tentang Proyek

**DIMENSI LABS — Debian 11 ➜ 12 (Fail-Safe Upgrade Mode)** adalah skrip otomatis aman untuk SSH,  
dirancang untuk meningkatkan sistem dari **Debian 11 (Bullseye)** ke **Debian 12 (Bookworm)** tanpa gangguan koneksi dan tanpa prompt interaktif.

Skrip ini memastikan proses peningkatan berlangsung mulus, bahkan saat pustaka sistem seperti **GLIBC (libc6)** diperbarui.

---

## 🇬🇧 About This Project

**DIMENSI LABS — Debian 11 ➜ 12 (Fail-Safe Upgrade Mode)** is a fully automated, SSH-safe upgrade script  
designed to transition systems from **Debian 11 (Bullseye)** to **Debian 12 (Bookworm)** seamlessly and non-interactively.

It ensures a safe process even when upgrading core components like **GLIBC (libc6)**.

---

## ✨ Fitur Utama / Main Features

| 🇮🇩 Fitur | 🇬🇧 Feature |
|-----------|-------------|
| 🔒 Aman untuk SSH — Tidak akan terputus selama upgrade | 🔒 SSH-Safe — No disconnection during upgrade |
| ⚙️ Tangani GLIBC secara aman sebelum upgrade penuh | ⚙️ Handles GLIBC upgrade safely before full upgrade |
| 🌐 Bilingual (Bahasa Indonesia & English) | 🌐 Bilingual (Indonesian & English) |
| 🧩 Mode non-interaktif, tanpa prompt | 🧩 Fully non-interactive mode, no prompts |
| 🔁 Reboot otomatis setelah selesai | 🔁 Automatic reboot after completion |
| 🎛️ Tampilan profesional dengan spinner kanan | 🎛️ Clean interface with right-aligned spinner |
| 🧼 Bersihkan cache & paket lama otomatis | 🧼 Automatically cleans old packages and cache |

---

## 🧱 Persyaratan / Requirements

Pastikan sistem memiliki paket berikut:
```
apt install -y curl gnupg2 lsb-release ca-certificates locales
```

Make sure the following packages are installed:
```
apt install -y curl gnupg2 lsb-release ca-certificates locales
```

---

## 🚀 Cara Menggunakan / How to Use

### 🇮🇩 Langkah:
1. Unduh skrip:
   ```bash
   wget https://github.com/dimensinet/dimensi-debian-upgrade/raw/main/upgrade-failsafe.sh -O upgrade-failsafe.sh
   chmod +x upgrade-failsafe.sh
   ```

2. Jalankan:
   ```bash
   sudo bash upgrade-failsafe.sh
   ```

3. Tunggu hingga proses selesai dan sistem reboot otomatis.

4. Setelah reboot, periksa versi Debian:
   ```bash
   lsb_release -a
   ```
   Hasil yang diharapkan:
   ```
   Distributor ID: Debian
   Description:    Debian GNU/Linux 12 (bookworm)
   Release:        12
   Codename:       bookworm
   ```

---

### 🇬🇧 Steps:
1. Download the script:
   ```bash
   wget https://github.com/dimensinet/dimensi-debian-upgrade/raw/main/upgrade-failsafe.sh -O upgrade-failsafe.sh
   chmod +x upgrade-failsafe.sh
   ```

2. Run it:
   ```bash
   sudo bash upgrade-failsafe.sh
   ```

3. Wait until the process finishes and the system reboots automatically.

4. After reboot, check your Debian version:
   ```bash
   lsb_release -a
   ```
   Expected output:
   ```
   Distributor ID: Debian
   Description:    Debian GNU/Linux 12 (bookworm)
   Release:        12
   Codename:       bookworm
   ```

---



## ⚠️ Catatan Penting / Important Notes

🇮🇩
- Lakukan **backup atau snapshot** sebelum menjalankan skrip.
- Skrip ini telah diuji di berbagai server Debian 11 (KVM, VPS, Bare Metal).
- Hindari menjalankan skrip lain selama proses berlangsung.

🇬🇧
- Always **perform a backup or snapshot** before running the script.
- Tested on multiple Debian 11 environments (KVM, VPS, Bare Metal).
- Avoid running other heavy operations during upgrade.

---

## 🧩 Lisensi / License

**License:** MIT  
You are free to use, modify, and distribute this script with attribution.

---

## 👨‍💻 Kredit / Credits

🇮🇩
Dikembangkan oleh **DIMENSI LABS**  
Pemelihara: [Your Name or GitHub Username]

🇬🇧
Developed by **DIMENSI LABS**  
Maintainer: [Your Name or GitHub Username]
