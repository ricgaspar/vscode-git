cls

$Computername = 'vs103'

$FeaturesToDelete = @( 'Web-Server', 'NET-WCF-Services45', 'NET-Framework-45-ASPNET' )
$Features = Get-WindowsFeature -Computername $Computername | Where-Object -FilterScript { $_.Installed -Eq $TRUE }
if($Features) {
	ForEach( $FeatureName in $FeaturesToDelete ) {
		
		$result = $Features | Where-Object -FilterScript { $_.name -Eq $FeatureName}
		if($result) { 
			Write-Host "Deleting $FeatureName on $Computername"
			Uninstall-WindowsFeature -ComputerName $Computername -Name $FeatureName 
		} else {
			Write-Host "$FeatureName is not installed on $Computername"
		}
	}
}
