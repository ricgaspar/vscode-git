# ---------------------------------------------------------
# Collect user information from AD
# Marcel Jussen
# 9-10-2012
# ---------------------------------------------------------

cls
Add-PSSnapin Quest.ActiveRoles.ADManagement

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

Function Replace-SingleQuote-ToDbl {
	param (
		[string]$String = $null
	)	
	$single_quote = [string]([char]39)
	if(($String -eq $null) -or ($String.Length -eq 0)) { return "" }
	$String = $String.Replace($single_quote,$single_quote + $single_quote)
	return $String
}

Function Import_UsersAD {
	$OuDomain = "DC=nedcar,DC=nl" 
	
	Echo-Log "Query AD for user objects."
	# $colResults  = Get-QADUser -searchRoot $OuDomain -SamAccountName "OKE1690"
	$colResults  = Get-QADUser -searchRoot $OuDomain  -SizeLimit 0
	
	if($colResults -ne $null) {
		$count = $colResults.Count
		Echo-Log "AD User collection: $count accounts."
	
		$query = "delete from UsersAD"
		Echo-Log $query
		$data = Query-SQL $query $SQLconn

		$query = "delete from UsersAD_SAM"
		Echo-Log $query
		$data = Query-SQL $query $SQLconn
	}

	foreach($account in $colResults) {
	
	$SamAccountName = Replace-SingleQuote-ToDbl $account.SamAccountName		
	$DN = Replace-SingleQuote-ToDbl $account.DN
	$Sid = Replace-SingleQuote-ToDbl $account.Sid	
	
	$Query = "INSERT INTO [SECDUMP].[dbo].[UsersAD_SAM] ([systemname],[domainname],[poldatetime],[SamAccountName],[SID],[DN]) "+ 
    	"VALUES (" + 
		"'"	+ $Env:COMPUTERNAME + "'," +
		"'"	+ $Env:USERDOMAIN + "'," +
		"GetDate()," + 
		"'"	+ $SamAccountName + "'," +
		"'"	+ $Sid + "'," +
		"'"	+ $DN + "')"				
	$data = Query-SQL $query $SQLconn
	
	}
}

Function Check_Import {
	$query = "select * from vw_UsersAD_ImportFailures"	
	$data = Query-SQL $query $SQLconn
}

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($SQLconn.state -eq "Closed") { exit }   	

Echo-Log "---------------------------------"

Import_UsersAD
Check_Import

Echo-Log "---------------------------------"
Echo-Log "End script $ScriptName"

Close-LogSystem
Remove-SQLconnection $SQLconn