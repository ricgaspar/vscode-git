# ---------------------------------------------------------
#
# Collect computer information from AD
# Marcel Jussen
# 25-1-2011
# ---------------------------------------------------------

# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

cls

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

$conn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($conn.state -eq "Closed") { exit }

$query = "delete from computersAD"
$data = Query-SQL $query $conn

$Searcher=New-Object System.DirectoryServices.DirectorySearcher
# $Searcher.Filter="(&(objectCategory=Computer)(OperatingSystem=Windows*Server*))"
$Searcher.Filter="(objectCategory=Computer)"
$Searcher.PageSize = 5000
$Results=$Searcher.FindAll()

$query = "delete from hosts"
$data = Query-SQL $query $conn

if (Test-Path "hosts.ini") { Remove-Item "hosts.ini" -Force -ErrorAction SilentlyContinue }
$file = New-Item -type file "hosts.ini"

foreach ($computer in $Results) {
	$cn = "'" + $computer.GetDirectoryEntry().cn + "'" 
	
	$query = "delete from computersAD where systemname = " + $cn
	$data = Query-SQL $query $conn
	
	$DN = "'" + $computer.GetDirectoryEntry().Adspath + "'" 
	$Desc = "'" + $computer.GetDirectoryEntry().description + "'" 
	$dispname = "'" + $computer.GetDirectoryEntry().displayName + "'" 
	$CPage = "'" + $computer.GetDirectoryEntry().codePage + "'" 
	$CCode = "'" + $computer.GetDirectoryEntry().countryCode + "'" 
	$Loc = "'" + $computer.GetDirectoryEntry().location + "'" 
	$OS = "'" + $computer.GetDirectoryEntry().operatingSystem + "'" 
	$OSVer = "'" + $computer.GetDirectoryEntry().operatingSystemVersion + "'" 
	$OSSP = "'" + $computer.GetDirectoryEntry().operatingSystemServicePack + "'" 
	$dnsname = "'" + $computer.GetDirectoryEntry().dNSHostName + "'" 
	$SPN = "'" + $computer.GetDirectoryEntry().servicePrincipalName + "'" 
	
	$query = "insert into computersAD " +
		"(DN,systemname,poldatetime,description,displayName,codePage,countryCode,location,operatingSystem,operatingSystemVersion,operatingSystemServicePack,dNSHostName,servicePrincipalName) " +
		"VALUES (" + $DN + "," + 
		$cn + "," + 
		"getdate()" + "," +		
		$Desc + "," + 
		$dispname + "," + 
		$CPage + "," + 
		$CCode + "," + 
		$Loc + "," + 
		$OS + "," + 
		$OSVer + "," + 
		$OSSP + "," + 
		$dnsname + "," + 
		$SPN + ")"	
	$data = Query-SQL $query $conn
	
	if ($OS.Contains("Server")) {
		$query = "insert into hosts (systemname) values (" + $cn + ")"
		$data = Query-SQL $query $conn
				
		add-content $file $computer.GetDirectoryEntry().cn
	}
}
Remove-SQLconnection $conn

Echo-Log "End script $ScriptName"
