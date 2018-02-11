$taskname = 'LijnPC Shutdown'
$hostname = $env:COMPUTERNAME
$sch = New-Object -ComObject("Schedule.Service")
$sch.connect($hostname)
$tasks = $sch.getfolder("\").gettasks(0)
$taskfound = $false
foreach ($task in $tasks) {	if($task.Name -match $taskname) { $taskfound = $true } }
if($taskfound) { return "FOUND" } else { return "MISSING" }