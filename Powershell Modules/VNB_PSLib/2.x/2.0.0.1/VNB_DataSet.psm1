<#
.SYNOPSIS
    VNB Library - Transact SQL and DataSet object functions

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	18-01-2016
 
.DESCRIPTION
    Functions to update SQL databases with PS DataSet objects
#>

function Get-SQLDataType { 
    param(
		$type
	) 

	switch ($type) 
    { 
        'Boolean' 	{ '[nvarchar](MAX)' }          
        'Byte' 		{ '[nvarchar](1)' } 
		'Byte[]' 	{ '[varbinary](MAX)' }
        'Char' 		{ '[nvarchar](1)' } 
        'Datetime' 	{ '[datetime]' } 
        'Decimal' 	{ '[bigint]' } 
        'Double' 	{ '[bigint]' }
        'System.Guid' 		{ 'uniqueidentifier' } 
		'Int'	 	{ '[int]' }
		'Int16' 	{ '[smallint]' }		
		'Int32' 	{ '[int]' }
		'Int64' 	{ '[bigint]' }		
		'Single' 	{ '[smalint]' }
		'String' 	{ '[nvarchar](MAX)' }
		'UInt16' 	{ '[int]' }
		'UInt32' 	{ '[bigint]' }
		'UInt64' 	{ '[real]' }		
        default 	{ 'nvarchar(MAX)' }
    }
} 

#######################
function Get-Type
{
    param($type)

$types = @(
'System.Boolean',
'System.Byte[]',
'System.Byte',
'System.Char',
'System.Datetime',
'System.Decimal',
'System.Double',
'System.Guid',
'System.Int16',
'System.Int32',
'System.Int64',
'System.Single',
'System.UInt16',
'System.UInt32',
'System.UInt64')

    if ( $types -contains $type ) {
        Write-Output "$type"
    }
    else {
        Write-Output 'System.String'
        
    }
} #Get-Type

#######################
<#
.SYNOPSIS
Creates a DataTable for an object
.DESCRIPTION
Creates a DataTable based on an objects properties.
.INPUTS
Object
    Any object can be piped to Out-DataTable
.OUTPUTS
   System.Data.DataTable
.EXAMPLE
$dt = Get-psdrive| Out-DataTable
This example creates a DataTable from the properties of Get-psdrive and assigns output to $dt variable
.EXAMPLE
$dt = Get-Process | Out-DataTable
This example creates a DataTable from the properties of Get-Process and assigns output to $dt variable
.NOTES
Adapted from script by Marc van Orsouw see link
Version History
v1.0  - Chad Miller - Initial Release
v1.1  - Chad Miller - Fixed Issue with Properties
v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0
v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties
v1.4  - Chad Miller - Corrected issue with DBNull
v1.5  - Chad Miller - Updated example
v1.6  - Chad Miller - Added column datatype logic with default to string
v1.7  - Chad Miller - Fixed issue with IsArray
v1.8  - Boe Prox    - Fixed issue null values being applied to rows causing errors using [DBNull]::Value
.LINK
http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx
#>
function Out-DataTable
{
    [CmdletBinding()]
    param([Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject)

    Begin
    {
        $dt = new-object Data.datatable  
        $First = $true 
    }
    Process
    {
        foreach ($object in $InputObject)
        {
            $DR = $DT.NewRow()  
            foreach($property in $object.PsObject.get_properties())
            {  
                if ($first)
                {  
                    $Col =  new-object Data.DataColumn  
                    $Col.ColumnName = $property.Name.ToString()  
                    if ($property.value)
                    {
                        if ($property.value -isnot [System.DBNull]) {
                            $Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)")
                         }
                    }
                    $DT.Columns.Add($Col)
                }  
                if ($property.Gettype().IsArray) {
                    $DR.Item($property.Name) =$property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1
                }  
               else {
                    If ($Property.Value) {
                        $DR.Item($Property.Name) = $Property.Value
                    } Else {
                        $DR.Item($Property.Name)=[DBNull]::Value
                    }
                }
            }  
            $DT.Rows.Add($DR)  
            $First = $false
        }
    } 
     
    End
    {
        Write-Output @(,($dt))
    }

} #Out-DataTable

New-Alias -Name 'New-DataTable' -Value 'Out-DataTable' 

