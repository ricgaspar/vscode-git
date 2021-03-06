# ---------------------------------------------------------
# ZIP SPATZ data 
#
# Marcel Jussen
# 27-11-2014
# ---------------------------------------------------------

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $false
$Global:PathRoot = $null

# Trailing slash must not be removed!
$Global:SPATZ_DESTINATION = '\\vs058\Spatz_Archive\'

#
# Checks if the default folder for Spatz exists and inventories the folders that contain
# a predefined pathname pattern.
#
Function Check_SPATZ_Path {
	Param (
		[ValidateNotNullOrEmpty()] 
		[string]$Spatz_Path,
		[ValidateNotNullOrEmpty()] 
		[string]$Include
    ) 
	process {
		if([System.IO.Directory]::Exists($Spatz_Path)) {
			$RootFolders = Get-ChildItem -path $Spatz_Path -Include $Include -Force -errorAction SilentlyContinue |
				where {$_.psIsContainer -eq $true}
			$SystemCol = @()
			foreach($Folder in $RootFolders) {
				$SubFolders = Get-ChildItem -path $Folder.Fullname -Include $Include -Force -errorAction SilentlyContinue |
					where {$_.psIsContainer -eq $true}
				foreach($Sub in $SubFolders) { $SystemCol += $Sub.Fullname }
			}
			$SystemCol
		}
	}	
}

Function QuoteFileName {
	[cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()] 
        [string]$Filepath	
    )
	Process {
		$Filepath = $Filepath.Trim()
		$Filepath = '"' + $Filepath + '"'
		$Filepath = $Filepath.Replace('""', '"')		
		return $Filepath
	}
}

Function FolderToZip {	
	[cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$FSOFolder,
		[ValidateNotNullOrEmpty()]
		[string]$ZipFile 
    )
	
	Process {
		if([System.IO.Directory]::Exists($FSOFolder)) { 
			Echo-Log "Create archive from folder: $FSOFolder"
			Echo-Log "Zip archive path: $ZipFile"						

			$FSOToZipFolder = $FSOFolder + '\*.*'
			$FSOToZipFolder = QuoteFileName($FSOToZipFolder)
			$ZipFile = QuoteFileName($ZipFile)			

			# create shell and run command in RUNAS environment.		
				
			$TempFolder = 'D:\Temp'
			# Create temporary folder if it does not exist
			if([System.IO.Directory]::Exists($TempFolder) -eq $false) {
				$t = [System.IO.Directory]::CreateDirectory($TempFolder)
			}
			
			$CommandLineExe = "C:\Program Files\WinZip\wzzip.exe"	
			$CommandParams = "-a -p -r -yc $ZipFile $FSOToZipFolder"
			
			# Use temporary folder to create ZIP archive if we have one.
			if([System.IO.Directory]::Exists($TempFolder)) {				
				$CommandParams = "-a -b$TempFolder -p -r -ybc $ZipFile $FSOToZipFolder"
			} 				
			
			if([IO.File]::Exists($CommandLineExe)) {
				Echo-Log "Executing : $CommandLineExe"
				Echo-Log "Parameters: $CommandParams"
			
				# Starts a process, waits for it to finish and then checks the exit code.
				$p = Start-Process $CommandLineExe -ArgumentList $CommandParams -wait -NoNewWindow -PassThru
				$HasExited = $p.HasExited
				$Exitcode = $p.ExitCode					
				
				if([System.IO.File]::Exists($ZipFile)) {
					Echo-Log "The ZIP archive was created."
				} else {
					Echo-Log "ERROR: The ZIP archive cannot be found."
				}				
				
			} else {
				Echo-Log "ERROR: Cannot find $CommandLineExe"
			}
		} else {
			Echo-Log "ERROR: Cannot find $FSOFolder"
		}
	}	
} 

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Spatz_Zip"

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

# Check if the application is installed 
$SPATZ_Folder = '\\vdlnc00261\D$\Matuschek'
$AppPresent = [System.IO.Directory]::Exists($SPATZ_Folder)

# ********************************

if($AppPresent -ne $true) {
	Echo-Log "Spatz folder $SPATZ_Folder could not be found. We assume that archiving is not needed."	
} else {
	$BaseFolders = Check_SPATZ_Path $SPATZ_Folder
    ForEach($Folder in $BaseFolders) {
		$Basename = Split-Path $Folder -Leaf
		$ZipDate = Get-Date –f "yyyyMMdd-HHmmss"
		$ZipFile = $SPATZ_Folder + "\ZIP-Archives\$Basename-$ZipDate.zip"
		FolderToZip $Folder $ZipFile
	}
}

# We are done. Close the log.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

#Copy the current logfile to the archive share
$LogPath = "C:\Logboek\$logfile.log"
$DestPath = $Global:SPATZ_DESTINATION + (gc env:computername) + "\log\Spatz_Zip.log"
$DestFolder = Split-Path $DestPath -Parent
if([System.IO.Directory]::Exists($DestFolder) -eq $false) { 
	$t = [System.IO.Directory]::CreateDirectory($DestFolder) 
} else {
	if([System.IO.File]::Exists($DestPath)) {
		Remove-Item $DestPath -Recurse -ErrorAction SilentlyContinue
	}
}
Copy-Item $LogPath $DestPath -ErrorAction SilentlyContinue

