#
# Read ADO connection string from UDL file
#
function Read-UDL-ConnectionString {
	param(		
		[Parameter(Mandatory=$true)] [string]$UDLFile
	)	
	try {
		(Get-Content $UDLFile)[2..10] | Out-String
	} catch { }	
}

#
# Starts ADO UDL connection application and creates a temporary UDL file 
# with ADO connection information.
#
function Create-UDL-TempConnectionString {
	$UDLFile = "$env:temp\connection.udl"
	New-Item $UDLFile -ItemType File -Force | Out-Null
	Start-Process $UDLFile -Wait
	try {
		(Get-Content $UDLFile)[2..10] | Out-String
	} catch { }
	Remove-Item $path
}

#
# Invoke SQL query with ADO connection string
# Returns a hash with results
#
function Invoke-UDL-SQL {
	param(
		[Parameter(Mandatory=$true)] $query,
		[Parameter(Mandatory=$true)] $connectionstring
	)

	$db = New-Object -comObject ADODB.Connection
	$db.Open($connectionstring)
	$rs = $db.Execute($query)
	while (!$rs.EOF) {
		$hash = @{}
		foreach ($field in $rs.Fields) {
			$hash.$($field.Name) = $field.Value
		}
		$rs.MoveNext() 
		New-Object PSObject -property $hash
	}
	$rs.Close()
	$db.Close()
}

$udl = Read-UDL-ConnectionString -UDLFile C:\Scripts\Powershell\SQL\secdump.udl
$result = Invoke-UDL-SQL -connectionstring $udl -query "select * from vw_UsersAD"