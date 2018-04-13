<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
	 Created on:   	27-7-2017 08:11
	 Created by:   	MJ90624
	 Organization: 	VDL Nedcar
	 Filename:     	CollectSysinfo-NTFS-ACL.ps1
	===========================================================================
	.DESCRIPTION
		Collect ACL information on all folder stored on NTFS formatted volumes.
#>

#Requires -version 3.0
#Requires -RunAsAdministrator

param (
	[string]$Computername = $env:COMPUTERNAME
)

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

# ---------------------------------------------------------
# Ensures you only refer to variables that exist (great for typos) and 
# enforces some other "best-practice" coding rules.
Set-StrictMode -Version Latest

# ---------------------------------------------------------
# enforces all errors to become terminating unless you override with 
# per-command -ErrorAction parameters or wrap in a try-catch block
$script:ErrorActionPreference = "Stop"

# ---------------------------------------------------------
Function Show-FreeMemory
{
	# ---------------------------------------------------------
	# Show free memory after trigger of garbage collection
	# ---------------------------------------------------------
	try
	{
		# Trigger garbage collect		
		[System.GC]::Collect()
		
		$os = Get-Ciminstance Win32_OperatingSystem
		$pctFree = [math]::Round(($os.FreePhysicalMemory/$os.TotalVisibleMemorySize) * 100, 2)
		$FreeGb = [math]::Round($os.FreePhysicalMemory/1mb, 2)
		$msg = "Physical Memory free: $FreeGb Gb ($pctFree %) post GC collection"
		echo-Log $msg
		
		$pctFree = [math]::Round(($os.FreeVirtualMemory/$os.TotalVirtualMemorySize) * 100, 2)
		$FreeGb = [math]::Round($os.FreeVirtualMemory/1mb, 2)
		$msg = "Virtual Memory free: $FreeGb Gb ($pctFree %)  post GC collection"
		echo-Log $msg
	}
	catch
	{
		Echo-Log $_.Exception | format-list -force
	}
	Clear-LogCache
}

# ---------------------------------------------------------
Function Insert-Record
{
	param (
		[ValidateNotNullOrEmpty()]
		[string]$Computername,
		[ValidateNotNullOrEmpty()]
		[string]$ObjectName,
		[ValidateNotNullOrEmpty()]
		$ObjectData,
		[ValidateNotNullOrEmpty()]
		[bool]$Erase
		
	)
	if ($ObjectData)
	{
		# Create the table if needed
		$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		if ($new) { Echo-Log "Table $ObjectName was created." }
		
		# Append record to table
		# $RecCount = $($ObjectData.count)
		# Echo-Log "Update table $ObjectName with $RecCount records."
		Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
	}
}

