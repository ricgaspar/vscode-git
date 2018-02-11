cls
$Computername = 's001'
$Type = "Win32_perfformatteddata" 
$WMIClasses = Get-WmiObject -List -ComputerName $Computername | Where-Object {$_.name -Match $Type}

foreach($class in $WMIClasses)
{
	$class.name
}

# $PerfMonCounterClass = 'Win32_PerfFormattedData_PerfOS_PagingFile'
# $PerfQuery = "Select * from $PerfMonCounterClass where Name='\\??\\D:\\pagefile.sys'"
# $PerfQueryResult = Get-WmiObject -Query $PerfQuery -ErrorAction SilentlyContinue -ComputerName s007
# $PerfQueryResult