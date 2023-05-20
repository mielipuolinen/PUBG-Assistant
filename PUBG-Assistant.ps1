#Requires -RunAsAdministrator 
#Requires -Version 5.0

<#
.SYNOPSIS
This is a PowerShell script file template for future projects.
A brief description of script.
Prints two strings, by default "Hello World!"

.DESCRIPTION
A more detailed description of script.
This script combines two strings and returns it. Pipelining (input and output) and parameters are supported, see examples.
CmdletBinding() enables -Verbose and -Debug parameters.

.PARAMETER String1
First string.

.PARAMETER String2
Second string.

.EXAMPLE
PS> ScriptFileTemplate.ps1 -String1 "Hi" -String2 "GitHub!"
Hi GitHub!

.EXAMPLE
PS> "What's up" | ScriptFileTemplate.ps1
What's up World!

.EXAMPLE
PS> ScriptFileTemplate.ps1 | %{Return $PSItem}
Hello World!

.EXAMPLE
PS> ScriptFileTemplate.ps1
Hello World!

.INPUTS
A list of type of objects that can be piped into this script.
String

.OUTPUTS
A list of type of objects that this script returns and therefore can be piped forward.
String

.NOTES
Additional notes.
Author: Niko Mielikäinen
Git: https://github.com/mielipuolinen
#>

[CmdletBinding()]
Param(
    [Parameter()] [string] $TslGameEXE_Path,
    [Parameter()] [switch] $RemoveMovies,
    [Parameter()] [switch] $ClearAppData,
    [Parameter()] [switch] $ValidateGameUserSettings,
    [Parameter()] [switch] $RunGameOptimization,
    [Parameter()] [switch] $UninstallWellbia,
    [Parameter()] [switch] $LaunchPUBG,
    [Parameter()] [switch] $TerminatePUBG,
    [Parameter()] [switch] $ValidateGameFiles
)

Set-StrictMode -Version Latest

if("" -eq $TslGameEXE_Path){
    try {
        $PUBG_UninstallKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 578080"
        $TslGameEXE_Path = "$($PUBG_UninstallKey.InstallLocation)\TslGame\Binaries\Win64\TslGame.exe"
        Test-Path $TslGameEXE_Path | Out-Null
    } catch {
        Write-Error "Unable to locate the PUBG installation folder, please provide a full path to TslGame.exe by using -TslGameEXE_Path parameter. Error: ${error[0]}"
    }
}

try {
    $TslGameEXE = Get-Item -LiteralPath $TslGameEXE_Path
    $PUBG_RootDir = (Get-Item -LiteralPath $TslGameEXE.PSParentPath).Parent.Parent.Parent
} catch {
    Write-Error "Unable to determine the PUBG installation folder. Error: ${error[0]}"
}


if($RemoveMovies){
    # Delete LicenseScreen.mp4 & LoadingScreen.mp4
    
    $MovieFiles = @{
        "LicenseScreen.mp4" = "$($PUBG_RootDir.FullName)\TslGame\Content\Movies\LicenseScreen.mp4";
        "LoadingScreen.mp4" = "$($PUBG_RootDir.FullName)\TslGame\Content\Movies\LoadingScreen.mp4"
    }

    foreach ($Movie in $MovieFiles.GetEnumerator()) {
        Write-Verbose "Deleting: $($Movie.Key)"
        try {
            Test-Path -LiteralPath $Movie
            Remove-Item -LiteralPath $Movie
        } catch {
            Write-Warning "Unable to delete. Error: ${error[0]}"
        }
    }
}
if ($ClearAppData) {
    # 1. Backup GameUserSettings.ini
    # 2. Remove PUBG AppData folder & Launch PUBG (Windowed)
    # 4. Poll for new GameUserSettings.ini & Kill PUBG
    # 5. Restore GameUserSettings.ini & Launch PUBG
}

if ($ValidateGameUserSettings) {
    # Open GameUserSettings.ini
    # Check for uneven float values
    # If found, prompt user and fix
}

