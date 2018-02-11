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

clear

cls	
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"  

$DBStats = Get-MailboxDatabase "<insert database name>" | Get-MailboxStatistics | Sort totalitemsize -desc | ft displayname, totalitemsize, itemcount

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
$query = "delete from exch_dbstatistics"
$data = Query-SQL $query $conn
# if ($data.gettype() -eq [int]) {Error-Log  "Failed to query SQL server.";EXIT}

$SQ = [char]39
$Systemname = $SQ + $env:COMPUTERNAME + $SQ
$Domainname = $SQ + $env:USERDNSDOMAIN + $SQ

foreach($dbstat in $DBStats) {
	$Servername = $dbstat.ServerName
	$Dbname = $dbstat.Database
	$LastBackup = $dbstat.LastFullBackup
	$DBSizeStr = [string]$dbstat.DatabaseSize
	$temp = $DBSizeStr.split("(")
	if($temp.Count -eq 2) {
		$Size = $temp[1]
		$Size = $Size.replace(",","")
		$Size = $Size.replace(")","")
		$Size = $Size.replace("bytes","")
		$DBSize = [int64]$Size
	} else {
		$DBSize = -1		
	}
	
	$MailBoxName = $dbstat.Name
	
	Echo-Log "$MailBoxName [$Dbname] [$LastBackup] [$DBSize] [$MailBoxName]"
	
	$query = "insert into exch_dbstatistics " +
		"(systemname, domainname, poldatetime, " +
		"servername, [database], lastfullbackup, databasesize, mailboxname) " +
		" VALUES ( $systemname, $domainname, GetDate()," +
		$SQ + $Servername + $SQ + "," +
        $SQ + $Dbname + $SQ + "," +
	    $SQ + $LastBackup + $SQ + "," +
    	$DBSize + "," +
		$SQ + $MailBoxName + $SQ + ")"					
		$data = Query-SQL $query $conn		
}

Remove-SQLconnection $conn

Echo-Log "Ended script $ScriptName"