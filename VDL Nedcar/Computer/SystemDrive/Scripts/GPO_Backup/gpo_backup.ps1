# ---------------------------------------------------------
#
# Backup GPO to temp folder, create ZIP archive from folder and move ZIP to secure location.
# Marcel Jussen
# 5-11-2014
#
# ---------------------------------------------------------
#Requires -version 2.0

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1


Function FileZipFolders {
	[cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()] 
        [string]$FSOFolder,
		[ValidateNotNullOrEmpty()] 
        [string]$ZipFile
    )
	
	Process {	
		$Exitcode = $null		
		if(Test-Path $FSOFolder) { 			
			$ZipAction = 'M -r'
			$CommandLineExe = "C:\Program Files\Winrar\winrar.exe"			
			$CommandParams = "$ZipAction -ilogC:\Logboek\gpo_backup_winrar.log -inul $ZipFile $FSOFolder"
			
			Echo-Log "Executing : $CommandLineExe"
			Echo-Log "Parameters: $CommandParams"
			
			#starts a process, waits for it to finish and then checks the exit code.
			$p = Start-Process $CommandLineExe -ArgumentList $CommandParams -wait -NoNewWindow -PassThru
			$HasExited = $p.HasExited
			$Exitcode = $p.ExitCode
		} else {
			Echo-Log "INFO: $FSOFolder does not exist."
		} 	
		return $Exitcode
	}
} 

# Record start of script.
$BaseStart = Get-Date
$BaseLog = "C:\Logboek\GPO_Backup.log"
$Global:glb_EVENTLOGFile = $BaseLog
[void](Init-Log -LogFileName $BaseLog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Starting backup of GPO's."

Import-Module grouppolicy 

# Create temp folder
$date = get-date -format yyyy-MM-dd
$gpo_backup_temp = "D:\GPO\Backup\$date"
Echo-Log "Creating folder $gpo_backup_temp"
$t = New-Item -Path $gpo_backup_temp -ItemType directory -Force -ErrorAction SilentlyContinue

# Backup GPO to temp folder
Echo-Log "Creating backup."
$Backup = Backup-Gpo -All -Path $gpo_backup_temp
foreach($gpo in $Backup) {
	$DisplayName = $gpo.Displayname
	$GpoId = $gpo.GpoId
	$Id = $gpo.Id
	$BackupDirectory = $gpo.BackupDirectory	
	Echo-Log "$Displayname; $GpoId; $Id; $BackupDirectory"
}

# Create folder to move GPO zip archives to.
$computername = $env:COMPUTERNAME
$gpo_backup_path = "\\s031.nedcar.nl\d$\Data\Backup\GPO\$computername"
if(Test-Path -Path $gpo_backup_path) { 
	Echo-Log "Folder $gpo_backup_path already exists."
} else {
	Echo-Log "Creating folder $gpo_backup_path"
	$t = New-Item -Path $gpo_backup_path -ItemType directory -Force -ErrorAction SilentlyContinue
}

if(Test-Path -Path $gpo_backup_path) { 
	# Create zip archive on backup location
	$ZipFile = $gpo_backup_path + "\gpo-backup-$date.zip"
	if(Test-Path -Path $ZipFile) {
		Echo-Log "An existing ZIP file is being removed."
		Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
	}
	if(Test-Path -Path $ZipFile) {
		Echo-Log "Error: The ZIP file could not be removed."
	} else {
		Echo-Log "The ZIP file was successfully removed."
	
		Echo-Log "Moving folder $gpo_backup_temp into ZIP file."
		Echo-Log "Creating ZIP file $ZipFile"
		FileZipFolders $gpo_backup_temp $ZipFile
	
		Echo-Log "Ready with WinRAR."
		
		if(Test-Path -Path $ZipFile) {
			Echo-Log "The ZIP file was successfully created."
		} else {
			Echo-Log "ERROR: The ZIP file was not successfully created."
		}
	}
} else {
	Echo-Log "ERROR: Could not find $gpo_backup_path"
	Echo-Log "ERROR: Cannot create ZIP file in $gpo_backup_path"
}


Echo-Log "End of script."
$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log "Cleanup running time : $min"				
Echo-Log ("=" * 80)