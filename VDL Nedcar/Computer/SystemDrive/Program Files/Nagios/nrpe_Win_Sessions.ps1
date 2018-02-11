#
# List active TS and Console sessions 
#

Import-Module PSTerminalServices
cls
$session = Get-TSSession -ComputerName 'localhost' -State 'Active'
if($session -eq $null) {
	"No TS sessions are active"
} else {
	$ClientName = $session.ClientName
	$IPaddress = $session.IPAddress
	$UserName = $session.UserName
	$WindowsStationName = $session.WindowStationName
	"User '$Username' active from $Clientname ($IPAddress) in session $WindowsStationName"
}