# ---------------------------------------------------------
Function Export-NTFS
{
	param (
		[Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
		[string]$Computername = $env:COMPUTERNAME
	)
	
	Echo-Log "Collecting NTFS ACL info on $Computername"
	# Override 
	if ($Computername -ne $env:COMPUTERNAME)
	{
		Echo-Log "This function is not allowed te be run remotely."
		Return 0
	}
	
	function Chk-Identity
	{
		param (
			[string]$Identity,
			[boolean]$LocalGroupInclude = $False
		)
		
		$strSearch = $Identity.trim()
		$strSearch = $strSearch.ToUpper()
		$Res = $False
		if ($strSearch.length -eq 0) { $Res = $True }
		
		# Suppress builtin accounts
		if (!($Res)) { $Res = $strSearch -match "BUILTIN" }
		if (!($Res)) { $Res = $strSearch -match "CREATOR OWNER" }
		if (!($Res)) { $Res = $strSearch -match "NT AUTHORITY" }
		if (!($Res)) { $Res = $strSearch -match "NT SERVICE" }
		if (!($Res)) { $Res = $strSearch -match "S-1-15-2-1" }
		if (!($Res)) { $Res = $strSearch -match "OWNER RIGHTS" }
		if (!($Res)) { $Res = $strSearch -match "APPLICATION PACKAGE" }
		if (!($Res)) { $Res = $strSearch -match "EVERYONE" }
		
		# Check if a ACL group starts with the local computer name
		if ($LocalGroupInclude -eq $False) { if (!($Res)) { $Res = $strSearch -match ($Env:COMPUTERNAME + "\\") } }
		return $Res
	}
	
	function Collect-NTFS-ACL
	{
		param (
			[string]$Computername = $env:COMPUTERNAME,
			[string]$RootPath = 'C:\'
		)
		
		# Define name of SQL table
		$ObjectName = 'VNB_SYSINFO_NTFSACL'
		
		Echo-Log "Building folder list from $RootPath"
		$dirlist = Get-ChildItem $RootPath -Recurse -Directory -ErrorAction SilentlyContinue
		
		Echo-Log "Retrieve ACL for each folder."
		foreach ($folder in $dirlist)
		{
			try
			{
				$FolderPath = $folder.fullname
				$ACL = (Get-Item -LiteralPath $FolderPath).GetAccessControl() | Select * -Expand Access `
				| Select Owner, IdentityReference, FileSystemRights, AccessControlType, IsInherited, InheritanceFlags, PropagationFlags `
				| Where-Object { $_.IsInherited -eq $False } `
				| Where-Object { $_.FileSystemRights -notmatch "\d" }				
				foreach ($accessObject in $ACL)
				{
					$owner = [string]$($accessObject.Owner)
					$inh = [string]$($accessObject.IsInherited)
					$idref = [string]$($accessObject.IdentityReference)
					$fsr = [string]$($accessObject.FileSystemRights)
					$act = [string]$($accessObject.AccessControlType)
					$iflags = [string]$($accessObject.InheritanceFlags)
					$pflags = [string]$($accessObject.PropagationFlags)
					
					$idchk = Chk-Identity -Identity $idref -LocalGroupInclude $True
					if (!$idchk)
					{
						if (($idref.Length -gt 0) -AND ($fsr.Length -gt 0))
						{
							$sqlObj = "" | Select Fullname, Owner, IdentityReference, FileSystemRights, AccessControlType, IsInherited, InheritanceFlags, PropagationFlags
							$sqlObj.Fullname = $($FolderPath)
							$sqlObj.Owner = $owner
							$sqlObj.IdentityReference = $idref
							$sqlObj.FileSystemRights = $fsr
							$sqlObj.AccessControlType = $act
							$sqlObj.IsInherited = $inh
							$sqlObj.InheritanceFlags = $iflags
							$sqlObj.PropagationFlags = $pflags
								
							Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $sqlObj -Erase $Erase
							$Erase = $False
						}
					}					
				}
			}
			catch
			{
				$ErrorMessage = $_.Exception.Message
				Echo-Log "ERROR: ACL retrieval failed on folder $($FolderPath)"
				Echo-Log "       $ErrorMessage"							
								
				$sqlObj = "" | Select Fullname, Owner, IdentityReference, FileSystemRights, AccessControlType, IsInherited, InheritanceFlags, PropagationFlags
				$sqlObj.Fullname = $($FolderPath)
				$sqlObj.Owner = '*Error*'
				$sqlObj.IdentityReference = '*Error*'
				$sqlObj.FileSystemRights = $ErrorMessage
				$sqlObj.AccessControlType = ''
				$sqlObj.IsInherited = ''
				$sqlObj.InheritanceFlags = ''
				$sqlObj.PropagationFlags = ''
				
				Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $sqlObj -Erase $Erase
				$Erase = $False
			}
		}
	}
	
	$Erase = $True
	
	# Inventory logical disk with NTFS filesystems
	try
	{
		$LogicalDisks = Get-WmiObject Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { ($_.MediaType -eq 12) -and ($_.FileSystem -eq 'NTFS') }
		foreach ($Device in $LogicalDisks)
		{
			$RootPath = $Device.Name + '\'
			Collect-NTFS-ACL -Computername $Computername -RootPath $RootPath
		}
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Echo-Log $ErrorMessage
		Echo-Log "ERROR: Collecting NTFS ACL info ended in error."
	}
}

Function Get-Inventory
{
	param (
		[Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
		[string]$Computername = $env:COMPUTERNAME
	)
	
	# Lets retrieve the current weekday
	$nl = New-Object system.globalization.cultureinfo("nl-NL")
	$a = get-date -format ($nl.DateTimeFormat.LongDatePattern)
	$b = ($a -split ' ')
	$weekday = $b[0]
	Echo-Log "Current weekday: $($weekday)" 
	
	# Create an approval record if it does not exist
	$query = "exec prc_VNB_NTFSACL_APPROVAL'$env:COMPUTERNAME'"
	$approval = Invoke-SQLQuery -query $query -conn $Global:UDLConnection
	if ($approval)
	{
		Echo-Log "Approval record status: $($approval.ApprovalStatus)"
		
		# Query for approved weekday
		$query = "exec prc_VNB_NTFSACL_APPROVAL_QUERY '$env:COMPUTERNAME'"
		$approvedday = Invoke-SQLQuery -query $query -conn $Global:UDLConnection		
		if ($approvedday)
		{
			if ($approvedday.Approved -gt 0)
			{
				Echo-Log "The NTFS ACL export is authorized to run today."
				Export-NTFS $Computername
			}
			else
			{
				Echo-Log "The NTFS ACL export is not authorized to run on '$($weekday)'"
			}
		}		
	}	
}

# ---------------------------------------------------------
Clear

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-SysInfo-NTFS-ACL.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
Init-Log -LogFileName $Sysinfolog $False -alternate_location $True | Out-Null
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"
Show-FreeMemory

# Create MSSQL connection
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

# Start inventory
Get-Inventory -Computername $Computername

Show-FreeMemory
Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================