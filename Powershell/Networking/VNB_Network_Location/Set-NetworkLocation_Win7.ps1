$PrivateNetwork=1
$WorkNetwork=2
$PublicNetwork=3

$NetworkNameFilter = 'nedcar.nl'
$NetworkTypeAssignment = $WorkNetwork

$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
$connections = $networkListManager.GetNetworkConnections()
$connections | % `
{
	If ($_.GetNetwork().GetName() -like $NetworkNameFilter) {
		$_.GetNetwork().SetCategory($NetworkTypeAssignment) 
	}
}
 