Function New-WMIClassTable {
# ---------------------------------------------------------
# Checks if a table exists for the requested WMI class
# Creates the table if needed. 
# Returns true if a table was created.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
		
		[parameter(Mandatory=$True)]
		[string]
		$ClassName,
		
		[parameter(Mandatory=$True)]
		[string]
		$Computername
	)
	
	begin {
		# 
		# Open SQL client connection
		$SqlClientConnection = new-object System.Data.SqlClient.SqlConnection($UDLConnection)    	
    	$SqlClientConnection.Open()		
	}
	
	process {
		#
		# Get data from WMI class and only select those properties we got from SQL.
		$WMIObj = Get-WmiObject -Class $ClassName -Computer $Computername -ErrorAction SilentlyContinue
		if($WMIObj) {
			$query = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$ClassName'"
			$Tablecheck = Query-SQL $query $SqlClientConnection
			if($Tablecheck) {				
				return $false
			} else {
				# Convert data into DataTable object
				$dtable = $WMIObj | Out-DataTable 
				if($dtable) {
					$Columns = $dtable.columns
					$query = "CREATE TABLE [dbo].[$ClassName] ("
	
					$query += '[Systemname] [nvarchar](50) NOT NULL,'
					$query += '[Domainname] [nvarchar](50) NOT NULL,'
					$query += '[PolDateTime] [datetime] NOT NULL,'
	
					foreach($Column in $Columns) {
						# Get column data 
						$ColumnName = $Column.ColumnName
						$ColumnType = $Column.DataType
						
						#
						# Change WMI types to SQL types
						$ValType = Get-SQLDataType $ColumnType
						if($ValType -eq 'ERROR') {
							Write-Host "ERROR: $ColumnName $ColumnName $ValType"
						}
						
						#
						# Filter out restricted column names						
						$RestrictedColumnNames = @(
							'Systemname',
							'Domainname',
							'PolDateTime'
						)
						
						#
						# Filter out unwanted WMI properties
						$RestrictedColumnNames += @(
							'__GENUS',
							'__CLASS',
							'__SUPERCLASS',
							'__DYNASTY',
							'__RELPATH',
							'__PROPERTY_COUNT',
							'__DERIVATION',
							'__SERVER',
							'__NAMESPACE',
							'__PATH',
							'Scope',
							'Path',
							'Options'
							'ClassPath',
							'Properties',
							'SystemProperties',
							'Qualifiers',
							'Site',
							'Container'
						)
						
						if($RestrictedColumnNames -contains $ColumnName) {
							# this ColumnName is unwanted.
						} else {
							$query += "[$ColumnName] $Valtype NULL,"
						}						
					}
					
					#
					# Remove the last comma character
					$query = $query -replace ".$"
					
					$query += " ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]"					
					# $query	
					$QueryResult = (Query-SQL $query $SqlClientConnection)
					return $true
				}
			}
		} else {
			# The WMI object does not exist?
			return $false
		}
	}
	
	end {
		#
		# Close the SQL client connection
		$SqlClientConnection.Close()		
	}
}

Function Send-WMIClass {
# ---------------------------------------------------------
# Sends values of a WMI class properties to SQL table.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
		
		[parameter(Mandatory=$True)]
		[string]
		$ClassName,
		
		[parameter(Mandatory=$False)]
		[string]
		$Computername = $env:COMPUTERNAME,
		
		[parameter(Mandatory=$False)]
		[bool]
		$Erase = $True
	)
	begin {			
		# 
		# Open SQL client connection
		$SqlClientConnection = new-object System.Data.SqlClient.SqlConnection($UDLConnection)    	
    	$SqlClientConnection.Open()
		
		# Check for presence of global variable Domainname
		if($Global:Domainname) { 
			$strDomainName = $Global:Domainname 
		} else {
			$strDomainName = $env:USERDOMAIN
		}
	}
	process {		
	
		#
		# Query column names from table.
		$query = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$ClassName' and not(COLUMN_NAME = 'Systemname') and not(COLUMN_NAME = 'Domainname') and not(COLUMN_NAME = 'PolDateTime')"	
		$PropertyNames = Query-SQL $query $SqlClientConnection
		if($PropertyNames) {
			#
			# Create array needed to select properties from WMI object
			$SelectArray = @( @{Name="Systemname"; Expression={$Computername}}, 
				@{Name="Domainname"; Expression={$strDomainName}}, 
				@{Name="PolDateTime"; Expression={get-date}} )
			$SelectArray += $PropertyNames | Select -ExpandProperty 'COLUMN_NAME'

			#
			# Delete previous data from table 
			if($Erase -eq $True) { 
				$query = "delete from dbo.$ClassName where systemname = '" + $Computername + "'"	
				[void](Query-SQL $query $SqlClientConnection)
			}
		
			#
			# Get data from WMI class and only select those properties we got from SQL.
			$WMIObj = Get-WmiObject -Class $ClassName -Computer $Computername -ErrorAction SilentlyContinue | Select $SelectArray
			if($WMIObj) {
				#
				# Convert data into DataTable object
				$dtable = $WMIObj | Out-DataTable 
		
				#
				# Dump datatable to SQL
				$SqlBulkCopy = new-object ("System.Data.SqlClient.SqlBulkCopy") $SqlClientConnection
				$SqlBulkCopy.DestinationTableName = "dbo.$ClassName"
				$SqlBulkCopy.WriteToServer($dtable)
			}
		}		
	}
	end {
		#
		# Close the SQL client connection
		$SqlClientConnection.Close()		
	}
}


