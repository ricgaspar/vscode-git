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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Once\configure-Features61.01.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

Write-Host "Started NCSTD Configure $NCSTD_VERSION"
if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {
	$msg = "Installing Windows 2008 R2 features."
	Append-Log $msg

	Import-Module Servermanager
	Add-WindowsFeature FS-FileServer
	Add-WindowsFeature FS-Resource-Manager
	Add-WindowsFeature RSAT-FSRM-Mgmt
	Add-WindowsFeature Desktop-Experience
	Remove-WindowsFeature ADDS-Identity-Mgmt
}