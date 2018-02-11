# ---------------------------------------------------------
# Marcel Jussen
# 7-2-2011
# ---------------------------------------------------------
cls
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "s001.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

# ---------------------------------------------------------

# ---------------------------------------------------------
# Retrieve list fron SQL
# ---------------------------------------------------------
Function Export-DHCP-Reservations-Depricated {
    $SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($conn.state -eq "Closed") { exit }   	

	$query = "exec DHCP_Reservations_Depricated"
	$data = Query-SQL $query $SQLconn
	Remove-SQLconnection $SQLconn
	
	return $data
}

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"  

$reservations = Export-DHCP-Reservations-Depricated 
$tmpname = ""
$tmpip = ""
foreach ($res in $reservations) { 
	$Server = $res.Server
	$Scope = $res.Scope
	$IP_Address = $res.IP_Address
	$MAC = $res.MAC
	$Reservation_name = $res.Reservation_name 
	if ($Reservation_name -ne $tmpname) { 
		$ad = Search-AD-Computer $res.Reservation_name
		If($ad -ne 0) {
			Write-Host "Found in Active Directory: $Reservation_name"		
		} else {
			if ( $IP_Address -ne $tmpip ) { 
				If(IsComputerAlive $IP_Address) {
					Write-Host "Host is pingable: $IP_Address $Reservation_name"
				} else {
					Write-Host "We have a winner: $IP_Address $Reservation_name"
				}
			}
			$tmpip = $IP_Address
		}
	}
	$tmpname = $Reservation_name
}

Echo-Log "End script $ScriptName"
