$computername = Read-Host -Prompt 'Enter Hostname'
$MonitorsCMD = ""

if (!$computername) {
    $MonitorsCMD = Get-CimInstance -ClassName WmiMonitorID -Namespace root\wmi
}
else {
    $MonitorsCMD = Get-CimInstance -ClassName WmiMonitorID -Namespace root\wmi -ComputerName $computername
}

$Monitors = $MonitorsCMD
$LogFile = "C:\monitors.txt"

# Ensure the directory exists
$LogDir = Split-Path $LogFile
if (!(Test-Path -Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
}

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

# Remove PAUSE as it's not needed
