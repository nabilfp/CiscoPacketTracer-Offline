# Packet Tracer Offline

Mematikan akses internet untuk **Cisco Packet Tracer** saja, tanpa mengganggu
browser dan aplikasi lain. Packet Tracer jadi sepenuhnya offline, internet
kamu tetap jalan seperti biasa.

Berbasis Windows Firewall. Tidak install aplikasi tambahan, tidak ubah
setting lain, dan bisa dikembalikan kapan saja.

---

## What's inside

| File | Fungsi |
| --- | --- |
| `Install.ps1` | Mengaktifkan mode offline (butuh Administrator) |
| `Uninstall.ps1` | Mengembalikan Packet Tracer ke online |

---

## Cara 1: Instant (paling gampang)

1. Klik kanan `Install.ps1` > **Run with PowerShell**
2. Kalau muncul permintaan izin Administrator (UAC), pilih **Yes**
3. Selesai

Kalau klik kanan tidak muncul opsi Run with PowerShell, buka PowerShell,
pindah ke folder ini, lalu jalankan:

```powershell
.\Install.ps1
```

Script akan otomatis minta izin Administrator sendiri, jadi approve saja
jika UAC muncul.

---

## Cara 2: Manual

Buka **PowerShell sebagai Administrator** (klik kanan Start > Terminal
(Admin), atau Windows + X > Windows PowerShell (Admin)).

Copy paste seluruh baris ini:

```powershell
$exe = (Get-ChildItem "$env:ProgramFiles\Cisco Packet Tracer*" -Directory | Select-Object -First 1).FullName + '\bin\PacketTracer.exe'
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -Direction Outbound -Action Block -Program $exe -Profile Any
New-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -Direction Inbound  -Action Block -Program $exe -Profile Any
```

Selesai. Kalau baris pertama error karena folder tidak ketemu, pakai path
lengkap, contoh:

```powershell
$exe = 'C:\Program Files\Cisco Packet Tracer 8.2.2\bin\PacketTracer.exe'
```

---

## Cara mengembalikan ke online

Sama persis, PowerShell sebagai Administrator:

```powershell
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' | Remove-NetFirewallRule
```

Atau jalankan `Uninstall.ps1`.

---

## Cek status

PowerShell (Administrator tidak wajib):

```powershell
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' |
    Select-Object Direction, Action, Enabled
```

Kalau ada baris `Outbound Block` dan `Inbound Block`, berarti sedang offline.
Kalau kosong, berarti sudah online.

---

## Catatan

- **Tutup Packet Tracer dulu** sebelum mengaktifkan. Aturan berlaku untuk
  koneksi baru.
- Versi Packet Tracer tidak penting, script mencari folder
  `Cisco Packet Tracer*` secara otomatis.
- Tidak ada yang diubah di luar Packet Tracer. Browser, Wi-Fi, dan
  aplikasi lain tetap normal.