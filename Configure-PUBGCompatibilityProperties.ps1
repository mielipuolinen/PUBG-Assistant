[CmdletBinding()]
Param(
    [Parameter()] [Boolean] $ConfigureGameMode = $true,
    [Parameter()] [Boolean] $ConfigureXboxGameBar = $true,
    [Parameter()] [Boolean] $ConfigureHAGS = $true,
    [Parameter()] [Boolean] $ConfigureVRR = $true
)


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