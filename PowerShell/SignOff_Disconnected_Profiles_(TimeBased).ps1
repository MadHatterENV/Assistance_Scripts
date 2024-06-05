
## % Written by : Tom Royeaerd ##
## % Scripted : 05/06/2024 ##

# USAGE : $> backup.sh /path/to/folder [BackupName]
# Check First : README.MD for details.
## ----------------------------------------------------------------------------
# The script will check the DA_Servers.txt file and will list-up all the current
# disconnected user sessions on the servers.
# If the session has been idle for more than 1 day, the session will be logged off.
## ----------------------------------------------------------------------------

## Clear Host Console
Clear-Host

## Define Variable for Server Count
$z = 0

##Set Default Script Location
Set-Location $PSScriptRoot

## Provide List of Servers to Check for the Disconnected user session
$Servers = Get-Content ".\Servers\DA_Servers.txt"

## Get Servers Count
$count = $Servers.count 

## Define Date for the Out file
# $dt = Get-Date -Format yyyyMMdd
# $Date = Get-Date

## Define Path for the Out File
$exportFile = ".\Out\RDP_DisConnected_Users.csv"

## Create a Function to list all user sessions from Remote Servers
function Get-RemoteUsers {

    ## Loop through each server to find the User session    
    foreach ($Computer in $Servers) {

        #initiate counter for showing progress
        $z = $z + 1

        # Start writing progress 
        Write-Progress -Activity "Processing Server: $z out of $count servers." -Status " Progress" -PercentComplete ($z / $Servers.count * 100)

        $obj = "" | Select-Object @{Name = 'ServerName'; Expression = { $Computer } }, UserName, ID, State, IdleTime, LogonTime
    
        try {
            quser /server:$Computer 2>&1 | Select-Object -Skip 1 | ForEach-Object {
                $items = $_.Trim() -split '\s{2,}'
                $obj.UserName = $items[0]
                 
                # If session is disconnected different fields will be selected
                if ($items[2] -like 'Disc*') {
                    $obj.Id = $items[1]
                    $obj.State = $items[2]
                    $obj.IdleTime = $items[3]
                    $obj.LogonTime = $items[4..($items.GetUpperBound(0))] -join ' ' 
                }
                else {
                    $obj.Id = $items[1]
                    $obj.State = $items[2]
                    $obj.IdleTime = $items[3]
                    $obj.LogonTime = $items[4] 
                }

                # reformat the IdleTime property
                $obj.IdleTime = '{0} days, {1} hours, {2} minutes' -f ([int[]]([regex]'^(?:(\d+)\+)?(\d+):(\d+)').Match($obj.IdleTime).Groups[1..3].Value | ForEach-Object { $_ })
                # output the object
                $obj
            }
        } 
        catch {
            #$obj.Error = $_.Exception.Message
            #$obj
        }
    }
}

## Filter the results to find out the disconnected users
$allRemoteUsers = Get-RemoteUsers  $Servers
$disconnectedUsers = $allRemoteUsers | Where-Object { $_.State -like 'disc*' }
if (@($disconnectedUsers).Count) {
    #output on screen
    $disconnectedUsers | Format-Table -AutoSize
    # output to Csv
    $disconnectedUsers | Export-Csv "$exportFile" -NoTypeInformation
}
else {
    Write-Host "No disconnected users found" -BackgroundColor Red
}





# ----------------------------------------------------------------------------------------------------------------------------

foreach ($item in $disconnectedUsers) {
    # read back the values for Days, Hours and Minutes from the formatted string
    $d, $h, $m = [int[]]([regex]'(\d+) days, (\d+) hours, (\d+) minutes').Match($item.IdleTime).Groups[1..3].Value
    if ($d -gt 1 -or ($d -eq 1 -and ($h -gt 0 -or $m -gt 0))) {
        # been idle for more than 1 day, so logoff the user here
        Write-Host "Logging off $($item.UserName) from computer $($item.ServerName).."
        logoff $item.Id /SERVER:$($item.ServerName)
        # or use: rwinsta $item.Id /SERVER:$($item.ServerName)
    }
}


# ----------------------------------------------------------------------------------------------------------------------------



if (@($disconnectedUsers).Count) {
    #output on screen
    $disconnectedUsers | Format-Table -AutoSize
    # output to Csv
    $disconnectedUsers | Export-Csv "$exportFile" -NoTypeInformation

    # next, loop through the disconnected user connections and test if there are idle connections older than 1 day
    # if so then log them off
    foreach ($item in $disconnectedUsers) {
        # read back the values for Days, Hours and Minutes from the formatted string
        $d, $h, $m = [int[]]([regex]'(\d+) days, (\d+) hours, (\d+) minutes').Match($item.IdleTime).Groups[1..3].Value
        if ($d -gt 1 -or ($d -eq 1 -and ($h -gt 0 -or $m -gt 0))) {
            # been idle for more than 1 day, so logoff the user here
            Write-Host "Logging off $($item.UserName) from computer $($item.ServerName).."
            logoff $item.Id /SERVER:$($item.ServerName)
            # or use: rwinsta $item.Id /SERVER:$($item.ServerName)
        }
    }
}
else {
    Write-Host "No disconnected users found" -BackgroundColor Red
}


# https://tecadmin.net/windows-logoff-disconnected-sessions/
