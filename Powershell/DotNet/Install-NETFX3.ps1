#-----------------------------------------------------------------------
#
# Install NETFX3 on Windows 10
# Marcel Jussen
# 02-11-2017
#
#-----------------------------------------------------------------------
# Write text to screen and log file at the same time
#
Import-Module PSClientManager -Force -ErrorAction Stop

Function Append-Log {
    param (
        [string]
        $Message
    )
    $logTime = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    Write-host "-> $message"
    Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

#
# Check if we are running during a SCCM Task Sequence
#
Function SCCM_TaskSeq_Active {
    $tsenv = $null
    try { $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue }
    catch { 	}
    $result = [Boolean](($tsenv -ne $null))
    return $result
}

#-----------------------------------------------------------------------
$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ComputerName = $Env:COMPUTERNAME
Write-host "Started script $PSScriptName from $PSScriptRoot"

$SCRIPTLOG = $env:PROGRAMDATA + "VDL Nedcar\Logboek\OSD\OSD_Configure_NETFX3.log"
New-Item -Path ($env:PROGRAMDATA + 'VDL Nedcar\Logboek\OSD\') -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

#
# Check if a task sequence is active.
#
$TS = SCCM_TaskSeq_Active
if ($TS) { Append-Log "This script is running during a SCCM Task Sequence." }
$OS = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object BuildNumber, Version
if ($OS.Version -match '10.0') {
    Append-Log "Windows 10 detected."
    Append-Log "Build number: $($OS.BuildNumber)"
    $Payload = $PSScriptRoot + '\' + $($OS.BuildNumber) + '\sxs\Microsoft-Windows-NetFx3-OnDemand-Package.cab'
    $ValidPayload = Test-Path $Payload
    if ($ValidPayload) {
        Append-Log "The payload '$($Payload)' was found."
    }
    else {
        Append-Log "ERROR: The payload '$($Payload)' could not be found."
    }

    $NETFX3 = $null
    Append-Log "Checking if NETFX3 is already enabled"
    try {
        $NETFX3 = Get-ClientFeature | Where-Object { $_.Name -eq 'NetFX3' } | Select-object State
    }
    catch {
        Append-Log "ERROR: Could not determine the install state of NETFX3."
    }
    if ($NETFX3) {
        if ($NETFX3.State -ne 'Enabled') {
            Append-Log "Enabling NETFX3 using payload."
            Dism /online /enable-feature /featurename:NetFX3 /Source:"$($Payload)"
        }
    }
    else {
        Append-Log "Error: Feature state detection failed."
    }

    Append-Log "Consolidate NETFX3."
    try {
        $NETFX3 = Get-ClientFeature | Where-Object { $_.Name -eq 'NetFX3' } | Select-object State
    }
    catch {
        Append-Log "ERROR: Could not determine the install state of NETFX3."
    }
    if ($NETFX3) {
        if ($NETFX3.State -eq 'Enabled') {
            Append-Log "NETFX3 is enabled."
        }
        else {
            Append-Log "ERROR: NETFX3 is not enabled."
        }
    }
    else {
        Append-Log "Error: Feature state detection failed."
    }
}

Append-Log "Ended script $PSScriptName from $PSScriptRoot"
