# ------------------------------------------------------------------------------
<#
.SYNOPSIS
    Sets Wifi driver settings in the registry

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	13-07-2015

.CHANGE_DATE
	13-07-2015
 
.DESCRIPTION
    Sets Wifi driver settings in the registry
#>
# ------------------------------------------------------------------------------
#-requires 3.0

#-----------------------------------------------------------------------
#
# Write text to screen and log file at the same time
#
Function Append-Log {
	param (
		[string] $Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

#
# Check if we are running during a SCCM Task Sequence
#
Function SCCM_TaskSeq_Active {
	$tsenv = $null	
	try { $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue }
	catch { }
	$result = [Boolean](($tsenv -ne $null))
	return $result	
}

#-----------------------------------------------------------------------
$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ComputerName = $Env:COMPUTERNAME
$version = '0.0.0'
$TS = SCCM_TaskSeq_Active

$bl_ScheduledTaskCreated = $False
$TasksSourcePath = $PSScriptRoot 

#
# Create new log file
#
$SCRIPTLOG = 'C:\Windows\Patchlog\Wifi_Driver_settings.log'
if(Test-Path($SCRIPTLOG)) { Remove-Item $SCRIPTLOG -ErrorAction SilentlyContinue }
Append-Log ("-" * 80)
Append-Log "Version = $version"
if($TS) { Append-Log "This script is running during a SCCM Task Sequence." }
Append-Log "Source folder: $TasksSourcePath"
Append-Log ("-" * 80)

$RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class'
$RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\0002'
$CurrentKey = Get-ChildItem -Path $RegPath -ErrorAction SilentlyContinue 

$CurrentKey


#
# Done!
#
Append-Log ("-" * 80)
Append-Log "Ended script $PSScriptName from $PSScriptRoot"
Append-Log ("-" * 80)