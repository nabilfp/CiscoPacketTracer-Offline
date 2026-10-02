$ErrorActionPreference = 'Stop'
$RuleName = 'Packet Tracer Offline Shield'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Meminta hak Administrator (UAC), approve saja...' -ForegroundColor Yellow
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    ) -Wait
    exit
}

function Get-PacketTracerExe {
    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
        if (-not $root) { continue }
        $dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'Cisco Packet Tracer*' -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            $exe = Join-Path $dir.FullName 'bin\PacketTracer.exe'
            if (Test-Path -LiteralPath $exe) { return $exe }
        }
    }
    return $null
}

$mainExe = Get-PacketTracerExe
if (-not $mainExe) {
    Write-Host ''
    Write-Host 'GAGAL: Packet Tracer tidak ditemukan.' -ForegroundColor Red
    Write-Host 'Pastikan Cisco Packet Tracer sudah terinstall di Program Files.'
    Write-Host ''
    Read-Host 'Tekan Enter untuk menutup'
    exit 1
}

$binDir = Split-Path -Parent $mainExe
$targets = @($mainExe, (Join-Path $binDir 'QtWebEngineProcess.exe')) |
    Where-Object { Test-Path -LiteralPath $_ }

Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule

foreach ($exe in $targets) {
    foreach ($direction in @('Outbound', 'Inbound')) {
        New-NetFirewallRule -DisplayName $RuleName -Direction $direction `
            -Action Block -Program $exe -Profile Any -Enabled True | Out-Null
    }
}

Write-Host ''
Write-Host 'BERHASIL: Packet Tracer sekarang OFFLINE.' -ForegroundColor Green
Write-Host 'Internet browser dan aplikasi lain TIDAK terganggu.'
Write-Host ''
Write-Host 'Aturan yang dibuat:'
foreach ($exe in $targets) { Write-Host ("  - " + $exe) }
Write-Host ''
Write-Host 'Cek status:'
Write-Host ("  Get-NetFirewallRule -DisplayName '" + $RuleName + "'")
Write-Host 'Kembalikan ke normal: .\Uninstall.ps1'
Write-Host ''
Read-Host 'Tekan Enter untuk menutup'