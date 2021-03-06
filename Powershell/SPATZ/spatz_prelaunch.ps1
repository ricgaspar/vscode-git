# ---------------------------------------------------------
# Check for existence of SPATZ application and data 
# and schedule a task for archival purposes
#
# Marcel Jussen
# 10-12-2013
# ---------------------------------------------------------

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $true

# Trailing slash must not be removed!
$Global:SPATZ_DESTINATION = '\\nedcar.nl\factory\Spatz_Archive\'

#
# Checks if the default folder for Spatz exists and inventories the folders that contain
# a predefined pathname pattern.
#
Function Check_SPATZ_Path {
	Param (
		[string]$Spatz_Path = 'D:\Matuschek',
		[string]$Pathname_to_include = 'Backup_Base'
    ) 
	if([string]::IsNullOrEmpty($Spatz_Path)) { return $null }
	if([string]::IsNullOrEmpty($Pathname_to_include)) { return $null }
	
	if([System.IO.Directory]::Exists($Spatz_Path)) {
		Echo-Log "SPATZ folder $Spatz_Path was found."
	} else {
		Echo-Log "ERROR: SPATZ folder $Spatz_Path was not found."
		return $null
	}
	
	# Look for folders that contain the name Backup_Base in its pathname		
	$Folders = Get-ChildItem -path $Spatz_Path -Include $Pathname_to_include -Recurse -Force -errorAction SilentlyContinue |
			where {$_.psIsContainer -eq $true} 
	return $Folders
}


#
# Create folders on the archive server if needed.
#
Function Create_RemoteArchive_Folders {
	$Destination = $Global:SPATZ_DESTINATION
	
	# Create a destination folder for this computer which contains the computername in the pathname
	$DestFolder = $Destination + (gc env:computername)
	if([System.IO.Directory]::Exists($DestFolder) -ne $true) {
		Echo-Log "Creating folder: $DestFolder"
		$temp = New-Item -ItemType directory -Path $DestFolder -ErrorAction SilentlyContinue
	}
	
	$ControlFolder = $DestFolder + '\log\'
	if([System.IO.Directory]::Exists($ControlFolder) -ne $true) {
		Echo-Log "Creating folder: $ControlFolder"
		$temp = New-Item -ItemType directory -Path $ControlFolder -ErrorAction SilentlyContinue
	}
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
if($Global:DEBUG) {
	$logfile = "Spatz_Prelaunch-DEBUG"
} else {
	$logfile = "Spatz_Prelaunch-$cdtime"
}

# Create logboek folder if it does not exist
if([System.IO.Directory]::Exists('C:\Logboek') -ne $true) {
	$temp = New-Item -ItemType directory -Path 'C:\Logboek' -ErrorAction SilentlyContinue
}
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"
Echo-Log ("-"*60)

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

# Trailing slash must not be removed!
$SPATZ_Folder = 'D:\Matuschek\'

# Check if configuration data folders exist
$SPATZ_Include = 'Backup_Base'
$ConfFolders = Check_SPATZ_Path $SPATZ_Folder $SPATZ_Include

# Check if statistic data folders exist
$SPATZ_Include = 'QA_Base'
$StatFolders = Check_SPATZ_Path $SPATZ_Folder $SPATZ_Include

if(($ConfFolder -ne $null) -or ($StatFolders -ne $null)) {
		
}

# We are done. Close the log.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

#Copy the current logfile to the archive share
$LogPath = "C:\Logboek\$logfile.log"
$DestFolder = $Global:SPATZ_DESTINATION + (gc env:computername) + "\log\prelaunch.log"
Copy-Item $LogPath $DestFolder -ErrorAction SilentlyContinue
