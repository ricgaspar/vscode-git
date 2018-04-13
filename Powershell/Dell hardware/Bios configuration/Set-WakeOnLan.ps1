# =========================================================
# VDL Nedcar - Information Systems
#
# .SYNOPSIS
# 	Update Dell BIOS parameters for Wake On LAN feature
#
# .CREATED_BY
# 	Marcel Jussen
#
# .CHANGE_DATE
# 	13-04-2018
#
# .DESCRIPTION
#	Updates the WakeOnLAN and DeepSleepCtrl parameters to enable Wake On LAN
#
# =========================================================
#Requires -version 5.0

Set-StrictMode -Version Latest

# Update Dell BIOS to accept Wake-On-LAN
Write-Output ("-" * 80)
Write-Output "[$env:COMPUTERNAME] Start of script."

# New-Item -Path "$Env:ProgramData\VDL Nedcar\Logboek\BIOS" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
# Start-Transcript -Path "$Env:ProgramData\VDL Nedcar\Logboek\BIOS\VNB-BIOS-Update-WakeOnLan.log" -Force
# Write-Output "[$env:COMPUTERNAME] Start of transscript logging."

#
# WARNING
# Dell Optiplex 7040 and Latitude E5570 share a common BIOS model which has a critical bug when version < 1.5.0
#
$BIOSver = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop | Select-Object SMBIOSBIOSVersion
$Make = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object Manufacturer, Model
$AcceptedBIOSMajor = '1'
$AcceptedBIOSMinor = '5'
$AcceptedBIOS = $AcceptedBIOSMajor + '.' + $AcceptedBIOSMinor
if ($Make.Manufacturer -eq 'Dell Inc.') {
    Write-Output "[$env:COMPUTERNAME] Computername: $env:COMPUTERNAME"
    Write-Output "[$env:COMPUTERNAME] Make: $($Make.Manufacturer)"
    if (($Make.Model -eq 'Optiplex 7040') -or ($Make.Model -eq 'Latitude E5570')) {
        Write-Output "[$env:COMPUTERNAME] Model (*): $($Make.Model)"
        $VerArray = $($Biosver.SMBIOSBIOSVersion).split('.')
        Write-Output "[$env:COMPUTERNAME] Major: $($VerArray[0])"
        Write-Output "[$env:COMPUTERNAME] Minor: $($VerArray[1])"

        if ( ($($VerArray[0]) -ge $AcceptedBIOSMajor ) -and ( $($VerArray[1]) -ge $AcceptedBIOSMinor) ) {
            Write-Output "[$env:COMPUTERNAME] BIOS: $($BIOSver.SMBIOSBIOSVersion)"
            Write-Output "[$env:COMPUTERNAME] A valid BIOS version was found."
        }
        else {
            Write-Output "[$env:COMPUTERNAME] BIOS (*): $($BIOSver.SMBIOSBIOSVersion)"
            Write-Output "[$env:COMPUTERNAME] ERROR: BIOS version is not valid. Cannot update this BIOS."
            Write-Output "[$env:COMPUTERNAME] Acceptable BIOS version should at least be $($AcceptedBIOS)"
            Exit
        }
    }
    else {
        Write-Output "[$env:COMPUTERNAME] Model: $($Make.Model)"
        Write-Output "[$env:COMPUTERNAME] BIOS: $($BIOSver.SMBIOSBIOSVersion)"
        Write-Output "[$env:COMPUTERNAME] A valid BIOS version was found."
    }
}

#
# If BIOS version is OK, check for required parameter values and update if needed.
#
Write-Output ("-" * 80)
Write-Output "[$env:COMPUTERNAME] Importing DellBIOSProvider module."

# Set-Location "C:\Program Files\WindowsPowerShell\Modules\DellBIOSProvider\2.0.0\"
# Import-Module '.\DellBIOSProvider.psd1' -Verbose
# Import-Module '.\DellBIOSProvider.psm1' -Verbose
Import-Module DellBIOSProvider -Verbose -ErrorAction Stop

