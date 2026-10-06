$ErrorActionPreference = 'Stop'
$RuleName = 'Packet Tracer Offline Shield'
$script:Diag = New-Object System.Collections.Generic.List[string]

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($PSCommandPath) {
        Write-Host 'Requesting Administrator rights (UAC), please approve...' -ForegroundColor Yellow
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
        ) -Wait
        return
    }
    Write-Host ''
    Write-Host 'FAILED: must be run as Administrator.' -ForegroundColor Red
    Write-Host 'Right-click Start > Terminal (Admin), then try again.'
    Write-Host ''
    return
}

function Test-PacketTracerFolder {
    param([string]$Folder)

    if (-not $Folder) { return $null }
    if (-not (Test-Path -LiteralPath $Folder -PathType Container -ErrorAction SilentlyContinue)) { return $null }

    foreach ($rel in @('bin\PacketTracer.exe', 'bin\PacketTracer64.exe', 'PacketTracer.exe')) {
        $exe = Join-Path $Folder $rel
        if (Test-Path -LiteralPath $exe -PathType Leaf -ErrorAction SilentlyContinue) { return $exe }
    }
    return $null
}

function Get-DriveRoots {
    $roots = @()
    try {
        foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
            if (-not $drive.IsReady) { continue }
            if ($drive.DriveType -notin @([System.IO.DriveType]::Fixed, [System.IO.DriveType]::Removable)) { continue }
            $root = $drive.RootDirectory.FullName
            if ($root) { $roots += $root }
        }
    } catch {
        $script:Diag.Add('Unable to enumerate drives: ' + $_.Exception.Message)
    }
    if ($roots.Count -eq 0) { $roots = @("$env:SystemDrive\") }
    return @($roots | Select-Object -Unique)
}

function Find-PacketTracerInRegistry {
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )

    foreach ($key in $keys) {
        if (-not (Test-Path -LiteralPath $key -ErrorAction SilentlyContinue)) { continue }
        foreach ($app in @(Get-ChildItem -LiteralPath $key -ErrorAction SilentlyContinue)) {
            $props = Get-ItemProperty -LiteralPath $app.PSPath -ErrorAction SilentlyContinue
            if (-not $props) { continue }
            if ([string]$props.DisplayName -notlike '*Packet Tracer*') { continue }

            foreach ($field in @($props.InstallLocation, $props.DisplayIcon, $props.UninstallString)) {
                if (-not $field) { continue }
                $raw = ([string]$field).Trim()
                $path = $null

                $exeInField = [regex]::Match($raw, '(?i)"?((?:[a-z]:|\\\\)[^"]*?\.exe)"?')
                if ($exeInField.Success) {
                    $path = $exeInField.Groups[1].Value.Trim()
                } elseif ($raw -notmatch '\.exe') {
                    $path = $raw.Trim('"') -replace ',\d+\s*$', ''
                }
                if (-not $path) { continue }

                if (Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue) {
                    if ((Split-Path -Leaf $path) -like 'PacketTracer*.exe') { return $path }
                    $exe = Test-PacketTracerFolder (Split-Path -Parent $path)
                    if ($exe) { return $exe }
                } else {
                    $exe = Test-PacketTracerFolder $path
                    if ($exe) { return $exe }
                }
            }
            $script:Diag.Add("Found 'Packet Tracer' in the uninstall registry, but the stored install path is missing or invalid.")
        }
    }
    return $null
}

function Find-PacketTracerInFolder {
    param([string]$BasePath)

    if (-not (Test-Path -LiteralPath $BasePath -PathType Container -ErrorAction SilentlyContinue)) { return $null }

    $dirs = @(Get-ChildItem -LiteralPath $BasePath -Directory -Filter 'Cisco Packet Tracer*' -ErrorAction SilentlyContinue)
    foreach ($dir in $dirs) {
        $exe = Test-PacketTracerFolder $dir.FullName
        if ($exe) { return $exe }
        $script:Diag.Add("A 'Cisco Packet Tracer*' folder was found at $($dir.FullName) but PacketTracer.exe (or bin\PacketTracer.exe / bin\PacketTracer64.exe) is missing inside.")
    }
    return $null
}

