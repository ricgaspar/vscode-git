#-----------------------------------------------------------------------
# VDL Nedcar Windows server standaard
#
# Author: Marcel Jussen
# 29-03-2016
#-----------------------------------------------------------------------

#Requires -version 2.0

#
# Version of NCSTD is read from config.xml
#
$NCSTD_VERSION = $null

# Make sure to run this script from the config folder or else no scheduled tasks are created.
set-location 'C:\Scripts\Config'

#-----------------------------------------------------------------------
#
# Write text to screen and log file at the same time
#
Function Append-Log {
    [CmdletBinding()]
	param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

#
# Execute Robocopy.exe for a file/folder update
#
function rbcpy_update {
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $SourcePath,

		[Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $DestinationPath
	)	
	
	Append-Log "robocopy.exe $SourcePath $DestinationPath /S /E /Z"
	$rbcpy_result = robocopy.exe $SourcePath $DestinationPath /S /E /Z /LOG+:$Rbcpy_log
}


function Start-Process {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $command,

        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $arguments
    )

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.Filename = $command
    $process.StartInfo.Arguments = $arguments
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    [void]($process.Start())
}

#
# Check if OS version is within limits and execute the script
#
function execute-script {
    [CmdletBinding()]
	param (
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]		
        $ScriptPath,
		
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $Version,
		
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $Comment,

		[Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $OSVersions
	)
	
	Append-Log "Executing: $ScriptPath"	
	if(Test-Path($ScriptPath)) {
		Append-Log "File $ScriptPath was found."

        # 6.0.6002 Windows 2008 Server / Vista
        # 6.1.7601 Windows 2008 R2 Server / Win 7
        # 6.2.9200 Windows 2012 Server / Win 8 
        # 6.3.9600 Windows 2012 R2 Server / win 8.1
        # 10.0.10240 Windows 10
        
        $Win32_OS_Version = (gwmi Win32_OperatingSystem).version
		$OSArray = $Win32_OS_Version.split(".")
		$OSCheck = $OSArray[0] + "." + $OSArray[1]
			
		if($OSVersions.contains($OSCheck)) {
			Append-Log "OS: $OSCheck ($OSVersions). OS Version check succeeded."
			
			$extension = [System.IO.Path]::GetExtension($ScriptPath)
			$extension = $extension.ToUpper()
			
			switch ($extension) { 
        		".PS1" { $result = Start-Process -command "powershell" -arguments "-file $ScriptPath $Version" } 
        		".VBS" { $result = Start-Process -command "cscript" -arguments "//NoLogo $ScriptPath $Version" } 
				".CMD" { $result = Start-Process -command "cmd" -arguments "/c $ScriptPath $Version" }         		
    		}
			if($result -ne $null) {
				foreach($line in $result) {
					Append-Log $line
				}
			}
		} else {
			Append-Log "OS: $OSCheck ($OSVersions). Warning: OS Version check did not succeed."		
		}		
	} else {
		Append-Log "ERROR: $ScriptPath cannot be found!"
	}
}

#
# Read script configuration and execute scripts
#
Function exec-configuration-scripts {
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $xml_filepath
	)
	
	Append-Log "Scripts: $xml_filepath"
	if (Test-Path $xml_filepath) {	
		$xml_content  = Get-Content $xml_filepath
		$xml_data = [xml] $xml_content
	
		$scripts = $xml_data.SelectNodes("scripts/script")
		foreach ($script in $scripts) {
			$script_comment = $script.description
			$script_version = $script.version
			if($script_version -eq $null) { $script_version = $NCSTD_VERSION }
			$script_path = $script.path
			$full_path = $PSScriptRoot + "\" + $script_path		
			$script_osversions = $script.os_versions
			execute-script $full_path $script_version $script_comment $script_osversions
		}		
	}
}

#
# Read file/folder updates and execute the update
#
Function exec-update-files {
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $Source,
		
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $Destination
	)
	Append-Log "Updates: $Source $Destination"
	rbcpy_update $Source $Destination
}

#-----------------------------------------------------------------------
$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Write-host "Started script $PSScriptName from $PSScriptRoot"

#
# Erase any previous robocopy log file
#
$Rbcpy_log = "$env:SystemDrive\Logboek\Config\rbcpy.log"
if(Test-Path($Rbcpy_log)) { Remove-Item $Rbcpy_log -ErrorAction SilentlyContinue }

#
# Create logboek folder if it does not exist
#
if(!(Test-Path("$env:SystemDrive\logboek"))) { New-Item "$env:SystemDrive\logboek" -ItemType directory -ErrorAction SilentlyContinue}
if(!(Test-Path("$env:SystemDrive\logboek\config"))) { New-Item "$env:SystemDrive\logboek\config" -ItemType directory -ErrorAction SilentlyContinue}
if(!(Test-Path("$env:SystemDrive\logboek\config\once"))) { New-Item "$env:SystemDrive\logboek\config\once" -ItemType directory -ErrorAction SilentlyContinue}
if(!(Test-Path("$env:SystemDrive\logboek\config\versions"))) { New-Item "$env:SystemDrive\logboek\config\versions" -ItemType directory -ErrorAction SilentlyContinue}

#
# Read configuration XML which must be located in the script folder.
#
$xml_filepath = "$PSScriptRoot\ncstd.xml"
if (Test-Path $xml_filepath) {	
	$xml_content  = Get-Content $xml_filepath
	$xml_data = [xml] $xml_content

	#
	# Get configuration information
	#
	$NCSTD_VERSION = $xml_data.ncstd.GetAttribute("version")
	$NCSTD_TYPE = $xml_data.ncstd.GetAttribute("type")
	$NCSTD_LOGFILE = $xml_data.ncstd.GetAttribute("logfile")
	
	#
	# Set script logging file and remove a previous version if needed.
	#
	$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\configure-$NCSTD_LOGFILE-$NCSTD_VERSION.log"
	if(Test-Path($SCRIPTLOG)) { Remove-Item $SCRIPTLOG -ErrorAction SilentlyContinue }

	#
	# Read File and folder updates and execute
	#
	$fileupdates = $xml_data.SelectNodes("ncstd/updates/fileupdates")
	if($fileupdates -ne $null) {
		foreach ($fileupdate in $fileupdates) {
			$sourcepath = $PSScriptRoot + "\" + $fileupdate.source_path		
			$destinationpath = $fileupdate.destination_path
			exec-update-files $SourcePath $DestinationPath 
		}
	} else {
		Append-Log "Warning: Could not find any valid file/folder updates."
	}
	
	#
	# Read which scripts to execute and do so
	#
	$scripts = $xml_data.SelectNodes("ncstd/scripts")
	if($scripts -ne $null) {
		foreach ($script in $scripts) {
			$script_path = $PSScriptRoot + "\" + $script.path
			$description = $script.description                        
            write-host "$script_path $description"
			exec-configuration-scripts $script_path 
		}
	} else {
		Append-Log "Warning: Could not find any valid scripts."
	}
	
	#
	# We are done
	#
}

Append-Log "Ended script $PSScriptName from $PSScriptRoot"