#-----------------------------------------------------------------------
# VDL Nedcar Windows server standaard
#
# Configure application script
#
# Author: Marcel Jussen
#-----------------------------------------------------------------------

param (
	[string]$NCSTD_VERSION = '6.0.0.3'
)

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-folders-$NCSTD_VERSION.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

function Remove-Folder-Ncstd {
	param (
		[string]$FolderPath,
		[string]$OSVersions
	)
	
	$OSCheck = $False	
	#
	# if OSVersions is not used, always allow by setting OScheck=true.
	#
	if([string]::IsNullOrEmpty($OSVersions)) { $OSCheck = $True }
	
	Append-Log "Remove folder: $FolderPath"	
	if(Test-Path($FolderPath)) {
		Append-Log "Folder $FolderPath was found."
		
		#
		# Check OS versions if parameter OSversions is used
		#
		if($OSCheck -eq $false) {
			$Win32_OS_Version = ( Get-WmiObject Win32_OperatingSystem | select Version).Version
			$OSArray = $Win32_OS_Version.split(".")
			$OSCheck = $OSArray[0] + "." + $OSArray[1]			
			if($OSVersions.contains($OSCheck)) { 
				Append-Log "OS: $OSCheck ($OSVersions). OS Version check succeeded."
				$OSCheck = $true 
			} else {
				Append-Log "OS: $OSCheck ($OSVersions). OS Version check did not succeed."
			}
		}
	
		#
		# Remove file if OSCheck is ok.
		#
		if($OSCheck -eq $true) {
			Append-Log "Remove file $FolderPath"
			Remove-Item $FolderPath -Recurse -Force -ErrorAction SilentlyContinue
		}
	}
}

if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {

	$SName = "\" + $MyInvocation.MyCommand.Name
	$SPath = $MyInvocation.MyCommand.Path
	$SPath = $SPath.Replace($SName, $null)

	$xml_filepath = "$SPath\folders.xml"
	if (Test-Path $xml_filepath) {	
		$xml_content  = Get-Content $xml_filepath
		$xml_data = [xml] $xml_content
	
		$folders = $xml_data.SelectNodes("folders/folder")
		foreach ($folder in $folders) {
			$folder_path = $folder.path
			$folder_osversions = $folder.os_versions
			Remove-Folder-Ncstd $folder_path $folder_osversions
		}		
	} else {
		Write-Host "ERROR: Cannot find $xmlfile_path"
	}
}