# ---------------------------------------------------------
# Archive SPATZ data to \\nedcar.nl\factory\Spatz_archive
#
# Marcel Jussen
# 14-10-2014
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

$Global:DEBUG = $false
$Global:PathRoot = $null

# Trailing slash must not be removed!
$Global:SPATZ_DESTINATION = '\\nedcar.nl\factory\Spatz_Archive\'

# For testing purposes only! Trailing slash must not be removed!
# $Global:SPATZ_DESTINATION = '\\vdlnc00261\d$\Spatz_Archive\'

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

	Echo-Log "Inventory subfolders $Spatz_Path with $Pathname_to_include"	
	
	#
	# Inventory folders. Skip folders with 'unused' in it.
	#
	$Folders = Get-ChildItem -path $Spatz_Path -Include $Pathname_to_include -Recurse -Force -errorAction SilentlyContinue |
			where {$_.psIsContainer -eq $true} | ?{ $_.fullname -notmatch "\\unused\\?"}
	return $Folders
}

#
# Execute Robocopy to archive Spatz data
#
Function RBCPY_SHELL {	
	Param (
		[string]$Sourcepath,
		[string]$Destinationpath,
		[boolean]$Mirror = $false,
		[Boolean]$CRWExclude = $true
    )
	if([string]::IsNullOrEmpty($Sourcepath)) { return $null }
	if([string]::IsNullOrEmpty($Destinationpath)) { return $null }
	
	$Rbcp_Arguments = "$Sourcepath $Destinationpath /NP /LOG+:C:\Logboek\robocopy.log"
	if($Mirror) { 
		Echo-Log "MIRROR active."
		$Rbcp_Arguments += " /MIR" 
	} else { 
		$Rbcp_Arguments += " /E" 
	}

	# Exclude CRW files
	if($CRWExclude -eq $true) {
		Echo-Log "CRW extension filter active."
		$Rbcp_Arguments += " /XF *.crw"
	}
	
	# Always exclude QA_Curves folders	
	$Rbcp_Arguments += " /XD *QA_Curves*"
	
	Echo-Log $Rbcp_Arguments
	if($Global:DEBUG) {	
		$ErrorCode = 99		
	} else {
		$ErrorCode = (Start-Process -FilePath "robocopy.exe" -ArgumentList $Rbcp_Arguments -Wait -Passthru).ExitCode  
	}
	
	switch ($ErrorCode) 
    { 
        0 {$Text = "No files were copied. No files were mismatched. The files already exist in the destination directory; therefore, the copy operation was skipped."} 
		1 {$Text = "All files were copied successfully."}
        2 {$Text = "There are some additional files in the destination directory that are not present in the source directory. No files were copied."} 
        3 {$Text = "Some files were copied. Additional files were present."} 
    
        5 {$Text = "Some files were copied. Some files were mismatched."} 
        6 {$Text = "Additional files and mismatched files exist. No files were copied. This means that the files already exist in the destination directory."} 
        7 {$Text = "Files were copied, a file mismatch was present, and additional files were present."}
        8 {$Text = "ERROR: Several files did not copy."}
		99 {$Text = "Debug mode: Files were not copied."}
        default {"The result code could not be determined."}
    }

	Echo-Log $Text		
 	return $ErrorCode
}

#
# Inventory Spatz data folder and parse thru them to archive data.
#
Function Backup_SPATZ_Data { 
	Param (
		[string]$Sourcepath,
		[string]$IncludeString,
		[Boolean]$Mirror = $false,
		[Boolean]$CRWExclude = $true
    )
	if([string]::IsNullOrEmpty($Sourcepath)) { return $null }
	if([string]::IsNullOrEmpty($IncludeString)) { return $null }
	
	$Folders = Check_SPATZ_Path -Spatz_Path $Sourcepath -Pathname_to_include $IncludeString
	if($Folders -ne $null) {
		$Destination = $Global:SPATZ_DESTINATION
	
		# Create a destination folder for this computer which contains the computername in the pathname
		$DestFolder = $Destination + (gc env:computername)
		if([System.IO.Directory]::Exists($DestFolder) -ne $true) {
			$temp = New-Item -ItemType directory -Path $DestFolder -ErrorAction SilentlyContinue
		}		

		# For each found folder execute a Robocopy
		ForEach($folder in $Folders) {			
			$Pathname = $folder.Fullname			
						
			$SourceFolder = """" + $Pathname + """"					
			$RBDestFolder = $DestFolder + '\' + $Pathname.Replace($SPATZ_Folder, "")
			$RBDestFolder = """" + $RBDestFolder + """"
		
			$result = RBCPY_SHELL -Sourcepath $SourceFolder -Destinationpath $RBDestFolder -Mirror $Mirror $CRWExclude			
		}
	
	} else {
		Echo-Log "ERROR: The SPATZ path does not contain any valid $IncludeString folders."
	}
}

