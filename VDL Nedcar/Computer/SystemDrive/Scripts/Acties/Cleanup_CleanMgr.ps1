<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
	 Created on:   	31-7-2017 09:41
	 Created by:   	MJ90624
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

#Requires -Version 3.0
#Requires -RunAsAdministrator

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

# ---------------------------------------------------------
# Ensures you only refer to variables that exist (great for typos)
# and enforces other "best-practice" coding rules.
Set-StrictMode -Version Latest

# ---------------------------------------------------------
Function Get-ComputerApproval
{
	Param (
		[ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
		[string]$ApprovalINIPath
	)
	
	# ---------------------------------------------------------
	# Check cleanup approval by scanning the approval lists
	# ---------------------------------------------------------
	Process
	{
		$Result = $False
		Try
		{
			$Computername = $env:COMPUTERNAME
			$ApprovedList = Get-Content $ApprovalINIPath
			
			# Check if approved
			if (!$Result) { $Result = (($ApprovedList | Select-String -Pattern '\*') -ne $null) }
			if (!$Result) { $Result = (($ApprovedList | Select-String -Pattern $Computername) -ne $null) }			
		}
		Catch
		{
			Write-Host "ERROR: An error occured during approval check."
			$Result = $False
		}
		
		$Result
	}
}

# =========================================================
# Record start of script.
clear
$BaseStart = Get-Date
# Script Timer
$Global:ScriptStart = Get-Date

$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Write-host "Started script $PSScriptName from $PSScriptRoot"

# Create default folder structure if it is not there already
[void](Create-FolderStruct "$env:SYSTEMDRIVE\Logboek\Cleanup")

$CleanupMgrLog = "$env:SYSTEMDRIVE\Logboek\Cleanup\Cleanup-CleanMgr-Sagerun.log"
$Global:glb_EVENTLOGFile = $CleanupMgrLog
[void](Init-Log -LogFileName $CleanupMgrLog $False -alternate_location $True)

Echo-Log ("=" * 80)
Echo-Log "Starting CleanMgr cleanup process on $($env:Computername)."

# 6.0.6002 Windows 2008 Server / Vista
# 6.1.7601 Windows 2008 R2 Server / Win 7
# 6.2.9200 Windows 2012 Server / Win 8 
# 6.3.9600 Windows 2012 R2 Server / win 8.1
# 10.0.10240 Windows 2016 / Win 10

$OSVersions = "6.0,6.1,6.2,6.3,10.0"
$Win32_OS_Version = (gwmi Win32_OperatingSystem).version
$OSArray = $Win32_OS_Version.split(".")
$OSCheck = $OSArray[0] + "." + $OSArray[1]

# Perform OS version check first
if ($OSVersions.contains($OSCheck))
{
	Echo-Log "OS: $OSCheck ($OSVersions). OS Version check succeeded."
	# ---------------------------------------------------------
	$ApprovalINI = "$($PSScriptRoot)\systems-cleanmgr-sagerun-approved.ini"
	$Approved = Get-ComputerApproval -ApprovalINIPath $ApprovalINI
	if ($Approved)
	{
		# Create reg keys
		try
		{
			$volumeCaches = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
			foreach ($key in $volumeCaches)
			{
				Echo-Log "Creating cleanmgr sagerun key: $($key.PSPath)"
				New-ItemProperty -Path "$($key.PSPath)" -Name StateFlags5432 -Value 2 -Type DWORD -Force | Out-Null
			}
			
			# Run Disk Cleanup 
			$CleanMgrEXE = "$env:SystemRoot\System32\cleanmgr.exe"
			$ArgList = "/sagerun:5432"
			if (Test-Path $CleanMgrEXE)
			{
				Echo-Log "Start cleanmgr '$($key.PSPath)' with argument '$($ArgList)'"
				Start-Process -Wait $CleanMgrEXE -ArgumentList $ArgList
			}
			else
			{
				Echo-Log "ERROR: Cleanmgr.exe could not be found at '$($CleanMgrEXE)'"
				Echo-Log "       Make sure the 'Desktop-Experience' feature is installed."
			}
			
			# Delete the keys		
			$volumeCaches = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
			foreach ($key in $volumeCaches)
			{
				Echo-Log "Removing cleanmgr sagerun key: $($key.PSPath)"
				Remove-ItemProperty -Path "$($key.PSPath)" -Name StateFlags5432 -Force | Out-Null
			}
		}
		catch
		{
			$ErrorMessage = $_.Exception.Message
			$FailedItem = $_.Exception.ItemName
			Echo-Log "ERROR: The cleanup with CleanMgr was aborted."
			Echo-Log "       $FailedItem"
			Echo-Log "       $ErrorMessage"
		}
		
	}
	else
	{
		Echo-Log "ERROR: This computer is not approved to run this script."
		Echo-Log "       Check $($ApprovalINI) for valid systemnames."
	}
}
else
{
	Echo-Log "ERROR: OS: $OSCheck ($OSVersions). OS Version check did not succeed."
	Echo-Log "       The script is aborted."
}

Echo-Log "End of CleanMgr cleanup script."
$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log "Total cleanup running time : $min"
Echo-Log ("=" * 80)

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================