Function New-VNBObjectTable_DataSetTable {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
		
		[parameter(Mandatory=$True)]		
		$ObjectDataSetTable,
		
		[parameter(Mandatory=$True)]
		[string]
		$ObjectName
	)
	
	begin {
		# 
		# Open SQL client connection
		$SqlClientConnection = new-object System.Data.SqlClient.SqlConnection($UDLConnection)    	
    	$SqlClientConnection.Open()		
	}
	process {
		$query = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$ObjectName'"
		$Tablecheck = Query-SQL $query $SqlClientConnection
		if(!($Tablecheck)) {						
			$Columns = $ObjectDataSetTable.columns
			$query = "CREATE TABLE [dbo].[$ObjectName] ("
	
			$query += '[Systemname] [nvarchar](50) NOT NULL,'
			$query += '[Domainname] [nvarchar](50) NOT NULL,'
			$query += '[PolDateTime] [datetime] NOT NULL,'
	
			foreach($Column in $Columns) {
				# Get column data 
				$ColumnName = $Column.ColumnName
				$ColumnType = $Column.DataType
				
				#
				# Change WMI types to SQL types
				$ValType = 'ERROR'
				$ValType = Get-SQLDataType $ColumnType
				if($ValType -eq 'ERROR') {
					Write-Host "ERROR: $ColumnName $ColumnName $ValType"
				}
						
				#
				# Filter out restricted column names						
				$RestrictedColumnNames = @(
					'Systemname',
					'Domainname',
					'PolDateTime'
				)
						
				#
				# Filter out unwanted WMI properties
				$RestrictedColumnNames += @(
					'__GENUS',
					'__CLASS',
					'__SUPERCLASS',
					'__DYNASTY',
					'__RELPATH',
					'__PROPERTY_COUNT',
					'__DERIVATION',
					'__SERVER',
					'__NAMESPACE',
					'__PATH',
					'Scope',
					'Path',
					'Options'
					'ClassPath',
					'Properties',
					'SystemProperties',
					'Qualifiers',
					'Site',
					'Container'
				)
						
				if($RestrictedColumnNames -contains $ColumnName) {
					# this ColumnName is unwanted.
				} else {
					$query += "[$ColumnName] $Valtype NULL,"
				}						
			}
					
			#
			# Remove the last comma character
			$query = $query -replace ".$"
			
			$query += " ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]"					
			# $query	
			$QueryResult = (Query-SQL $query $SqlClientConnection)
			$result = $true
		}
	}
	end {		
		#
		# Close the SQL client connection
		$SqlClientConnection.Close()
		
		return $result
	}
}

Function New-VNBObjectTable {
# ---------------------------------------------------------
# Checks if a table exists for the requested custom VNB class
# Creates the table if needed. 
# Returns true if a table was created.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
		
		[parameter(Mandatory=$True)]
		[string]
		$ObjectName,
		
		[parameter(Mandatory=$True)]
		$ObjectData
	)
	
	begin {
		
	}
	
	process {
		#
		# Get data from custom class and only select those properties we got from SQL.
		
		if($ObjectData) {
			# 
			# Open SQL client connection
			$SqlClientConnection = new-object System.Data.SqlClient.SqlConnection($UDLConnection)    	
    		$SqlClientConnection.Open()		
		
			$query = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$ObjectName'"
			$Tablecheck = Query-SQL $query $SqlClientConnection
			#
			# Close the SQL client connection
			$SqlClientConnection.Close()
			
			if($Tablecheck) {				
				return $false
			} else {				
				# Convert data into DataTable object
				$ObjectDataSetTable = $ObjectData | Out-DataTable
				if($ObjectDataSetTable) {				
					New-VNBObjectTable_DataSetTable -UDLConnection $UDLConnection -ObjectDataSetTable $ObjectDataSetTable -ObjectName $ObjectName												
				}
			}
		} else {
			# The WMI object does not exist?
			return $false
		}
	}
	
	end {
				
	}
}

