Import-Module VNB_PSLib -Force

Function Scan-PSVersion {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]		
		$DTable,
		
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection
	)

	$ObjectName = 'VNB_DSC_PSVersionTable'
	
	# Erase all previous records
	$Erase = $True
	
	foreach($Computer in $DTable) {
		$Computername = $Computer.name
		
		# Convert hash table to object. Works only in PS v3	
		$psvt = invoke-command -computername $Computername { $PSVersionTable }		
		$ObjectData = New-Object PSObject -property $psvt		
		if($ObjectData) {			
			$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
		}
		# Add new records 
		$Erase = $False
	}
}

Function Scan-DiscoveryDataTable {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection
	)
	
	process {		
		# ADODB connections need an implicit Provider type declaration in the UDL connection string
		$ADOProvider = 'Provider=SQLOLEDB.1'
		$ADOConn = $UDLConnection
		if($ADOConn -notcontains $ADOProvider) { $ADOConn = $ADOProvider + ';' + $ADOConn }
		
		try {
			$TSQL = "select name, dnshostname from vw_VNB_DSC_SCANNED_COMPUTERS order by dn"
			
			# Query with ADO connection
			$DTable = Invoke-UDL-SQL -query $TSQL -connectionstring $ADOConn
			if($DTable) {				
				Scan-PSVersion -DTable $DTable -UDLConnection $UDLConnection				
			}
		}
		catch {}
	}		
}

cls

$UDLFile = $glb_UDL
if((Test-Path $UDLFile)) {
	$UDLConnection = Read-UDLConnectionString $UDLFile
	Scan-DiscoveryDataTable -UDLConnection $UDLConnection
}