# =========================================================
# Export DHCP info to SQL database secdump.
#
# Marcel Jussen
# 1-03-2016
#
# =========================================================
#Requires -version 3.0
cls
# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$UDLConnection = Read-UDLConnectionString $glb_UDL

$DHCPServer = 'dc07.nedcar.nl'

$ExportFile = "$env:TEMP\dhcpexport.xml"
# Export-DhcpServer -Computername 'DC07' -file $ExportFile
[xml]$XmlDocument = Get-Content -Path $ExportFile

$Computername = $Env:COMPUTERNAME
$ScopeErase = $true
$ReserveErase = $true

$Scopes = $XmlDocument.DHCPServer.IPv4.Scopes.Scope
Foreach($SC in $Scopes) {
	$Scope = "" | Select DHCPServer,ScopeID,Name,SuperScopename,SubnetMask,StartRange,EndRange,LeaseDuration,State,Type,Description
	$Scope.DHCPServer = $DHCPServer
	$Scope.ScopeID = $SC.ScopeId
	$Scope.Name = $SC.Name	
	$Scope.ScopeID = $SC.ScopeID
	$Scope.Name = $SC.Name
	$Scope.SuperScopename = $SC.SuperScopename
	$Scope.SubnetMask = $SC.SubnetMask
	$Scope.StartRange = $SC.StartRange
	$Scope.EndRange = $SC.EndRange
	$Scope.LeaseDuration = $SC.LeaseDuration
	$Scope.State = $SC.State
	$Scope.Type = $SC.Type
	$Scope.Description = $SC.Description
	
	$ObjectData = $Scope
	$ObjectName = 'VNB_DHCP_SCOPES'
	$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
	Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $ScopeErase	
	$ScopeErase = $False
	
	Foreach($Reservation in $SC.Reservations.Reservation) {
		$Res = "" | Select DHCPServer, ScopeID, ScopeName, Name, IPAddress, ClientId, MACAddress, Description
		$Res.DHCPServer = $DHCPServer
		$Res.ScopeID = $SC.ScopeId 
		$Res.ScopeName = $SC.Name
		$Res.Name = $Reservation.Name
		$Res.IPAddress = $Reservation.IPAddress
		$Res.ClientId = $Reservation.ClientID
		$MAC = [string]$($Reservation.ClientID)
		$MAC = ($MAC.replace('-','')).ToUpper()
		$Res.MACAddress = $MAC
		$Res.Description = $Reservation.Description
		
		$ObjectData = $Res
		$ObjectName = 'VNB_DHCP_RESERVATIONS'
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $ReserveErase		
		$ReserveErase = $False
	}	
}