if ($RunGameOptimization) {

    ###
    # Check Windows Game Mode (Set ON)

    [boolean] $CurrentValue = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' | Select-Object -ExpandProperty AutoGameModeEnabled
    Write-Verbose "Windows Game Mode: ${CurrentValue}"

    if ($CurrentValue -eq $false) {
        Write-Warning "Enable Windows Game Mode"
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Value 1 -WhatIf
    }


    ###
    # Check Xbox Game Bar (Set OFF)

    [boolean] $CurrentValue = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' | Select-Object -ExpandProperty AppCaptureEnabled
    Write-Verbose "Windows Xbox Game Bar (AppCapture): ${CurrentValue}"

    if ($CurrentValue -eq $false) {
        Write-Warning "Disable Windows Xbox Game Bar (AppCaptureEnabled)"
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -WhatIf
    }

    [boolean] $CurrentValue = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'HistoricalCaptureEnabled' | Select-Object -ExpandProperty HistoricalCaptureEnabled
    Write-Verbose "Windows Xbox Game Bar (HistoricalCapture): ${CurrentValue}"

    if ($CurrentValue -eq $false) {
        Write-Warning "Disable Windows Xbox Game Bar (HistoricalCapture)"
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'HistoricalCaptureEnabled' -Value 0 -WhatIf
    }


    ###
    # Check Hardware-Accelerated GPU Scheduling (HAGS) (Off/On?)


    [int] $CurrentValue = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' | Select-Object -ExpandProperty HwSchMode

    if ($CurrentValue -le 2) {
        [boolean] $CurrentValue = $false
    } else {
        [boolean] $CurrentValue = $true
    }

    Write-Verbose "Windows Hardware-Accelerated GPU Scheduling (HAGS): ${CurrentValue}"
    Write-Verbose "- HAGS allows the GPU to manage its own vRAM, eliminating the overhead time of communication with the OS, resulting in faster response rates from the GPU."

    if ($CurrentValue -eq $false) {
        Write-Warning "Enable Windows Hardware-Accelerated GPU Scheduling (HAGS)"
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Value 2 -WhatIf
    }


    ###
    # Check Variable Refresh Rate (VRR) (Off/On?)

    # Enables VRR support for DX11 full-screen games that did not support VRR natively
    # Doesn't override G-SYNC or Adaptive-Sync settings
    # Essentially an override for Windows Store games that lack adaptive sync support
    # May help with some overlays performance (e.g. Windows volume)
    # Requirements: Win 10 v1903+, G-Sync/FreeSync/Adaptive-Sync capable GPU & monitor
    # Default: off
    # Settings > System > Display > Graphics Settings > Variable refresh rate

    [string] $CurrentValue = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name 'DirectXUserGlobalSettings' | Select-Object -ExpandProperty DirectXUserGlobalSettings

    [boolean] $VRR_Enabled_Match = $CurrentValue -contains "VRROptimizeEnable=1;"
    [boolean] $VRR_Disabled_Match = $CurrentValue -contains "VRROptimizeEnable=0;"

    if ( !$VRR_Enabled_Match -and $VRR_Disabled_Match ) {
        [boolean] $VRR_Enabled = $false
    } elseif ( !$VRR_Enabled_Match -and $VRR_Disabled_Match ) {
        [boolean] $VRR_Enabled = $true
    } else {
        Write-Warning "Unable to determine VRR."
    }

    Write-Verbose "Windows Variable Refresh Rate (VRR): ${VRR_Enabled}"

    if ( $VRR_Enabled -eq $false ) {
        Write-Verbose "Enable Windows Variable Refresh Rate (VRR)"
        $NewValue = $CurrentValue -replace "VRROptimizeEnable=0;","VRROptimizeEnable=1;"
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -Name 'DirectXUserGlobalSettings' -Value $NewValue -WhatIf
    }


    ###
    # Configure TslGame.exe compatibility properties

    Write-Verbose "Checking TslGame.exe compatibility properties"

    [string] $CurrentValue_HKCU = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name $TslGameEXE_Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $TslGameEXE_Path
    [string] $CurrentValue_HKLM = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name $TslGameEXE_Path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $TslGameEXE_Path

    [boolean] $TslGameEXE_HKCU_CompatibilityProperties = $false
    [boolean] $TslGameEXE_HKLM_CompatibilityProperties = $false
    $TslGameEXE_CompatibilityProperties = New-Object System.Collections.ArrayList

    if ("" -ne $CurrentValue_HKCU) {
        $TslGameEXE_HKCU_CompatibilityProperties = $true
        [string[]] $TslGameEXE_HKCU = $CurrentValue_HKCU.Split(" ")
        $TslGameEXE_CompatibilityProperties.AddRange($TslGameEXE_HKCU)
    }

    if ("" -ne $CurrentValue_HKLM) {
        $TslGameEXE_HKLM_CompatibilityProperties = $true
        [string[]] $TslGameEXE_HKLM = $CurrentValue_HKLM -split " "
        $TslGameEXE_CompatibilityProperties.AddRange($TslGameEXE_HKLM)
    }

    $TslGameEXE_CompatibilityProperties.Add("~")

    $TslGameEXE_CompatibilityProperties.Add("~")

    $TslGameEXE_CompatibilityProperties.Add("~")


    $TslGameEXE_CompatibilityProperties.Remove( ($TslGameEXE_CompatibilityProperties | Where-Object { !($_ -match "~") }) )
    $TslGameEXE_CompatibilityProperties.Add("~")

    # Configure DPI
    $TslGameEXE_CompatibilityProperties.Remove( ($TslGameEXE_CompatibilityProperties | Where-Object { !($_ -match "PERPROCESSSYSTEMDPIFORCEOFF|PERPROCESSSYSTEMDPIFORCEON|DPIUNAWARE|GDIDPISCALING|HIGHDPIAWARE") }) )
    $TslGameEXE_CompatibilityProperties.Add("HIGHDPIAWARE") | Out-Null

    # HIGHDPIAWARE = High DPI scaling override: Application
    # DPIUNAWARE = High DPI scaling override: System
    # GDIDPISCALING DPIUNAWARE = High DPI scaling override: System (Enhanced)
    # PERPROCESSSYSTEMDPIFORCEOFF = Program DPI: I signed in to Windows
    # PERPROCESSSYSTEMDPIFORCEON = Program DPI: I open this program


    # Configure Compatibility mode
    $TslGameEXE_CompatibilityProperties.Remove("WIN8RTM")
    $TslGameEXE_CompatibilityProperties.Remove("WIN7RTM")
    $TslGameEXE_CompatibilityProperties.Remove("VISTASP2")
    $TslGameEXE_CompatibilityProperties.Remove("VISTASP1")
    $TslGameEXE_CompatibilityProperties.Remove("VISTARTM")

    # WIN8RTM = Compatibility mode for Windows 8
    # WIN7RTM = Compatibility mode for Windows 7
    # VISTASP2 = Compatibility mode for Vista SP2
    # VISTASP1 = Compatibility mode for Vista SP1
    # VISTARTM = Compatibility mode for Vista

    # Disable automatic restart
    $TslGameEXE_CompatibilityProperties.Remove("REGISTERAPPRESTART")
    # REGISTERAPPRESTART = Register this program for restart


    # Configure Full-Screen Optimisation (FSO)
    # TODO: LET USER DECIDE
    $TslGameEXE_CompatibilityProperties.Remove("DISABLEDXMAXIMIZEDWINDOWEDMODE")
    # DISABLEDXMAXIMIZEDWINDOWEDMODE = Disable Full-screen Optimisations (FSO)


    # Configure Run as Admin
    # TODO: WHICH IS BETTER?
    $TslGameEXE_CompatibilityProperties.Remove("RUNASADMIN")
    # RUNASADMIN = Run this program as an administrator

    $TslGameEXE_CompatibilityProperties_String = $TslGameEXE_CompatibilityProperties -join " "
    $TslGameEXE_CompatibilityProperties_String

    ###
    # Check GSYNC (?)


    ###
    # Check DirectX version in PUBG (?)




}

