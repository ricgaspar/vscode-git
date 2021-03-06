#-----------------------------------------------------------------------
# VDL Nedcar Windows server standaard
#
# Author: Marcel Jussen
# 27-10-2015
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
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

#-----------------------------------------------------------------------
$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Write-host "Started script $PSScriptName from $PSScriptRoot"

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
	$NCSTD_INITLOGFILE = $xml_data.ncstd.GetAttribute("initlogfile")
	
	#
	# Set script logging file and remove a previous version if needed.
	#		
	$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\configure-$NCSTD_INITLOGFILE.log"	
	if(Test-Path($SCRIPTLOG)) { Remove-Item $SCRIPTLOG -ErrorAction SilentlyContinue }
	
	#
	# Check if the install.ps1 script log file exists, if so then skip install.ps1
	#
	$NCSTD_SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\configure-$NCSTD_LOGFILE-$NCSTD_VERSION.log"
	if(Test-Path($NCSTD_SCRIPTLOG)) { 
		# 
		# If the log file of the latest version of NCSTD exists there's no need to run init.
		#
		Append-Log "$NCSTD_SCRIPTLOG already exists."
		Append-Log "Init install is not needed."	
	} else {
		#
		# Run NCSTD install.ps1
		#

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.Filename = "powershell"
        $process.StartInfo.Arguments = "-file C:\Scripts\Config\install.ps1"
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        [void]($process.Start())

	}
	
	#
	# Check if the install.ps1 script exists, if so then remove scheduled tasks that runs init.ps1
	#
	if(Test-Path($NCSTD_SCRIPTLOG)) { 
		# Remove NCSTD init scheduled task
		$taskname = "VNB-NCSTD init"
        $Args = "/Delete /TN ""$taskname"" /F"
		
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.Filename = "schtasks"
        $process.StartInfo.Arguments = $Args
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        [void]($process.Start())
		
	}
	
	Append-Log "Ended script $PSScriptName from $PSScriptRoot"
}

Write-host "Ended script $PSScriptName from $PSScriptRoot"