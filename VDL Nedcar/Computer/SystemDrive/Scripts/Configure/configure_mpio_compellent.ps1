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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-MPIO-Compellent-$NCSTD_VERSION.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

if(Test-Path($SCRIPTLOG)) {
	Remove-Item $SCRIPTLOG -Force -ErrorAction SilentlyContinue
}

	$msg = "Configuring MPIO settings for Compellent SAN. This script is intentionally repeated every day!"
	Append-Log $msg	
	
	#
	# Collect disk information from WMI
	#
	$blFound = $false
	$disks = gwmi Win32_DiskDrive | Select -ExpandProperty Model
	foreach($disk in $disks) { 
		$msg = "Disk model: $disk"
		Append-Log $msg	
		
		#
		# Must be a Multi-Path device. 
		# SCSI device is a virtual machine, Multi-Path device is a physical machine.
		#
		if($disk -like '*Compellent*Multi-Path*') { $blFound = $true }
	}

	# If a Compellent disk was found, set MPIO registry values
	if($blFound) {
		$msg = "Compellent disk was found. Registry settings for MPIO are applied."
		Append-Log $msg	
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v PDORemovePeriod /t REG_DWORD /d 120 /f
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v PathRecoveryInterval /t REG_DWORD /d 25 /f
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v UseCustomPathRecoveryInterval /t REG_DWORD /d 1 /f
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v PathVerifyEnabled /t REG_DWORD /d 1 /f
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v RetryCount /t REG_DWORD /d 3 /f
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v RetryInterval /t REG_DWORD /d 1 /f
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v DiskPathCheckDisabled /t REG_DWORD /d 1 /f
		reg add HKLM\SYSTEM\CurrentControlSet\Services\mpio\Parameters /v DiskPathCheckInterval /t REG_DWORD /d 25 /f
		$msg = "Registry settings are active after next reboot."
		Append-Log $msg	
	} else {
		$msg = "A Compellent disk was not found. Registry settings are not applied."
		Append-Log $msg	
	}
