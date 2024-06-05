$Hostname = $env:COMPUTERNAME

$MonitorsCMD = Get-CimInstance -ClassName WmiMonitorID -Namespace root\wmi
$SerialNumberCMD = Get-CimInstance -ClassName Win32_BIOS

$Monitors = $MonitorsCMD
$SerialNumber = $SerialNumberCMD.SerialNumber

$LogFile = "C:\monitors.txt"

$networkInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object Description, MACAddress, IPAddress


# Ensure the directory exists
$LogDir = Split-Path $LogFile
if (!(Test-Path -Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
}

Write-Host ""
Write-Host "Hostname: $Hostname"
Write-Host "BIOS Serial Number: $SerialNumber"
Write-Host ""
Write-Host "=================================================="
Write-Host "Name, Serial"

foreach ($Monitor in $Monitors) {
    $nm = $Monitor.UserFriendlyName -notmatch '^0$'
    $Name = ""
    if ($nm -is [System.Array]) {
        foreach ($char in $nm) {
            $Name += [char]$char
        }
    }

    $sr = $Monitor.SerialNumberID -notmatch '^0$'
    $Serial = ""
    if ($sr -is [System.Array]) {
        foreach ($char in $sr) {
            $Serial += [char]$char
        }
    }

    Write-Host "$Name, $Serial"
}

Write-Host "Network Adapter Information:"
foreach ($networkAdapter in $networkInfo) {
    Write-Host "  Description: $($networkAdapter.Description)"
    Write-Host "  MAC Address: $($networkAdapter.MACAddress)"
    Write-Host "  IP Address(es): $($networkAdapter.IPAddress -join ', ')"
    Write-Host ""
}
# Remove PAUSE as it's not needed
