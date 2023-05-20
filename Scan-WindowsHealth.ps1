[CmdletBinding()]
Param(
    [Parameter()] [Boolean] $CheckSystemUptime = $true,
    [Parameter()] [Boolean] $CheckWindowsUpdates = $true,
    [Parameter()] [Boolean] $CheckPageFile = $true,
    [Parameter()] [Boolean] $CheckEventLogs = $true,
    [Parameter()] [Boolean] $CheckStartUpApps = $true,
    [Parameter()] [Boolean] $CheckDiskFreeSpace = $true,
    [Parameter()] [int] $MaxSystemUptimeInHours = 6,
    [Parameter()] [int] $MaxWindowsUpdateAgeInDays = 30
)


if ($CheckSystemUptime) {
    try {
        Write-Verbose "Checking system uptime"
        [datetime] $BootTimestamp = Get-CimInstance -ClassName "Win32_OperatingSystem" | Select-Object -ExpandProperty LastBootUpTime
        [datetime] $CurrentDate = Get-Date
        $UptimeInHours = [math]::Round( ( $CurrentDate - $BootTimestamp ).TotalHours )
        
        if ($UptimeInHours -gt $MaxSystemUptimeInHours) {
            Write-Warning "Reboot the computer: the system uptime is ${UptimeInHours} hours"
        } else {
            Write-Verbose "The system uptime is OK"
        }
    }
    catch {
        Write-Error "Failed to check system uptime"
    }


}


if ($CheckWindowsUpdates) {
    try {
        Write-Verbose "Checking Windows updates"
        $WindowsUpdate = New-Object -ComObject "Microsoft.Update.Session"
        $WindowsUpdateSearcher = $WindowsUpdate.CreateUpdateSearcher()
        $InstalledUpdatesCount = $WindowsUpdateSearcher.GetTotalHistoryCount()
        
        if ($InstalledUpdatesCount -gt 0) {
        
            $InstalledUpdates = $WindowsUpdateSearcher.QueryHistory(0,$InstalledUpdatesCount)
            $LatestUpdate = $InstalledUpdates | Sort-Object -Property Date | Select-Object -Last 1
            $LatestUpdateDate = $LatestUpdate.Date
            $DaysSinceLastUpdate = ( (Get-Date) - $LatestUpdateDate ).TotalDays
        
            if($DaysSinceLastUpdate -gt $MaxWindowsUpdateAgeInDays) {
                Write-Warning "Check Windows Updates. The latest update was installed on ${LatestUpdateDate}."
            } else {
                Write-Verbose "Windows Updates are relatively up-to-date"
            }
        
        } else {
            Write-Warning "Unable to read windows updates"
        }
    }
    catch {
        Write-Error "Failed to check Windows Updates"
    }
}

if ($CheckPageFile) {
    # Check page file is configured and size is relatively sized to RAM
    try {
        Write-Verbose "Checking"
    }
    catch {
        Write-Error "Failed to check"
    }
}

if ($CheckEventLogs) {
    # Check event logs for errors in last 72 hours (?)
    try {
        Write-Verbose "Checking"
    }
    catch {
        Write-Error "Failed to check"
    }
}

if ($CheckStartUpApps) {
    # Check number of startup apps (?)
    # Get-CimInstance Win32_StartupCommand
    # Warn if more than 20?
    # HKCU:\Software\Microsoft\Windows\CurrentVersion\Run
    # HKLM:\Software\Microsoft\Windows\CurrentVersion\Run
    # HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce
    # HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce
    try {
        Write-Verbose "Checking"
    }
    catch {
        Write-Error "Failed to check"
    }
}

if ($CheckDiskFreeSpace) {
    # Check disk spaces (<20% free)
    try {
        Write-Verbose "Checking"
    }
    catch {
        Write-Error "Failed to check"
    }

    Write-Verbose "Checking disk space"
    $Drives = Get-Volume | Where-Object {$_.DriveType -eq "Fixed" -and $null -ne $_.DriveLetter} | Sort-Object -Property DriveLetter

    # TODO: Check only System Drive & Game Drive

    foreach ($Drive in $Drives) {

        $DriveSize = $Drive.Size / 1GB
        $DriveFreeSpace = $Drive.SizeRemaining / 1GB
        $FreeSpacePercentage = [math]::Round( $DriveFreeSpace / $DriveSize , 2) * 100

        if ($FreeSpacePercentage -le 10){
            Write-Warning "Free up space on drive $($Drive.DriveLetter). Free space left: ${FreeSpacePercentage} %"
        }

    }
}