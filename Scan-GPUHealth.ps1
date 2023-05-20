[CmdletBinding()]
Param(
    [Parameter()] [Boolean] $CheckGPUDrivers = $true,
    [Parameter()] [int] $MaxGPUDriverAgeInDays = 30
)

if ($CheckGPUDrivers) {
    try {
        Write-Verbose "Checking GPU drivers"
        $GPUs = Get-CimInstance -ClassName "win32_VideoController"

        # TODO: Get latest driver versions from Nvidia & AMD
    
        foreach ($GPU in $GPUs) {

            # $GPU.DriverDate
            # $GPU.DriverVersion

            Write-Verbose "GPU: $($GPU.Name)"
            [datetime] $DriverDate = $GPU | Select-Object -ExpandProperty DriverDate
            $DriverAgeInDays = ( (Get-Date) - $DriverDate ).TotalDays
    
            if($DriverAgeInDays -gt $MaxGPUDriverAgeInDays) {
                Write-Warning "Update GPU driver. The current driver is ${DriverAgeInDays} days old."
            } else {
                Write-Verbose "GPU driver OK"
            }
    
        }
    }
    catch {
        Write-Error "Failed to check GPU drivers"
    }
}