
Import-Module VNB_PSLib

cls
$UDLConnection = Read-UDLConnectionString $glb_UDL
$Erase = $true
$ObjectName = 'VNB_SYSINFO_PSVERSIONTABLE'

$ServerList = Get-ADServers
$ServerNames = ($ServerList.properties).name
[Void]([array]::sort($ServerNames))

$counter = 0
foreach($Computername in $ServerNames) {
	if(($Computername -notlike 'VCS*') -and ($Computername -notlike 'VCP*') -and ($Computername -notlike 'VX*')) {
		$counter++
		Write-Host "$counter : $Computername"
	
		# $ObjectData = Get-DotNetVersions -Computername $Computername
		# if($ObjectData) {								
			# $new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			# Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 		
		# }
		
		# Convert hash table to object. Works only in PS v3	
		$psvt = invoke-command -computername $Computername { $PSVersionTable }		
		$ObjectData = New-Object PSObject -property $psvt
		if($ObjectData) {								
			$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 		
		}
	}
}

