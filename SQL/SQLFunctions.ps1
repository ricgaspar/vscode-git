##############################################################################
##
## Invoke-SqlCommand.ps1
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
## Return the results of a SQL query or operation
##
## ie:
##
##    ## Use Windows authentication
##    Invoke-SqlCommand.ps1 -Sql "SELECT TOP 10 * FROM Orders"
##
##    ## Use SQL Authentication
##    $cred = Get-Credential
##    Invoke-SqlCommand.ps1 -Sql "SELECT TOP 10 * FROM Orders" -Cred $cred
##
##    ## Perform an update
##    $server = "MYSERVER"
##    $database = "Master"
##    $sql = "UPDATE Orders SET EmployeeID = 6 WHERE OrderID = 10248"
##    Invoke-SqlCommand $server $database $sql
##
##    $sql = "EXEC SalesByCategory 'Beverages'"
##    Invoke-SqlCommand -Sql $sql
##
##    ## Access an access database
##    Invoke-SqlCommand (Resolve-Path access_test.mdb) -Sql "SELECT * FROM Users"
##    
##    ## Access an excel file
##    Invoke-SqlCommand (Resolve-Path xls_test.xls) -Sql 'SELECT * FROM [Sheet1$]'
##
##############################################################################

param(
    [string] $dataSource = "s001.nedcar.nl",
    [string] $database = "secdump",      
    [string] $sqlCommand = $(throw "Please specify a query."),
    [System.Management.Automation.PsCredential] $credential
  )


## Prepare the authentication information. By default, we pick
## Windows authentication
$authentication = "Integrated Security=SSPI;"

## If the user supplies a credential, then they want SQL
## authentication
if($credential)
{
    $plainCred = $credential.GetNetworkCredential()
    $authentication = 
        ("uid={0};pwd={1};" -f $plainCred.Username,$plainCred.Password)
}

## Prepare the connection string out of the information they
## provide
$connectionString = "Provider=sqloledb; " +
                    "Data Source=$dataSource; " +
                    "Initial Catalog=$database; " +
                    "$authentication; "

## Connect to the data source and open it
$connection = New-Object System.Data.OleDb.OleDbConnection $connectionString
$command = New-Object System.Data.OleDb.OleDbCommand $sqlCommand,$connection
$connection.Open()

## Fetch the results, and close the connection
$adapter = New-Object System.Data.OleDb.OleDbDataAdapter $command
$dataset = New-Object System.Data.DataSet
[void] $adapter.Fill($dataSet)
$connection.Close()

## Return all of the rows from their query
$dataSet.Tables | Select-Object -Expand Rows