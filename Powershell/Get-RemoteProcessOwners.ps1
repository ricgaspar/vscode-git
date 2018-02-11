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

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Get-RemoteProcessOwners.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

# Create MSSQL connection
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
$query = "select Systemname from vw_VNB_DOMAIN_COMPUTERS_SERVERS where DN like '%OU=ARTEMIS%'"
$data = Query-SQL $query $SQLconn

remove-item -path 'C:\Temp\process.txt' -Force -ErrorAction SilentlyContinue
$text = "Computername;Process;OwnerDomain;OwnerUser;"
$text | Out-File 'C:\Temp\process.txt' -Append

if ($data -ne $null) {
    $total = $data.count
    $cntr = 0
    ForEach ($rec in $data) {
        $cntr++
        $Computername = $rec.Systemname
        Write-Host "$Computername [$cntr of $total]"

        $Processes = Get-WmiObject Win32_Process -Computername $Computername
        ForEach ($Process in $Processes) {
            $owner = $Process | Invoke-WmiMethod -Name GetOwner
            $text = "$Computername;$($Process.Name);$($owner.domain);$($owner.user);"
            Write-Output $text
            $text | Out-File 'C:\Temp\process.txt' -Append
        }
    }
}
else {
    Write-host "The data returned was NULL."
}

Remove-SQLconnection $SQLconn

Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================