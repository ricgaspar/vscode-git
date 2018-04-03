# ---------------------------------------------------------
# Marcel Jussen
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

# ---------------------------------------------------------
Function Insert-Record {
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
	if($ObjectData) {
		# Create the table if needed
		$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		if($new) { Echo-Log "Table $ObjectName was created." }

		# Append record to table
		# $RecCount = $($ObjectData.count)
		# Echo-Log "Update table $ObjectName with $RecCount records."
		Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
	}
}

# ---------------------------------------------------------
Function Export-LocalGroups {
	param (
		[Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
		[string]$Computername = $env:COMPUTERNAME
	)
	Echo-Log "Collecting local groups info on $Computername"

	function Get-localgroupmembers {
  		param(
			[string]$Computername = $env:COMPUTERNAME,
    		[string]$localgroupname
  		)
  		$groupobj =[ADSI]"WinNT://$Computername/$localgroupname"
  		$localmembers = @($groupobj.psbase.Invoke("Members"))
  		$localmembers | ForEach-Object {$_.GetType().InvokeMember("Adspath","GetProperty",$null,$_,$null)}
		$($localmembers)
	}

	# Do not perform this export if this computer is a domain controller
	# Detect domain controllers in the domain
	$Computer = Get-WmiObject Win32_ComputerSystem -ComputerName $Computername -ErrorAction SilentlyContinue
	$DCCheck = $true
	if($Computer) {
		$Role = ($Computer).domainrole
		$DCCheck = (($Role -eq 4) -or ($Role -eq 5))
	}
	if($DCCheck) {
		Echo-Log "This computer is a domain controller. Skipping local groups inventory."
		return
	}

	# Define erase of previous records of this computer
	$Erase = $True
	$ObjectName = 'VNB_SYSINFO_COMPUTERLOCALGROUPS'

	$computer = [ADSI]("WinNT://" + $Computername + ",computer")
	$Groups = $computer.psbase.children | Where-Object{$_.psbase.schemaclassname -eq "group"} | Select-Object Name, Description, Path

	# Export local groups
	foreach($LocalGroup in $groups) {
		$GroupObj = "" | Select-Object Name,Description,Path
		$GroupObj.Name = $($LocalGroup.Name)
		$GroupObj.Description = $($LocalGroup.Description)
		$GroupObj.Path = $($LocalGroup.Path)

		# Create the table if needed
		$ObjectData = $GroupObj
		if($ObjectData) {
			Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
			$Erase = $False
		}
	}

	# Define erase of previous records of this computer
	$Erase = $True
	$ObjectName = 'VNB_SYSINFO_COMPUTERLOCALGROUPSMEMBERS'

	# Export members of local groups
	foreach($LocalGroup in $groups) {
		$localgroupname = $($LocalGroup.Name)
		$LocalGroupsMbrCol = @()

		# Create the table if needed
		$LocalGroupsMembers = Get-localgroupmembers $Computername $localgroupname
		ForEach($Member in $LocalGroupsMembers) {
			if([string]$Member -match 'WinNT:') {
				$MbrObj = "" | Select-Object LocalGroupName,Trusteename
				$MbrObj.LocalGroupName = $localgroupname
				$MbrObj.Trusteename = $Member

				# Create the table if needed
				$ObjectData = $MbrObj
				if($ObjectData) {
					if($ObjectData) {
						Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
						$Erase = $False
					}
				}
			}
		}
    }
}

Function Get-Inventory {
	param (
		[Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
		[string]$Computername = $env:COMPUTERNAME
	)

	Export-LocalGroups $Computername
}

Clear-Host

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-SysInfo.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

# Create MSSQL connection
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

# Start inventory
# Get-Inventory -Computername VS069
Get-Inventory -Computername VS070

Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================