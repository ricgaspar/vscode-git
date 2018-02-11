$strFilter = "(&(objectCategory=Computer)(OperatingSystem=Windows 2000 Server))"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter

$colProplist = "name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
{
	$objItem = $objResult.Properties; 
	Write-Host "Server: " + $objItem.name		
	$Svc = Get-WmiObject -class Win32_Service -namespace "root\CIMV2" -computername $objItem.name | Where-Object { $_.name -eq 'wuauserv' }
	
	Write-Host "- stopping service"
	$Result = $Svc.StartService()
	$Result = $Svc.StopService()	
	if($Result.returnvalue -eq 0) { "success" }
	else
  	{ " $($Result.returnvalue) was reported" }
		
	Write-Host "- disabling service"
	$Result = $Svc.changestartmode("disabled")
	if($Result.returnvalue -eq 0) { "success" }
	else
  	{ " $($Result.returnvalue) was reported" }
  
}


