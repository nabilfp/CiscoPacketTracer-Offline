$ErrorActionPreference = 'Stop'
$RuleName = 'Packet Tracer Offline Shield'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Write-Host 'Meminta hak Administrator (UAC), approve saja...' -ForegroundColor Yellow
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
        ) -Wait
        return
    }
    Write-Host ''
    Write-Host 'GAGAL: harus dijalankan sebagai Administrator.' -ForegroundColor Red
    Write-Host 'Klik kanan Start > Terminal (Admin), lalu ulangi.'
    Write-Host ''
    return
}

$removed = @(Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue)
$count = $removed.Count
if ($count -gt 0) {
    $removed | Remove-NetFirewallRule
}

Write-Host ''
Write-Host 'BERHASIL: Packet Tracer sudah online lagi.' -ForegroundColor Green
Write-Host ("Aturan dihapus: " + $count)
Write-Host ''