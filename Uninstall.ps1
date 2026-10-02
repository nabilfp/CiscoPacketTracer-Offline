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

$removed = @(Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue)
$count = $removed.Count
if ($count -gt 0) {
    $removed | Remove-NetFirewallRule
}

Write-Host ''
Write-Host 'BERHASIL: Packet Tracer sudah online lagi.' -ForegroundColor Green
Write-Host ("Aturan dihapus: " + $count)
Write-Host ''
Read-Host 'Tekan Enter untuk menutup'