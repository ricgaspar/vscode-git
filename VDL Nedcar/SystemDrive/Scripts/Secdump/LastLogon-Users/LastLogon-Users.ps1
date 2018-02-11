# ---------------------------------------------------------
# Collect user last logon information from AD
# Marcel Jussen
# 8-2-2011
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

cls

Add-PSSnapin Quest.ActiveRoles.ADManagement

Function Export_LastLogonADUsers {

	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($conn.state -eq "Closed") { exit }   	

	$query = "delete from LastLogonADUsers"
	$data = Query-SQL $query $SQLconn	 

	$DCs = Get-QADComputer -ComputerRole DomainController 
	$DCs | Foreach-Object {
		$dc = $_.Name
		Echo-Log "Exporting data from $dc"
		$coll = Get-QADUser -Service $dc -IncludedProperties LastLogon -SizeLimit 0
		foreach ($user in $coll) {
			$username = $user.SamAccountName
			$ll = $user.LastLogon						
			$query = "insert into LastLogonADUsers (username, domaincontroller, lastlogon, lastlogonDT) VALUES (" + 
				"'"	+ $username + "','" + $dc + "','" + $ll + "','" + $ll + "')"
			$data = Query-SQL $query $SQLconn
		} 
	}
	
	Remove-SQLconnection $SQLconn
}

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

# Export_LastLogonADUsers

Echo-Log "End script $ScriptName"
