cls

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
[void](Connect-ExchangeServer -auto)

$MailboxStats = Get-MailboxStatistics –Server "vs091.nedcar.nl" -Verbose:$false 
$vs091 = $MailboxStats.Count

$MailboxStats = Get-MailboxStatistics –Server "vs094.nedcar.nl" -Verbose:$false 
$vs094 = $MailboxStats.Count

$total = $vs091 + $vs094
$total