if ($UninstallWellbia) {
    # Check & Delete C:\Windows\xhunter1.sys
    # Check & Delete C:\Program Files\Common Files\Uncheater
    # Check & Delete "xhunter" & "ucldr" registry entries
    # Block %LocalAppData%\WELLBIA\*.exe & TslGame_UC.exe via Local GPO

    if (Test-Path -LiteralPath "C:\Windows\xhunter1.sys") {
        Write-Verbose "Found C:\Windows\xhunter1.sys"
    }

    if (Test-Path -LiteralPath "C:\Program Files\Common Files\Uncheater") {
        Write-Verbose "Found C:\Program Files\Common Files\Uncheater"
    }

}

if ($LaunchPUBG) {
    # steam://launch/578080
    # https://developer.valvesoftware.com/wiki/Steam_browser_protocol
    Write-Verbose "Launching PUBG"
    Start-Process -FilePath "steam://run/578080"
}

if ($TerminatePUBG) {
    # Terminate ExecPubg.exe, TslGame.exe (2x), TslGame_BE.exe, TslGame_UC.exe, zksvc.exe, BEService.exe
    $ProcessList = @("ExecPubg", "TslGame", "TslGame_BE", "TslGame_UC", "zksvc", "BEService")

    foreach ($Process in $ProcessList) {
        try {
            Write-Verbose "Stopping processes with name: ${Process}"
            Stop-Process -Name $Process -Force -ErrorAction SilentlyContinue
        } catch {}
    }
}

if ($ValidateGameFiles) {
    # steam://validate/578080
    # https://developer.valvesoftware.com/wiki/Steam_browser_protocol
    Start-Process -FilePath "steam://validate/578080"
    # Wait until steam.exe stops reading PUBG folder?
}