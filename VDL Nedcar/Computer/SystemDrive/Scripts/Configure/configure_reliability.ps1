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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Once\configure-Reliability.log"

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
	$msg = "Configuring DISKPERF performance counters."
	Append-Log $msg
	
	# Install BLAT 
	$command = "schtasks.exe /change /enable /tn \Microsoft\Windows\RAC\RacTask"	
	Write-Host $command
	
	# Execute command
	$result = invoke-expression $command 
	Append-Log $result
}