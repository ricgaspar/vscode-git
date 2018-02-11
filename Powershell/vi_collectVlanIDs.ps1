Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer S009

$MyCol = @()
$vmhosts = Get-VMHost | Get-View 
foreach ($vmhost in $vmhosts)
{	
	Write-Host $vmhost.Name
	
	$networkSystem = Get-view $vmhost.ConfigManager.NetworkSystem	
	foreach($netSys in $networkSystem)
	{		
		foreach($pnic in $netSys.NetworkConfig.Pnic)
		{
			$subnets = $netSys.QueryNetworkHint($pnic.Device)
			foreach($pnicHint in $subnets)
			{				
				foreach($pnicIpHint in $pnicHint.Subnet)
				{
					$NetworkInfo = "" | select-Object Host, Device, VlanId, IpSubnet
					$NetworkInfo.Host = $vmhost.Name
					$NetworkInfo.Device = $pnicHint.Device
					$NetworkInfo.VlanId = $pnicIpHint.VlanId
					$NetworkInfo.IpSubnet = $pnicIpHint.IpSubnet					
					$MyCol += $NetworkInfo
				}
			}
		}
	}
}

$filename = "D:\vi_collect_vlanid.csv"
$Mycol | Sort Host, Device | Export-Csv $filename -NoTypeInformation -delimiter ';'