Function Backup_Spatz_Logs {
	Param (
		[string]$Sourcepath,
		[string]$IncludeString = '*.log'
    )
	if([string]::IsNullOrEmpty($Sourcepath)) { return $null }
	if([string]::IsNullOrEmpty($IncludeString)) { return $null }
	
	Echo-Log "Inventory log files from $SourcePath"
	$Logs = Get-ChildItem -path $Sourcepath -Include $IncludeString -Recurse -Force -errorAction SilentlyContinue | 
		where {$_.psIsContainer -ne $true} | ?{ $_.fullname -notmatch "\\unused\\?"}
	
	if($Logs) {
		$Destination = $Global:SPATZ_DESTINATION

		# Create a destination folder for this computer which contains the computername in the pathname
		$DestFolder = $Destination + (gc env:computername)
		if([System.IO.Directory]::Exists($DestFolder) -ne $true) {
			$temp = New-Item -ItemType directory -Path $DestFolder -ErrorAction SilentlyContinue
		}	

		foreach ($logfile in $Logs) { 
			$Pathname = $logfile.Fullname			
						
			$SourceFolder = """" + $Pathname + """"					
			$RBDestFolder = $DestFolder + '\' + $Pathname.Replace($SPATZ_Folder, "")
			$RBDestFolder = Split-Path $RBDestFolder -Parent			
			$RBDestFolder = """" + $RBDestFolder + """"
						
			$Rbcp_Arguments = "$SourceFolder $RBDestFolder /Y /C"
			Echo-Log $Rbcp_Arguments
			if($Global:DEBUG) {	
				$ErrorCode = 99		
			} else {
				$ErrorCode = (Start-Process -FilePath "xcopy.exe" -ArgumentList $Rbcp_Arguments -Wait -Passthru).ExitCode  
			}
		}
	}
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

#
# Make the script wait for a random amount of seconds
# Default is wait to a random time of max 1800 seconds (30 minutes)
#
Function Wait_Random {
	Param (
		[int]$min_seconds = 1,
		[int]$max_seconds = 1800
    )
	if([string]::IsNullOrEmpty($min_seconds)) { return $null }
	if([string]::IsNullOrEmpty($max_seconds)) { return $null }
	
	if($Global:DEBUG -eq $true) { return $null }
	
	if($min_seconds -lt 0) { $min_seconds = 0 }
	if($max_seconds -lt 0) { $max_seconds = 0 }
	echo-log "Minimum wait time: $min_seconds seconds."
	echo-log "Maximum wait time: $max_seconds seconds."
	if($max_seconds -gt $min_seconds) { 		
		$wait_time = Get-Random -minimum $min_seconds -maximum $max_seconds
		echo-log "Script is set to wait to $wait_time seconds. Waiting..."
		Start-Sleep -s $wait_time
	}		
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
if($Global:DEBUG) {
	$logfile = "Spatz_Archiving-DEBUG"
} else {
	$logfile = "Spatz_Archiving-$cdtime"
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

if(Test-Path 'C:\Logboek\robocopy.log') { Remove-Item 'C:\Logboek\robocopy.log' -Force -ErrorAction SilentlyContinue }
if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

# Check if the application is installed 
$SPATZ_APPL = 'C:\Program Files (x86)\Matuschek\Spatz Studio NET\SPATZ Studio NET.exe'
$AppPresent = [System.IO.File]::Exists($SPATZ_APPL)

# ********************************
$AppPresent = $True
# ********************************

if($AppPresent -ne $true) {
	Echo-Log "Spatz Studio NET.exe could not be found. We assume that archiving is not needed."	
} else {

	# Wait a random period of 1-1800 seconds. 
	# This will spread the load on the archive server and prevents all Spatz PC's to back-up all at once.
	Wait_Random 

	# Trailing slash must not be removed!
	$SPATZ_Folder = 'D:\Matuschek\'

	# Create needed folders on archive server first
	[Void](Create_RemoteArchive_Folders)	
		
	$SPATZ_Include = 'Backup_Base'
	$temp = Backup_SPATZ_Data $SPATZ_Folder $SPATZ_Include -Mirror $True -CRWExclude $True
	
	$SPATZ_Include = 'QA_Base'	
	$temp = Backup_SPATZ_Data $SPATZ_Folder $SPATZ_Include -Mirror $False -CRWExclude $True
	
	$SPATZ_Include = 'Error_Base'	
	$temp = Backup_SPATZ_Data $SPATZ_Folder $SPATZ_Include -Mirror $False -CRWExclude $False
	
	$SPATZ_Include = 'OnlineStatistic'	
	$temp = Backup_SPATZ_Data $SPATZ_Folder $SPATZ_Include -Mirror $False -CRWExclude $True
	
	$SPATZ_Include = '*.log'
	$temp = Backup_Spatz_Logs $SPATZ_Folder $SPATZ_Include
}

# We are done. Close the log.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if($AppPresent -eq $true) {
	#Copy the current logfile to the archive share
	$LogPath = "C:\Logboek\$logfile.log"
	$DestPath = $Global:SPATZ_DESTINATION + (gc env:computername) + "\log\archive.log"
	if([System.IO.File]::Exists($DestPath)) {
		Remove-Item $DestPath -Recurse -ErrorAction SilentlyContinue
	}
	Copy-Item $LogPath $DestPath -ErrorAction SilentlyContinue
}