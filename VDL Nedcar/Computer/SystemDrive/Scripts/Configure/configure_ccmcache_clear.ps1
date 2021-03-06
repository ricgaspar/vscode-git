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

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-SccmCache-$NCSTD_VERSION.log"

#-----------------------------------------------------------------------
# This script is executed on a monthly basis (every 1st sunday at 23:45)
# This script is not started from the main script but directly from 
# a scheduled task
#-----------------------------------------------------------------------

Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

$LogStr = "Clearing SCCM cache started."	
Append-Log $LogStr	
 
#
# Clear SCCM client cache folder
#
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheElements = $Cache.GetCacheElements()
foreach ($Element in $CacheElements) {
	$LogStr = "Deleting CacheElement with PackageID $($Element.ContentID) in folder location $($Element.Location)"	
	Append-Log $LogStr	
    $Cache.DeleteCacheElement($Element.CacheElementID)
}

$LogStr = "Clearing SCCM cache has ended."	
Append-Log $LogStr	
