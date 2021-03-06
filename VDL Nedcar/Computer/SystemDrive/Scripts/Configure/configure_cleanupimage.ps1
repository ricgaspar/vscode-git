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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-CleanupImage-$NCSTD_VERSION.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {
	$msg = "Cleanup Windows WinSxS folder."
	Append-Log $msg
	
	# Cleanup superseded service pack information
	$command = "dism.exe /online /Cleanup-Image /spsuperseded"
	Write-Host $command
	
	# Execute command
	$result = invoke-expression $command 
	Append-Log $result
}