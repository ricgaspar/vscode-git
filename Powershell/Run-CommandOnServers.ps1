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
$query = "select Systemname, DN from vw_VNB_DOMAIN_COMPUTERS_SERVERS where Systemname = 'VS054'"
$data = Query-SQL $query $SQLconn

if ($data -ne $null)
{
    $cntr = 0
    $Count = [int]$Data.Count
    ForEach ($rec in $data) {
        $cntr++
        $Computername = $rec.Systemname
        write-host "[$cntr of $Count]: $Computername"
        Try {
            $Tst = Test-Connection -ComputerName $Computername
            if ($Tst) {
                $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computername -ErrorAction SilentlyContinue
                if ($OS -ne $null) {
                    $Version = $OS.Version
                    Write-Host "        OS: $($Version)"
                    $SrvOk = $False
                    If ($Version -match '6.') {
                        $SrvOk = $True
                    }
                    If ($Version -match '10.') {
                        $SrvOk = $True
                    }
                }
            }
            else {
                Write-Host "        Cannot connect to this server."
            }

        }
        Catch {
            $SrvOk = $False
        }

        if ($SrvOk -eq $true) {
            Write-Host "        Invoke command block."
            Invoke-Command -Computername $Computername {
                $parameter = 'SNAPSHOTPROVIDERFS'
                $OptFile = 'C:\Program Files\Tivoli\TSM\baclient\dsm.opt'
                if (Test-Path -Path $OptFile) {
                    $Content = Get-Content $OptFile
                    $Found = $Content -Match $Parameter
                    if ($Found -ne $null) {
                        Write-Host "        Search result: '$Found'"
                        Write-Host "        Parameter '$Parameter' was found in DSM.OPT."
                    }
                    else {
                        Write-Host "        Parameter '$Parameter' was not found in DSM.OPT."
                    }
                }
            }
        }
    }
    Write-Host "Done."
    Write-Host "Total updated systems: $cntr"
} else {
    Write-host "The data returned was NULL."
}

Remove-SQLconnection $SQLconn