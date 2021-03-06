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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-Volnames-$NCSTD_VERSION.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

Function Detect-Cluster {
	$result = $false	
	if(Get-WmiObject -Class Win32_Service -Filter "Name='ClusSvc'") { $result = $true }
	return $result	
}

if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {
	if(Detect-Cluster) {
		Write-Host "Cluster detected. No changes applied to volume names."
	} else {
		$msg = "Configuring volume names."
		Append-Log $msg	
	
		$computername = $env:COMPUTERNAME		
		$wmi = gwmi Win32_LogicalDisk -Filter "DriveType=3" 
		foreach($drive in $wmi) {
			$drivename = $drive.name
			$driveletter = $drivename.substring(0,1)
			$volname = $computername + "-" + $driveletter
			$volname = $volname.ToUpper()
			$curvolname = $drive.VolumeName
			if($curvolname -ne $volname) {
				Append-Log "Changing volume name $curvolname to $volname"
				$drive.VolumeName = $volname
				$drive.Put()
			} else {
				Append-Log "No need to change volume name $curvolname"
			}
		}		
	}	
}