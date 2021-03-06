#-----------------------------------------------------------------------
# VDL Nedcar Windows server standaard
#
# Configure application script
#
# Author: Marcel Jussen
#-----------------------------------------------------------------------

param (
	[string]$NCSTD_VERSION = '6.0.0.1'
)

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-files-$NCSTD_VERSION.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

function Unblock_Files {
	$ScriptsFolder = $env:SystemDrive + "\Scripts" 
	Get-ChildItem -path $ScriptsFolder -Recurse -Force -errorAction SilentlyContinue |
		where {$_.psIsContainer -eq $false} | Unblock-File
}

function Remove-File-Ncstd {
	param (
		[string]$FilePath,
		[string]$OSVersions
	)
	
	$OSCheck = $False	
	#
	# if OSVersions is not used, always allow by setting OScheck=true.
	#
	if([string]::IsNullOrEmpty($OSVersions)) { $OSCheck = $True }
	
	Append-Log "Remove file: $FilePath"	
	if(Test-Path($FilePath)) {
		Append-Log "File $FilePath was found."
		
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
			Append-Log "Remove file $FilePath"
			Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
		}
	}
}

if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {	
	Unblock_Files
	$xml_filepath = "files.xml"
	if (Test-Path $xml_filepath) {	
		$xml_content  = Get-Content $xml_filepath
		$xml_data = [xml] $xml_content
	
		$files = $xml_data.SelectNodes("files/file")
		foreach ($file in $files) {
			$file_path = $file.path
			$file_osversions = $file.os_versions
			Remove-File-Ncstd $file_path $file_osversions
		}		
	} else {
		Append-Log "ERROR: Cannot find $xmlfile_path"
	}
	Append-Log $msg
}