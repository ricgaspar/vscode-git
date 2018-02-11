# ---------------------------------------------------------
# Collect computer last logon information from AD
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

Function Export_LastLogonADSystems {

	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($conn.state -eq "Closed") { exit }   	

	$query = "delete from LastLogonADSystems"
	$data = Query-SQL $query $SQLconn	 

	$DCs = Get-QADComputer -ComputerRole DomainController 
	$DCs | Foreach-Object {
		$dc = $_.Name
		Echo-Log "Exporting data from $dc"
		$coll = Get-QADComputer -Service $dc -IncludedProperties LastLogon -SizeLimit 0
		foreach ($comp in $coll) {
			$systemname = $comp.Name
			$ll = $comp.LastLogon						
			$query = "insert into LastLogonADSystems (systemname, domaincontroller, lastlogon, lastlogonDT) VALUES (" + 
				"'"	+ $systemname + "','" + $dc + "','" + $ll + "','" + $ll + "')"
			$data = Query-SQL $query $SQLconn
		} 
	}
	
	Remove-SQLconnection $SQLconn
}

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

# Export_LastLogonADSystems

Echo-Log "End script $ScriptName"
