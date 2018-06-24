$Global:SCRIPTLOG = "$ENV:ProgramData\VDL Nedcar\Logboek\DCM-Bitlocker.log"
Function Append-Log {
    param (
        [string]$Message
    )
    $logTime = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

Remove-Item -Path $Global:SCRIPTLOG -Force -ErrorAction SilentlyContinue
$Computername = $ENV:Computername
Append-Log "Start DCM check on computer $Computername"

$OSVer = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Version,Caption
$OSOk = $False
Append-Log "OS Caption: $($OSVer.Caption)"
Append-Log "OS Version: $($OSVer.Version)"
# Windows 7
if ($OSVer.Version -match '6.1') {
    if ($OSVer.Caption -match 'Enterprise') { $OSOk = $True }
}
# Windows 8
if ($OSVer.Version -match '6.2') { $OSOk = $True }
# Windows 8.1
if ($OSVer.Version -match '6.3') { $OSOk = $True }
# Windows 10
if ($OSVer.Version -match '10.0') { $OSOk = $True }

# Create list of driveletters with removable media (a.k.a. USB drives)
$USBDrives = Get-WmiObject -Query "Select * From Win32_LogicalDisk" | Where-Object { $_.DriveType -eq 2 } | Select-Object DeviceID

# Check BDE status on valid OS versions
if ($OSOk) {
    $BitLockerOk = 999
    $Drives = 0
    $DCMDrives = 0

    $Tpm = Get-wmiobject -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm
    $TPMEnabled = $Tpm.IsEnabled().isenabled
    $TPMActivated = $Tpm.IsActivated().isactivated
    $TPMOwned = $Tpm.IsOwned().isOwned

    $TPMOk = $False
    if ($TPMEnabled -and $TPMActivated -and $TPMOwned) {
        $TPMOk = $True
        $BDEVols = Get-CimInstance -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" -ClassName "Win32_Encryptablevolume" | Where-Object { $_.Driveletter -match ':' }
        ForEach ($Vol in $BDEVols) {
            $USBSkip = $False
            $DriveLetter = $Vol.Driveletter
            Append-Log "Device: $Driveletter"
            ForEach ($USB in $USBDrives) {
                if ($DriveLetter -eq $USB.DeviceID) { $USBSkip = $True }
            }
            if (!$USBSkip) {
                $Drives++
                $CS = $Vol.ConversionStatus
                $PS = $Vol.ProtectionStatus
                if ($CS -eq '0') {
                    # Bitlocker conversion has not taken place.
                    $BitLockerOk = 0
                    Append-Log "  Conversion status: [$CS] No conversion has taken place."
                }
                if ($CS -eq '1') {
                    # Bitlocker conversion is completed.
                    Append-Log "  Conversion status: [$CS] Conversion is complete."
                    if ($PS -eq '1') {
                        Append-Log "  Protection status: [$PS] Proctection is active."
                        # Bitlocker conversion active.
                        $DCMDrives++
                    }
                    else {
                        Append-Log "  Protection status: [$PS] Procection is suspended."
                        # Bitlocker is suspended.
                    }
                }
                if ($CS -eq '2') {
                    # Bitlocker conversion is in progress
                    Append-Log "  Conversion status: [$CS] Conversion is in progress."
                    $DCMDrives++
                }
                if ($CS -eq '3') {
                    # Bitlocker conversion is in progress
                    Append-Log "  Conversion status: [$CS] Conversion is in progress."
                    $DCMDrives++
                }
                if ($CS -eq '4') {
                    # Bitlocker conversion is paused
                    Append-Log "  Conversion status: [$CS] Conversion is paused."
                }
                if ($CS -eq '5') {
                    # Bitlocker conversion is paused
                    Append-Log "  Conversion status: [$CS] Conversion is paused."
                }
            }
            else {
                Append-Log "* Skipped removable device '$Driveletter'"
            }
        }

        if ($Drives -ne 0) {
            if ($Drives -eq $DCMDrives) {
                $DCMStatus = "Compliant - Bitlocker enabled on all drives."
            }
            else {
                $DCMStatus = "ERROR - Bitlocker is not enabled on all drives."
            }
        }
    }
    else {
        $DCMStatus = "ERROR - TPM status is not correct."
    }
}
else {
    $DCMStatus = 'ERROR - Operating system does not support Bitlocker.'
}
Append-Log "COMPLIANCY CHECK RESULT: $DCMStatus"
Write-Host $DCMStatus

Append-Log "Ended DCM script on computer $Computername"