Function Send-VNBDataSetTable {
# ---------------------------------------------------------
# Sends values of custom VNB object properties to SQL table.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
		
		[parameter(Mandatory=$True)]
		[string]
		$ObjectName,
		
		[parameter(Mandatory=$True)]
		$ObjectDataSetTable,
		
		[parameter(Mandatory=$False)]
		[string]
		$Computername = $env:COMPUTERNAME,
		
		[parameter(Mandatory=$False)]
		[string]
		$Erase = $True
	)
	
	begin {			
		# 
		# Open SQL client connection
		$SqlClientConnection = new-object System.Data.SqlClient.SqlConnection($UDLConnection)
    	$SqlClientConnection.Open()
	}
	process {
		#
		# Delete previous data from table 
		if($Erase -eq $True) { 
			$query = "delete from dbo.$ObjectName where systemname = '" + $Computername + "'"	
			[void](Query-SQL $query $SqlClientConnection)
		}
				
		#
		try {
			# Dump datatable to SQL
			$SqlBulkCopy = new-object ("System.Data.SqlClient.SqlBulkCopy") $SqlClientConnection
			$SqlBulkCopy.DestinationTableName = "dbo.$ObjectName"
			$SqlBulkCopy.WriteToServer($ObjectDataSetTable)
		}
		catch {
			$ErrorMessage = $_.Exception.Message
    		$FailedItem = $_.Exception.ItemName
			Write-Host "SqlBulkCopy ended in error."
			Write-Host $ErrorMessage
		}
	
	}
	end {
		#
		# Close the SQL client connection
		$SqlClientConnection.Close()		
	}
}

Function Send-VNBObject {
# ---------------------------------------------------------
# Sends values of custom VNB object properties to SQL table.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
		
		[parameter(Mandatory=$True)]
		[string]
		$ObjectName,
		
		[parameter(Mandatory=$True)]
		$ObjectData,
		
		[parameter(Mandatory=$False)]
		[string]
		$Computername = $env:COMPUTERNAME,
		
		[parameter(Mandatory=$False)]
		[string]
		$Erase = $True
	)
	
	begin {					
		# Check for presence of global variable Domainname
		if($Global:Domainname) { 
			$strDomainName = $Global:Domainname 
		} else {
			$strDomainName = $env:USERDOMAIN
		}
	}
	
	process {		
		# 
		# Open SQL client connection
		$SqlClientConnection = new-object System.Data.SqlClient.SqlConnection($UDLConnection)    	
    	$SqlClientConnection.Open()
	
		#
		# Query column names from table.
		$query = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$ObjectName' and not(COLUMN_NAME = 'Systemname') and not(COLUMN_NAME = 'Domainname') and not(COLUMN_NAME = 'PolDateTime')"	
		$PropertyNames = Query-SQL $query $SqlClientConnection
		#
		# Close the SQL client connection
		$SqlClientConnection.Close()			
		
		if($PropertyNames) {
			#
			# Create array needed to select properties from WMI object
			$SelectArray = @( @{Name="Systemname"; Expression={$Computername}}, 
				@{Name="Domainname"; Expression={$strDomainName}}, 
				@{Name="PolDateTime"; Expression={get-date}} )
			$SelectArray += $PropertyNames | Select -ExpandProperty 'COLUMN_NAME'
					
			#
			# Get data from object and only select those properties we got from SQL.
			$ObjectDataSubSet = $ObjectData | Select $SelectArray
			
			# Convert data into DataTable object
			$ObjectDataSetTable  = $ObjectDataSubSet | Out-DataTable
			if($ObjectDataSetTable) {
				Send-VNBDataSetTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectDataSetTable $ObjectDataSetTable -Computername $Computername -Erase $Erase 
			}				
		}		
	}
	end {
			
	}
}

# ---------------------------------------------------------
# Convert a Hash to and Object
# $Object =  $Hash | ConvertTo-Object
# ---------------------------------------------------------
Function ConvertTo-Object {
	param (
		$Hashtable
	)
	Begin {
		$object = New-Object PSObject
	}
	Process {
		$_.GetEnumerator() |
			ForEach-Object { Add-Member -InputObject $object `
				-MemberType NoteProperty -Name $_.Name -Value $_.Value }
	}
	End {
		return $object
	}
}

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *