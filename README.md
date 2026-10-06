# Packet Tracer Offline

[README indo Version](README-ind.md)

Turn off internet access for **Cisco Packet Tracer** only, without
interfering with your browser or any other application. Packet Tracer
becomes fully offline while your internet keeps working normally.

Built on top of Windows Firewall. Nothing extra is installed, no other
settings are touched, and everything can be reverted any time.

---

## Method 1: Single Command (easiest)

Open **PowerShell as Administrator**, then copy paste this **single line**:

```powershell
irm https://raw.githubusercontent.com/nabilfp/PacketTracer-Offline/main/Install.ps1 | iex
```

Done. No need to browse into a folder, no need to download anything.

If you see **BERHASIL: Packet Tracer sekarang OFFLINE**, you are all set.

The script automatically searches for Cisco Packet Tracer on **all drives**
(not only C:), checking the registry and scanning every fixed drive, so it
works even if Packet Tracer is installed on drive D: or anywhere else.

---

## Method 2: Manual

If you prefer not to download the script at all, paste this in an
administrator PowerShell:

```powershell
$exe = (Get-ChildItem "$env:ProgramFiles\Cisco Packet Tracer*" -Directory | Select-Object -First 1).FullName + '\bin\PacketTracer.exe'
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -Direction Outbound -Action Block -Program $exe -Profile Any
New-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' -Direction Inbound  -Action Block -Program $exe -Profile Any
```

The first line detects the Packet Tracer folder name automatically, so it
is safe for any version.

> The snippet above only looks inside `Program Files` on the current drive.
> If Packet Tracer is installed on another drive (e.g. `D:\Program Files`),
> point to the full path manually:

```powershell
$exe = 'C:\Program Files\Cisco Packet Tracer 8.2.2\bin\PacketTracer.exe'
```

---

## How to go back online

PowerShell as Administrator, one line:

```powershell
irm https://raw.githubusercontent.com/nabilfp/PacketTracer-Offline/main/Uninstall.ps1 | iex
```

Or without downloading the script:

```powershell
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' | Remove-NetFirewallRule
```

---

## Check the status

PowerShell (Administrator not required):

```powershell
Get-NetFirewallRule -DisplayName 'Packet Tracer Offline Shield' | Select-Object Direction, Action
```

If rows `Outbound Block` and `Inbound Block` appear, Packet Tracer is
offline. If the result is empty, it is back online.

---

## Run it without opening an Administrator window

If you do not want to open an Administrator window, run `Install.ps1` with
right-click > Run with PowerShell, then approve the UAC prompt.

---

## Notes

- **Close Packet Tracer first** before enabling the rule. Firewall rules
  only apply to new connections.
- Safe to run repeatedly, no duplicate rules will be created.
- Nothing outside of Packet Tracer is modified. Browser, Wi-Fi, and every
  other application keep working as usual.
- The Packet Tracer installer itself adds an `Allow` rule for Packet
  Tracer, but in Windows Firewall **Block wins over Allow**, so the rules
  from this repo stay effective.