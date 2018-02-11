
Import-Module VNB_PSLib -Force

$ADSearchFilter = '(objectCategory=Computer)'
$ObjectList = Search-AD -ADSearchFilter $ADSearchFilter
$ComputerList = @()
foreach ($objResult in $ObjectList) {
	$ObjItem = $objResult.Properties
	$ObjComputer = New-Object System.Object
	$ObjComputer | Add-Member -MemberType NoteProperty -Name Name -Value $($ObjItem.name) -Force
	$ObjComputer | Add-Member -MemberType NoteProperty -Name AdsPath -Value $($ObjItem.adspath) -Force
	$ComputerList += $ObjComputer			
}
$ComputerList = $ComputerList | sort @{ expression = { $_.Name }; Descending = $false }
$ComputerList = $ComputerList | Where-Object { $_.AdsPath -match 'Cascade_Clients' }

foreach($Computer in $ComputerList)
{
	$Computername = $($Computer.Name)
	$uri = "http://$Computername.nedcar.nl:5009/Portal/Summary.mwsl?Page=Summary&TemplateFile=summary.xml&DataFile=summary_data.xml"
	
	$request = $null
	$time = try
	{	
		## Request the URI, and measure how long the response took.
		$result1 = Measure-Command { $request = Invoke-WebRequest -Uri $uri }
		$result1.TotalMilliseconds
	}
	catch
	{
   		<# If the request generated an exception (i.e.: 500 server
   		error or 404 not found), we can pull the status code from the
   		Exception.Response property #>
		$request = $_.Exception.Response
		$time = -1
	}
	$result = [PSCustomObject] @{
		Time		 = Get-Date;
		Uri		     = $uri;
		StatusCode   = [int]$request.StatusCode;
		StatusDescription = $request.StatusDescription;
		ResponseLength = $request.RawContentLength;
		TimeTaken    = $time;
	}
	
	$result
}





