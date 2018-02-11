Function Get-ScheduledTask
{
	param([string]$ComputerName = "localhost")	
	$Command = "schtasks.exe /query /s $ComputerName"
	Invoke-Expression $Command
	Clear-Variable Command -ErrorAction SilentlyContinue	
}

Function End-ScheduledTask
{
	param(
	[string]$ComputerName = "localhost",
	[string]$TaskName = "blank"
	)

	If ((Get-ScheduledTask -ComputerName $ComputerName) -match $TaskName)
	{
		$Command = "schtasks.exe /End /s $ComputerName /tn $TaskName "
		Invoke-Expression $Command
		Clear-Variable Command -ErrorAction SilentlyContinue			 
	}
}

Function Run-ScheduledTask
{
	param(
	[string]$ComputerName = "localhost",
	[string]$TaskName = "blank"
	)

	If ((Get-ScheduledTask -ComputerName $ComputerName) -match $TaskName)
	{
		$Command = "schtasks.exe /Run /s $ComputerName /tn $TaskName "
		Invoke-Expression $Command
		Clear-Variable Command -ErrorAction SilentlyContinue			 
	}
}

Function Remove-ScheduledTask
{
	param(
	[string]$ComputerName = "localhost",
	[string]$TaskName = "blank"
	)

	If ((Get-ScheduledTask -ComputerName $ComputerName) -match $TaskName)
	{
		$Command = "schtasks.exe /delete /s $ComputerName /tn $TaskName /F"
		Invoke-Expression $Command
		Clear-Variable Command -ErrorAction SilentlyContinue
	} 
}

Function Create-ScheduledTask
{
	param(
	[string]$ComputerName = "localhost",
	[string]$RunAsUser = "System",
	[string]$TaskName = "MyTask",
	[string]$TaskRun = '"C:\Program Files\Scripts\Script.vbs"',
	[string]$Schedule = "Monthly",
	[string]$Modifier = "second",
	[string]$Days = "SUN",
	[string]$Months = '"MAR,JUN,SEP,DEC"',
	[string]$StartTime = "13:00",
	[string]$EndTime = "17:00",
	[string]$Interval = "60"	
	)
	$Command = "schtasks.exe /create /s $ComputerName /ru $RunAsUser /tn $TaskName /tr $TaskRun /sc $Schedule /mo $Modifier /d $Days /m $Months /st $StartTime /et $EndTime /ri $Interval /F"
	Invoke-Expression $Command
	Clear-Variable Command -ErrorAction SilentlyContinue
}


$strFilter = "(&(objectCategory=Computer)(OperatingSystem=Windows Server*))"

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
    End-ScheduledTask -ComputerName $objItem.name -TaskName "Std-DUMPNTFSv3"
	Remove-ScheduledTask -ComputerName $objItem.name -TaskName "Std-DUMPNTFSv3"
}


