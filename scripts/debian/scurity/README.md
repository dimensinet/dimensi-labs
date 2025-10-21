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
