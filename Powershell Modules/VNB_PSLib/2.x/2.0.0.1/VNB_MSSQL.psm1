<#
.SYNOPSIS
    VNB Library - MS SQL - TransAct SQL functions

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	06-11-2016
 
.DESCRIPTION
    TransAct SQL functions
#>
#Requires -version 3.0

# Pre-defined global variables
$Global:glb_SecdumpUDLPath = "$Env:ALLUSERSPROFILE\VDL Nedcar\Secdump"
$Global:glb_UDL = "$Global:glb_SecdumpUDLPath\secdump.udl"

function Initialize-UDL {
# ---------------------------------------------------------
# Initializes Global variables #
# ---------------------------------------------------------
	# Library data path is defined in VNB_Logging.ps1 and must be initialised before this module!
	if(!(Test-Path $Global:glb_UDL)) { 
		Remove-Variable -Scope Global -Name glb_UDL -Force
	}
}

function New-SQLconnection {
# ---------------------------------------------------------
# Creates a SQL ADO connection object
# ---------------------------------------------------------
	[CmdletBinding()]
    Param (
		[parameter(Mandatory=$True)]
    	[string]
		$server,
		
		[parameter(Mandatory=$False)]
        [string]
		$database = "master",
		
		[parameter(Mandatory=$False)]
        [string]
		$connectionName = "libSQL"
    )    
	
	Process {
    	if (test-path variable:\conn) {
        	$conn.close()
    	} else {
        	$conn = new-object ('System.Data.SqlClient.SqlConnection')
	    }		
    	$connString = "Server=$server;Integrated Security=SSPI;Database=$database;Application Name=$connectionName"
    	$conn.ConnectionString = $connString
    	$conn.StatisticsEnabled = $true
    	$conn.Open()
		
    	return $conn
	}
}

function New-UDLSQLconnection {
# ---------------------------------------------------------
# Creates a SQL ADO connection object
# ---------------------------------------------------------
	[CmdletBinding()]
    Param (
		[parameter(Mandatory=$True)]
    	[string]
		$UDLConnection
    )    
	
	Process {
    	if (test-path variable:\conn) {
        	$conn.close()
    	} else {
        	$conn = new-object ('System.Data.SqlClient.SqlConnection')
	    }		    	
    	$conn.ConnectionString = $UDLConnection
    	$conn.StatisticsEnabled = $true
    	$conn.Open()
		
    	return $conn
	}
}

function Invoke-SQLQuery {
# ---------------------------------------------------------
# Executes a TS query against the ADO connection
# and returns a table with the results
# ---------------------------------------------------------
	[CmdletBinding()]
    Param (
		[parameter(Mandatory=$True)]
    	[string]
		$query,
		
		[parameter(Mandatory=$True)]
    	$conn, 
    	
		[parameter(Mandatory=$False)]
		[int]
		$CommandTimeout = 30
    )	
	
	Process {
		$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
		$sqlCmd.CommandTimeout = $CommandTimeout
		$SqlCmd.CommandText = $query
		$SqlCmd.Connection = $conn	
		$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter	
		$SqlAdapter.SelectCommand = $SqlCmd	
		$DataSet = New-Object System.Data.DataSet
		$Records = $SqlAdapter.Fill($DataSet)
		return $DataSet.Tables[0]
	}
}
Set-Alias Query-SQL Invoke-SQLQuery

function Invoke-QuerySQLNulled {
# ---------------------------------------------------------
# Executes a non-query (does not return a table)
# ---------------------------------------------------------
	[CmdletBinding()]
    Param (
		[parameter(Mandatory=$True)]
    	[string]
		$query, 
			
    	[parameter(Mandatory=$True)]
    	$conn, 
    	
		[parameter(Mandatory=$False)]
		[int]
		$CommandTimeout = 30
    )		
	Process {
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
}
Set-Alias NonQuery-SQL Invoke-QuerySQLNulled

function Close-SQLquery {
# ---------------------------------------------------------
# Close the SQL query
# ---------------------------------------------------------
	[CmdletBinding()]
    Param (
		[parameter(Mandatory=$True)]
		[string]
		$query
	)
	Process {
    	$query.close()
    	$query = $null
	}
}

function Remove-SQLconnection {
# ---------------------------------------------------------
# Close the SQL connection
# ---------------------------------------------------------
	[CmdletBinding()]
    Param ( 
		[parameter(Mandatory=$True)]
		$connection 
	)
	Process {
    	$connection.close()
    	$connection = $null
	}
}

#
# Read ADO connection string from UDL file
#
function Read-UDLConnectionString {
	[CmdletBinding()]
	param(		
		[Parameter(Mandatory=$true)] 
		[string]
		$UDLFile
	)
	Process {
		try {
			(Get-Content $UDLFile)[2..10] | Out-String
		} 
		catch { }	
	}
}

Set-Alias -Name 'Read-UDL-ConnectionString' -Value 'Read-UDLConnectionString'

function New-UDLTempConnectionString {
# ---------------------------------------------------------
# Starts ADO UDL connection application and creates a temporary UDL file 
# with ADO connection information.
# ---------------------------------------------------------
	Begin {
		$UDLFile = "$env:temp\connection.udl"
	}
	Process {		
		New-Item $UDLFile -ItemType File -Force | Out-Null
		Start-Process $UDLFile -Wait
		try {
			(Get-Content $UDLFile)[2..10] | Out-String
		} catch { }
		Remove-Item $path
	}
}

Set-Alias -Name 'Create-UDLTempConnectionString' -Value 'New-UDLTempConnectionString'

function Invoke-UDLSQLQuery {
# ---------------------------------------------------------
# Invoke SQL query with ADO connection string
# Returns a hash with results
# ---------------------------------------------------------
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)] 
		[string]
		$query,
		
		[Parameter(Mandatory=$true)] 
		[string]
		$connectionstring
	)

	Process {
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
	}
	
	End {
		$rs.Close()
		$db.Close()
	}
}

Set-Alias -Name 'Invoke-UDL-SQL' -Value 'Invoke-UDLSQLQuery'

Function Remove-Table {
# ---------------------------------------------------------
# Invoke SQL query to drop a table in the ADO db connection
# ---------------------------------------------------------
	param (		
		[Parameter(Mandatory=$true)]
		[string]
		$TableName,
		
		[Parameter(Mandatory=$true)]
		[string]
		$ADOConnection
	)
	
	Process {
		$TSQL = "IF (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = '$TableName')) BEGIN DROP TABLE [dbo].[$TableName] END"
		Invoke-SQLQuery $TSQL $ADOConnection		
	}
}

Set-Alias -Name 'Drop-Table' -Value 'Remove-Table'

# --------------------------------------------------------- 
# Initialise UDL file
# --------------------------------------------------------- 
Initialize-UDL

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *