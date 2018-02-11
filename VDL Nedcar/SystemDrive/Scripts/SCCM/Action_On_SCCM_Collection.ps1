$SCCMSiteCode = 'VNB'
$SCCMSiteServer = 's007.nedcar.nl'

$strQuery = 'SELECT * FROM SMS_CM_RES_COLL_VNB001E6'
$Computers = Get-WmiObject -Namespace "Root\SMS\Site_$SCCMSiteCode" -ComputerName $SCCMSiteServer -Query $strQuery `
			-ErrorAction STOP

Foreach($Device in $Computers) {
	$Name = $Device.Name
	$Name
	shutdown.exe -M	\\$Name -R -F -T 00
}