Write-Output ("-" * 80)
Write-Output "[$env:COMPUTERNAME] Dell BIOS System information."
$Info = Get-ChildItem -Path DellSmbios:\SystemInformation -ErrorAction Stop
ForEach ($Attrib in $Info) {
    Write-Output "[$env:COMPUTERNAME] $($Attrib.Attribute): $($Attrib.CurrentValue)"
}

Write-Output ("-" * 80)
Write-Output "[$env:COMPUTERNAME] Dell BIOS Powermanagement information."
$Info = Get-ChildItem -Path DellSmbios:\PowerManagement -ErrorAction Stop
ForEach ($Attrib in $Info) {
    Write-Output "[$env:COMPUTERNAME] $($Attrib.Attribute): $($Attrib.CurrentValue)"
}

Write-Output ("-" * 80)
$changed = $false
$password = 'kleinevogel'
$DeepSleepCtrl = Get-ChildItem -Path DellSmbios:\PowerManagement\DeepSleepCtrl -ErrorAction SilentlyContinue
$reqval = 'Disabled'
if ($DeepSleepCtrl) {
    $val = $DeepSleepCtrl.CurrentValue
    if ($val -ne $reqval) {
        Set-Item -path DellSmbios:\PowerManagement\DeepSleepCtrl -value $reqval -Password $password
        Write-Output "[$env:COMPUTERNAME] The DeepSleepCtrl parameter was changed to '$reqval'."
        $changed = $true
    }
    if ($changed) {
        $WakeOnLan = Get-ChildItem -Path DellSmbios:\PowerManagement\DeepSleepCtrl  -ErrorAction SilentlyContinue
        $val = $WakeOnLan.CurrentValue
        if ($val -eq $reqval) {
            Write-Output "[$env:COMPUTERNAME] SUCCESS: The DeepSleepCtrl parameter was updated successfully."
        }
        else {
            Write-Output "[$env:COMPUTERNAME] ERROR: The DeepSleepCtrl parameter failed to be updated to '$reqval'."
        }
    }
    else {
        Write-Output "[$env:COMPUTERNAME] SUCCESS: No update needed to the DeepSleepCtrl parameter."
    }
}
else {
    Write-Output "[$env:COMPUTERNAME] WARNING: The DeepSleepCtrl parameter is not supported."
}

$changed = $false
$WakeOnLan = Get-ChildItem -Path DellSmbios:\PowerManagement\WakeOnLan -ErrorAction SilentlyContinue
$reqval = 'LanOnly'
if ($WakeOnLan) {
    $val = $WakeOnLan.CurrentValue
    if ($val -ne $reqval) {
        Set-Item -path DellSmbios:\PowerManagement\WakeOnLan -value $reqval -Password $password
        Write-Output "[$env:COMPUTERNAME] The WakeOnLan parameter was changed to '$reqval'."
        $changed = $true
    }
    if ($changed) {
        $WakeOnLan = Get-ChildItem -Path DellSmbios:\PowerManagement\WakeOnLan  -ErrorAction SilentlyContinue
        $val = $WakeOnLan.CurrentValue
        if ($val -eq $reqval) {
            Write-Output "[$env:COMPUTERNAME] SUCCESS: The WakeOnLan parameter was updated successfully."
        }
        else {
            Write-Output "[$env:COMPUTERNAME] ERROR: The WakeOnLan parameter failed to be updated to '$reqval'."
        }
    }
    else {
        Write-Output "[$env:COMPUTERNAME] SUCCESS: No update needed to the WakeOnLan parameter."
    }
}
else {
    Write-Output "[$env:COMPUTERNAME] WARNING: The WakeOnLan parameter is not supported."
}

Write-Output "[$env:COMPUTERNAME] End of script. Bye bye."
Write-Output ("-" * 80)

# Stop-Transcript
