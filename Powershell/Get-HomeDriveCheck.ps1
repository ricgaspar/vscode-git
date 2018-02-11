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

Clear-Host

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
$query = "SELECT [ISP_USERID],[ISP_COMPOUND_NAME] FROM [SECDUMP].[dbo].[vw_PND_ACCOUNTS_MERGED_VERIFIED] isp where isp.[ISP_AD_INSERT] = 'Y'"
$data = Query-SQL $query $SQLconn

if ($data -ne $null)
{
    $cntr = 0
    ForEach($rec in $data)
    {
        $cntr++
        $ID = $rec.ISP_USERID
        $HomePath = "\\nedcar.nl\office\homes\$ID"
        if (Test-Path -Path $HomePath) {

        }
        else {
            write-host "($cntr) $ID"
        }
    }
    Write-Host "Total records: $cntr"
} else {
    Write-host "The data returned was NULL."
}

Remove-SQLconnection $SQLconn