cls

$Computername = 's007.nedcar.nl'
$MPIO_DSM = gwmi -ComputerName $Computername -NameSpace root\WMI -Class MPIO_REGISTERED_DSM -ErrorAction SilentlyContinue
if($MPIO_DSM) {
	Write-Host 'MPIO DSM is installed.'
	foreach($Parms in $MPIO_DSM.DsmParameters) {
		Write-Host "$($Parms.DsmName) $($Parms.DsmVersion.MajorVersion).$($Parms.DsmVersion.MinorVersion).$($Parms.DsmVersion.ProductBuild) QFE Number: $($Parms.DsmVersion.QfeNumber)"		
	}
	
	$MPIO_PATHINFO = gwmi -ComputerName $Computername -NameSpace root\WMI -Class MPIO_PATH_INFORMATION -ErrorAction SilentlyContinue
	if($MPIO_PATHINFO) {		
		Write-Host ('-'*60)
		$PathInfoInstance = $MPIO_PATHINFO.InstanceName
		Write-Host "Instance: $PathInfoInstance"
		Write-Host "Number of paths: $($MPIO_PATHINFO.NumberPaths)"
		foreach($Path in $MPIO_PATHINFO.PathList) {			
			$PathId = $Path.Pathid			
			$MPIO_PATHHEALTH = gwmi -ComputerName $Computername -NameSpace root\WMI -Class MPIO_PATH_INFORMATION -ErrorAction SilentlyContinue | ? { $_.InstanceName -eq $PathInfoInstance } | Select PathList
			foreach($pp in $MPIO_PATHHEALTH) {
				if($pp.PathList.PathId -eq $PathId) {
					Write-Host "[$PathId] $($pp.PathList.Adaptername) Bus number: $($pp.PathList.BusNumber) Device number: $($pp.PathList.DeviceNumber)"
				}
			}
			
		}
	} else {
		Write-Host 'ERROR: Could not retrieve MPIO PATH information.'
	}
} else {
	Write-Host 'Could not connect to WMI MPIO DSM class. MPIO is not installed?'
}