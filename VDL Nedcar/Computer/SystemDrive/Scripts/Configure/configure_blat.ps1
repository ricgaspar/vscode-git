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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-Blat-$NCSTD_VERSION.log"

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
	Append-Log "Installing BLAT commandline SMTP utility."
	
	# Install BLAT 
	$command = $env:SystemDrive + "\Scripts\Utils\blat.exe"
	$command += " -install smtp.nedcar.nl "
	$command += $env:COMPUTERNAME + "@vdlnedcar.nl"
	Write-Host $command
	
	# Execute command
	$result = invoke-expression $command 
	Append-Log $result
}