function Find-PacketTracerByScanning {
    param(
        [string]$Root,
        [int]$Depth = 5
    )

    $skip = @('Windows', 'Windows.old', 'Windows10Upgrade', 'Recovery', '$WinREAgent',
              'MSOCache', 'Config.Msi', 'node_modules', '.git', '$Recycle.Bin',
              'System Volume Information', 'Documents and Settings', 'All Users')

    $topDirs = @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $skip -notcontains $_.Name })

    foreach ($top in $topDirs) {
        $exe = Test-PacketTracerFolder $top.FullName
        if ($exe) { return $exe }
        $script:Diag.Add("A 'Cisco Packet Tracer*' folder was found at $($top.FullName) but PacketTracer.exe (or bin\PacketTracer.exe / bin\PacketTracer64.exe) is missing inside.")

        $dirs = @()
        try {
            $dirs = @(Get-ChildItem -LiteralPath $top.FullName -Directory -Recurse -Depth $Depth `
                -Filter 'Cisco Packet Tracer*' -ErrorAction SilentlyContinue)
        } catch { }
        foreach ($dir in ($dirs | Sort-Object { $_.FullName.Length })) {
            $exe = Test-PacketTracerFolder $dir.FullName
            if ($exe) { return $exe }
            $script:Diag.Add("A 'Cisco Packet Tracer*' folder was found at $($dir.FullName) but PacketTracer.exe (or bin\PacketTracer.exe / bin\PacketTracer64.exe) is missing inside.")
        }
    }
    return $null
}

function Get-PacketTracerExe {
    if ($env:PacketTracerExe) {
        $path = ([string]$env:PacketTracerExe).Trim().Trim('"')
        if (Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue) { return @{Found = $true; Path = $path} }
        $fromFolder = Test-PacketTracerFolder $path
        if ($fromFolder) { return @{Found = $true; Path = $fromFolder} }
        Write-Host ("WARNING: PacketTracerExe variable value is not valid: " + $path) -ForegroundColor Yellow
    }

    $roots = Get-DriveRoots
    if (-not $roots) {
        return @{Found = $false; Hint = 'No readable drive was found to search.'}
    }
    Write-Host ("Searching for Cisco Packet Tracer on all drives: " + ($roots -join ' ')) -ForegroundColor DarkGray

    $found = Find-PacketTracerInRegistry
    if ($found) { return @{Found = $true; Path = $found} }

    foreach ($root in $roots) {
        foreach ($pf in @('Program Files', 'Program Files (x86)')) {
            $found = Find-PacketTracerInFolder (Join-Path $root $pf)
            if ($found) { return @{Found = $true; Path = $found} }
        }
        $found = Find-PacketTracerInFolder $root
        if ($found) { return @{Found = $true; Path = $found} }
    }

    foreach ($root in $roots) {
        Write-Host ("  Scanning contents of " + $root + " (may take a few seconds)...") -ForegroundColor DarkGray
        $found = Find-PacketTracerByScanning -Root $root
        if ($found) { return @{Found = $true; Path = $found} }
    }

    return @{Found = $false; Hint = "No folder named 'Cisco Packet Tracer*' containing PacketTracer.exe was found on any drive."}
}

$result = Get-PacketTracerExe
if (-not $result.Found) {
    Write-Host ''
    Write-Host 'FAILED: Packet Tracer was not found on any drive.' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Reason:' -ForegroundColor Yellow
    Write-Host ("  - " + $result.Hint)
    $script:Diag | Select-Object -Unique | ForEach-Object { Write-Host ("  - " + $_) }
    Write-Host ''
    Write-Host 'Possible causes:' -ForegroundColor Yellow
    Write-Host '  - Cisco Packet Tracer is not installed.'
    Write-Host '  - It is installed deeper than 5 levels below the drive root.'
    Write-Host '  - The Packet Tracer folder exists but the PacketTracer.exe file is missing or blocked.'
    Write-Host ''
    Write-Host 'To force a path, set it and run again:'
    Write-Host "  `$env:PacketTracerExe = 'D:\path\to\bin\PacketTracer.exe'" -ForegroundColor Yellow
    Write-Host '  irm https://raw.githubusercontent.com/nabilfp/PacketTracer-Offline/main/Install.ps1 | iex'
    Write-Host ''
    return
}

$mainExe = $result.Path
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
Write-Host 'SUCCESS: Packet Tracer is now OFFLINE.' -ForegroundColor Green
Write-Host 'Your browser and other apps are NOT affected.'
Write-Host ''
Write-Host 'Rules created:'
foreach ($exe in $targets) { Write-Host ("  - " + $exe) }
Write-Host ''
Write-Host 'To restore internet access:'
Write-Host "  irm https://raw.githubusercontent.com/nabilfp/PacketTracer-Offline/main/Uninstall.ps1 | iex"
Write-Host ''