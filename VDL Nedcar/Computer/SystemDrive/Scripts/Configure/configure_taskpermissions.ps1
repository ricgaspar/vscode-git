#-----------------------------------------------------------------------
# VDL Nedcar Windows server standaard
#
# Configure application script
#
# Author: Marcel Jussen
#-----------------------------------------------------------------------

param (
	[string]$NCSTD_VERSION = '6.0.0.0'
)

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Once\configure-TaskPermissions.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {
	$msg = "Configuring scheduled tasks permissions for Windows 2008 servers."
	Append-Log $msg	
	
	$windir = $env:windir
	$systemdrive = $env:SystemDrive
	
	$command = "cscript $systemdrive\Scripts\Utils\xcacls.vbs $windir\System32\Tasks /E /G Builtin\Administrators:F;F"
	Append-log "Executing command: $command"
	
	$result = Invoke-Expression $command -ErrorAction SilentlyContinue
	foreach($logline in $result) { append-log $logline}
}