# -----------------------------------
Import-Module VNB_PSLib -Force
# -----------------------------------

Function Create-DiscoveryDataTable {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection
	)
	
	#Create Table object
	$tabName = "DiscoveredComputers"
	$table = New-Object system.Data.DataTable $tabName

	#Define Columns
	$column = New-Object system.Data.DataColumn cn,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn dn,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn description,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn name,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn operatingsystem,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn operatingsystemversion,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn dnshostname,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn parent,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn guid,([string])
	$table.columns.add($column)

	$column = New-Object system.Data.DataColumn whencreated,([datetime])
	$table.columns.add($column)
	
	$ObjectName = 'VNB_DSC_COMPUTERS_DISCOVERED'
	
	# Collect all servers from domain
	$domain = New-Object System.DirectoryServices.DirectoryEntry
	$OU = 'LDAP://' + $domain.distinguishedName
	$ComputerList = Get-ADComputers -OU $OU
	
	if($ComputerList) {
		$count = 0 
		foreach($Computername in $ComputerList) {
			$count++
			$DN = [string]($Computername.Properties.adspath)			
		
			$Obj = [adsi]$DN
			$Computername = $Obj.name

			#Create a row
			$row = $table.NewRow()

			#Enter data in the row
			$row.cn = $Obj.cn.Value
			$row.dn = $DN
			$row.description = $Obj.description.Value
			$row.name = $Obj.name.Value
			$row.operatingsystem = $Obj.operatingsystem.Value
			$row.operatingsystemversion = $Obj.operatingsystemversion.Value
			$row.dnshostname = $Obj.dNSHostName.Value
			$row.parent = $Obj.Parent
			$row.guid = $Obj.guid
			$row.whencreated = $Obj.whenCreated.Value

			#Add the row to the table
			$table.Rows.Add($row)		
		}
	}

	if($ComputerList) {
		#Create table if it does not exist.
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $table
	
		#Erase records previously created by this computer
		$Erase = $True		
		$Computername = $env:COMPUTERNAME
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $table -Computername $Computername -Erase $Erase		 		
	}

	return $table
}

$UDLFile = $glb_UDL
if((Test-Path $UDLFile)) {
	$UDLConnection = Read-UDLConnectionString $UDLFile	
	Create-DiscoveryDataTable -UDLConnection $UDLConnection
}
