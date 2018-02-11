# Start-Sql.ps1
###################################################################################################
# This is a SCRIPT which emits functions and variables into the global scope
# Most importantly, it uses a variable $SqlConnection which is expected to exist....
#
# On my computer, I set default values for the server and database, but not for the query, 
# nor for authentication (I usually use Integrated Security)
###################################################################################################
#   By default when you run this script it:
#     * creates the functions 
#     * initializes the connection
#   But we don't automatically do a query -- unless you pass one in!
#
#   Thus, calling the script with no parameters results in an initialized connection, 
#   but it doesn't return anything, so it's basically silent if there are no errors.
#

# the default server and database
param( 
   $Server = $(Read-Host "SQL Server Name"), 
   $Database = $(Read-Host "Default Database"),  
   $UserName, $Password, $Query )

## Uncomment the next line to start the SqlServer (or fail miserably but silently)
# Get-Service -include "MSSQLSERVER" | where {$_.Status -like "Stopped"} | Start-Service 

#
# change the SqlConnection (it's set to a default when the script it run)
#
function global:Set-SqlConnection( $Server = $(Read-Host "SQL Server Name"), $Database = $(Read-Host "Default Database"),  $UserName , $Password  ) {

  if( ($UserName -gt $null) -and ($Password -gt $null)) {
    $login = "User Id = $UserName; Password = $Password"
  } else {
    $login = "Integrated Security = True"
  }
  $SqlConnection.ConnectionString = "Server = $Server; Database = $Database; $login"
}

#
# A function to perform a query that returns a table full of data
#
function global:Get-SqlDataTable( $Query = $(Read-Host "Enter SQL Query")) {
  if (-not ($SqlConnection.State -like "Open")) { $SqlConnection.Open() }
  $SqlCmd = New-Object System.Data.SqlClient.SqlCommand $Query, $SqlConnection

  $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
  $SqlAdapter.SelectCommand = $SqlCmd

  $DataSet = New-Object System.Data.DataSet
  $SqlAdapter.Fill($DataSet) | Out-Null

  $SqlConnection.Close()
  
  return $DataSet.Tables[0]
}

#
# A function to perform a single-value (series) query.  That is, a query that 
# returns only a single value per row, which we just output strongly typed.
#
function global:Get-SQLQuery($Query = $(Read-Host "Enter SQL Query"), $type = "string")
{
  if (-not ($SqlConnection.State -like "Open")) { $SqlConnection.Open() }
  $SqlCmd = New-Object System.Data.SqlClient.SqlCommand $Query, $SqlConnection

  # $results = @();

  # trap [SqlException]
  # {
    #LogSqlErrors(e.Errors, sqlQuery);
    # throw new DataException("Unable to ExecuteReader(), check EventLog for details.", e);
  # }
  
  $dr = $SqlCmd.ExecuteReader()
  while($dr.Read())
  {
    #$results += $dr.GetValue(0) -as $type
    $dr.GetValue(0) -as $type # emit the value directly, isn't that more PowerShelly?
  }
  $dr.Close()
  $dr.Dispose()

  # return $results
}

# Initialize the SqlConnection variable
Set-Variable SqlConnection (New-Object System.Data.SqlClient.SqlConnection) -Scope Global -Option AllScope -Description "Personal variable for Sql Query functions"

# Initially create the SqlConnection
Set-SqlConnection $Server $Database

# go ahead and run the initial query if we have one...
if( $query -gt $null ) {
  Get-SqlDataTable $Query
}

# Some aliases to let you use the functions with less typing
Set-Alias gdt Get-SqlDataTable  -Option AllScope -scope Global -Description "Personal Function alias from Get-Sql.ps1"
Set-Alias sql Set-SqlConnection -Option AllScope -scope Global -Description "Personal Function alias from Get-Sql.ps1"
Set-Alias gq  Get-SqlQuery      -Option AllScope -scope Global -Description "Personal Function alias from Get-Sql.ps1"