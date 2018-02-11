# ---------------------------------------------------------
#
# Collect Exchange database statistics and store in secdump
# Marcel Jussen
#
# ---------------------------------------------------------
#requires -Version 2

# ---------------------------------------------------------
# INCLUDES
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

cls	
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
Connect-ExchangeServer -auto

$SQLServer = "vs064.nedcar.nl"
$conn = New-SQLconnection $SQLServer "secdump"
if ($conn.state -eq "Closed") {
	$conn
	Error-Log "Failed to establish a connection to $SQLServer"
	EXIT
} else {
	Echo-Log "SQL Connection to $SQLServer succesfully established."
}

# Remove all previous records from this system
$query = "delete from exch_dbstats"
$data = Query-SQL $query $conn

#Import Localized Data
# Import-LocalizedData -BindingVariable Messages
$Databases = Get-MailboxDatabase -Status -ErrorAction SilentlyContinue | Sort Server, Database
foreach($Database in $Databases) {
	If ($Database.DatabaseCreated) {
		$DBMounted = $Database.Mounted
		$MBCount = 0
	  	If ($DBMounted) {
        	$MBCount = @(Get-MailboxStatistics -Database $Database).Count        	
	  	}	  	

		$query = "insert into exch_dbstats " +		
		"(Server, [database], Mailbox_count, poldatetime) " +
		" VALUES ( " +
		$SQ + $Database.Server.Name + $SQ + "," +
        $SQ + $Database.Name + $SQ + "," +
	    $MBCount + ", GetDate()" + ")"					
		$data = Query-SQL $query $conn	
    		  	
	}
}
