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
$query = "select Systemname, DN from vw_VNB_DOMAIN_COMPUTERS_SERVERS"
$data = Query-SQL $query $SQLconn

if ($data -ne $null)
{
    $cntr = 0
    ForEach($rec in $data)
    {
        $cntr++
        $Computername = $rec.Systemname
        write-host "($cntr) $Computername"
        Invoke-Command -Computername "$Computername" {
            try {
                $test = Test-Connection dc07.nedcar.nl -Count 2 -ErrorAction Stop
            }
            catch {
                Write-host "    ERROR: DC07"
            }
            try {
                $test = Test-Connection dc08.nedcar.nl -Count 2 -ErrorAction Stop
            }
            catch {
                Write-host "    ERROR: DC08"
            }
        }
    }
    Write-Host "Total records: $cntr"
} else {
    Write-host "The data returned was NULL."
}

Remove-SQLconnection $SQLconn