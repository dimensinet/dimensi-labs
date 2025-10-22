# Dimensi Secure Chill — Debian 12

**Dimensi Secure Chill v7.2** adalah skrip interaktif untuk mengamankan server Debian 12.  
Gaya outputnya santai & sinematik: loading bar, efek "typewriter" saat menampilkan SSH key, jeda antar langkah agar proses mudah diikuti — tetapi semua tindakan yang dijalankan serius dan aman.

## Fitur utama
- Aman dari lockout (tidak menonaktifkan PasswordAuthentication jika belum ada SSH key valid)
- Menampilkan SSH public key dengan efek typewriter
- Loading bar saat startup (±5 detik)
- Menambahkan SSH public key manual / dari GitHub
- Mengamankan permission folder `/root/.ssh`
- Memperbarui konfigurasi `sshd_config` (Port, PubkeyAuthentication, dsb.)
- Memasang & mengaktifkan `fail2ban`
- Menerapkan kebijakan password kuat (libpam-pwquality, min 15 char + simbol)
- Mengaktifkan `unattended-upgrades`
- Menerapkan kernel hardening via sysctl
- Logging lengkap ke `/var/log/dimensi-secure.log`
- Ringkasan akhir rapi dan berwarna

## Requirements
- Server Debian 12 (tested)
- Akses root (script harus dijalankan sebagai root)
- Koneksi internet (untuk menginstall paket dan mengambil key dari GitHub jika dipilih)

> Script berusaha menggunakan only-bash (tanpa `bc`) sehingga kompatibel di sistem standar Debian.

## Instalasi (contoh)
Salin file ke server kamu (atau gunakan wget/curl langsung):

```bash
mkdir -p /opt/dimensi-labs/debian
# contoh: unduh dari repository (ganti URL dengan raw file di repo kamu)
wget -O /opt/dimensi-labs/debian/scure-debian12-chill-v7.2.sh https://raw.githubusercontent.com/<user>/<repo>/main/scripts/debian/scurity/scure-debian12-chill-v7.2.sh

chmod +x /opt/dimensi-labs/debian/scure-debian12-chill-v7.2.sh
```

## Menjalankan
Jalankan langsung (tidak perlu screen):
```bash
bash /opt/dimensi-labs/debian/scure-debian12-chill-v7.2.sh
```

Script akan:
1. Menampilkan loading bar
2. Memperbaiki permission `/root/.ssh`
3. Memeriksa/menambahkan SSH key
4. Meminta port SSH (default sesuai konfigurasi)
5. Menginstall & enable fail2ban, unattended-upgrades, pwquality
6. Meminta kamu mengganti/validasi password root
7. Menerapkan kernel hardening
8. Menampilkan ringkasan akhir dan menyimpan log ke `/var/log/dimensi-secure.log`

## Verifikasi & Troubleshooting
- Lihat log utama:
```bash
tail -F /var/log/dimensi-secure.log
```

- Verifikasi Fail2Ban:
```bash
fail2ban-client status sshd
```

- Cek konfigurasi SSH:
```bash
sshd -T | egrep 'port|passwordauthentication|permitrootlogin|pubkeyauthentication'
```

- Jika progress bar tidak berjalan sempurna, pastikan terminal mendukung ANSI colors (most do).  
- Jika script gagal pada pengunduhan GitHub key, periksa koneksi internet & username yang dimasukkan.

## Keamanan penting
- **Tes login SSH key di sisi client sebelum logout** — script hanya menonaktifkan password jika ada SSH key valid.  
- Pastikan kamu punya akses ke SSH key yang ditambahkan. Jika tidak yakin, pilih opsi lewati (password tetap aktif) dan tambahkan key dulu lewat console provider.
- Backup file konfigurasi ada di `/root/backups/scure-before-<timestamp>/`

## Contoh penggunaan (one-liner)
```bash
mkdir -p /opt/dimensi-labs/debian && \
wget -O /opt/dimensi-labs/debian/scure-debian12-chill-v7.2.sh https://raw.githubusercontent.com/<user>/<repo>/main/scripts/debian/scurity/scure-debian12-chill-v7.2.sh && \
chmod +x /opt/dimensi-labs/debian/scure-debian12-chill-v7.2.sh && \
bash /opt/dimensi-labs/debian/scure-debian12-chill-v7.2.sh
```

## Contributing
Silakan fork repo dan buat PR. Masukan fitur: tema warna, integrasi Telegram/email alert, atau profiling untuk distro lain.

## License
MIT — bebas dipakai dan dimodifikasi. Sertakan credit ke Dimensi Labs (optional).
