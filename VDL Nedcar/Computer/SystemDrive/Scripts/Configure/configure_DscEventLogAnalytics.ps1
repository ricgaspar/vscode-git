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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-DscEventLogAnalytics-$NCSTD_VERSION.log"

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
	Append-Log "Configuring Windows Event log for DSC Analytics."

	# Disable the Analytic log first, then re-enable
	wevtutil.exe set-log "Microsoft-Windows-Dsc/Analytic" /q:true /e:false
	wevtutil.exe set-log "Microsoft-Windows-Dsc/Analytic" /q:true /e:true
	wevtutil.exe set-log "Microsoft-Windows-Dsc/Debug" /q:true /e:false
	wevtutil.exe set-log "Microsoft-Windows-Dsc/Debug" /q:true /e:true
}