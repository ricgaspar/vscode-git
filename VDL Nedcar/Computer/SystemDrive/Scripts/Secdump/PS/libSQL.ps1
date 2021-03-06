# ---------------------------------------------------------
#
# MS SQL Functions
# Marcel Jussen
# 18-04-2014
#
# ---------------------------------------------------------

function New-SQLconnection {
# ---------------------------------------------------------
# Creates a SQL ADO connection object
# ---------------------------------------------------------
    Param (
    	[string]$server,
        [string]$database = "master",
        [string]$connectionName = "libSQL"
    )    
    if (test-path variable:\conn) {
        $conn.close()
    } else {
        $conn = new-object ('System.Data.SqlClient.SqlConnection')
    }		
    $connString = "Server=$server;Integrated Security=SSPI;Database=$database;Application Name=$connectionName"
    $conn.ConnectionString = $connString
    $conn.StatisticsEnabled = $true
    $conn.Open()
	
	if ($conn.state -eq "Closed") {
		$conn
		Error-Log "Failed to establish a connection to SQL server $server on database $database"		
	} 
    return $conn
}

function Query-SQL {
# ---------------------------------------------------------
# Executes a TS query against the ADO connection
# ---------------------------------------------------------
    Param (
    		[string]$query, 
    		$conn, 
    		[int]$CommandTimeout = 30
    )		
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$sqlCmd.CommandTimeout = $CommandTimeout
	$SqlCmd.CommandText = $query
	$SqlCmd.Connection = $conn	
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter	
	$SqlAdapter.SelectCommand = $SqlCmd	
	$DataSet = New-Object System.Data.DataSet
	$Records = $SqlAdapter.Fill($DataSet)
	$DataSet.Tables[0]		 		    
}

function NonQuery-SQL {
# ---------------------------------------------------------
# Executes a non-query (does not return a table)
# ---------------------------------------------------------
    Param (
    		[string]$query, 
    		$conn, 
    		[int]$CommandTimeout = 30
    )    
    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandTimeout = $CommandTimeout
    $sqlCmd.CommandText = $query
    $sqlCmd.Connection = $conn
    $RowsAffected = $sqlCmd.ExecuteNonQuery()
    if ($? -eq $false) {
        $RowsAffected = -2
    }
    return $RowsAffected
}

function Close-SQLquery {
# ---------------------------------------------------------
# Close the SQL query
# ---------------------------------------------------------
    Param (
		[string]$query
	)
    $query.close()
    $query = $null
}

function Remove-SQLconnection {
# ---------------------------------------------------------
# Close the SQL connection
# ---------------------------------------------------------
    Param ( $connection )
    $connection.close()
    $connection = $null
}

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

#
# Invoke SQL query to drop a table in the ADO db connection
#
Function Drop_Table {
	param (		
		$TableName,
		$ADOConnection
	)
	if($ADOConnection -eq $null) { return $null }
	if([string]::IsNullOrEmpty($TableName)) { return $null }
	
	$TSQL = "IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = '$TableName')) BEGIN DROP TABLE [dbo].[$TableName] END"
	Query-SQL $TSQL $ADOConnection
}