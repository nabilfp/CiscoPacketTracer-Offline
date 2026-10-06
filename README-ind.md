# Packet Tracer Offline

[README English Version](README.md)

Mematikan akses internet untuk **Cisco Packet Tracer** saja, tanpa mengganggu
browser dan aplikasi lain. Packet Tracer jadi sepenuhnya offline, internet
kamu tetap jalan seperti biasa.

Berbasis Windows Firewall. Tidak install aplikasi tambahan, tidak ubah
setting lain, dan bisa dikembalikan kapan saja.

---

## Cara 1: Satu Command (paling gampang)

Buka **PowerShell sebagai Administrator**, lalu copy paste **satu baris** ini:

```powershell
irm https://raw.githubusercontent.com/nabilfp/PacketTracer-Offline/main/Install.ps1 | iex
```

Selesai. Tidak perlu masuk folder, tidak perlu download file.

Kalau muncul tulisan **SUCCESS: Packet Tracer is now OFFLINE**, beres.

Skrip otomatis mencari Cisco Packet Tracer di **semua drive** (bukan cuma
C:). Dicek lewat registry dan isi tiap drive, jadi tetap jalan walau
Packet Tracer di-install di drive D: atau di tempat lain.

---

## Cara 2: Manual

Kalau mau tanpa download skrip sama sekali. Paste di PowerShell Administrator:

```powershell
$exe = (Get-ChildItem "$env:ProgramFiles\Cisco Packet Tracer*" -Directory | Select-Object -First 1).FullName + '\bin\PacketTracer.exe'
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -Direction Outbound -Action Block -Program $exe -Profile Any
New-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -Direction Inbound  -Action Block -Program $exe -Profile Any
```

Baris pertama mencari nama folder Packet Tracer secara otomatis, jadi aman
untuk versi apa pun.

> Baris di atas hanya mencari di `Program Files` pada drive aktif. Kalau
> Packet Tracer ada di drive lain (misal `D:\Program Files`), pakai path
> lengkap:

```powershell
$exe = 'C:\Program Files\Cisco Packet Tracer 8.2.2\bin\PacketTracer.exe'
```

---

## Cara mengembalikan ke online

PowerShell Administrator, satu baris:

```powershell
irm https://raw.githubusercontent.com/nabilfp/PacketTracer-Offline/main/Uninstall.ps1 | iex
```

Atau tanpa download skrip:

```powershell
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' | Remove-NetFirewallRule
```

---

## Cek status

PowerShell (Administrator tidak wajib):

```powershell
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' | Select-Object Direction, Action
```

Kalau ada baris `Outbound Block` dan `Inbound Block`, berarti sedang offline.
Kalau kosong, berarti sudah online.

---

## Cara tanpa buka Administrator

Kalau males buka Administrator, jalankan `Install.ps1` dengan klik kanan
> Run with PowerShell, lalu approve permintaan UAC yang muncul.

---

## Catatan

- **Tutup Packet Tracer dulu** sebelum mengaktifkan. Aturan berlaku untuk
  koneksi baru.
- Aman dijalankan berulang kali, tidak akan membuat rule duplikat.
- Tidak ada yang diubah di luar Packet Tracer. Browser, Wi-Fi, dan
  aplikasi lain tetap normal.
- Installer Packet Tracer sendiri membuat aturan `Allow` untuk
  Packet Tracer, tapi di Windows Firewall **Block menang atas Allow**,
  jadi aturan di repo ini tetap efektif.