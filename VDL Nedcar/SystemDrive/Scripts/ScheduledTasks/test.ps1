cls

$hostname = 'VS092'
$newtaskname = "VNB-Weekly reboot task"
$task_user = 'SYSTEM'
$task_pass = $null

$taskxml = Get-Content 'D:\Script_Source\Powershell\VNB_PSLib\Scheduled Tasks Inventory\Schedules\za0530.xml'
if($taskxml) {
	Remove-ScheduledTask -computername $hostname -TaskName $newtaskname

	$sch = New-Object -ComObject("Schedule.Service")
	$sch.connect($hostname)
	$folder = $sch.GetFolder("\")
	
	$task = $sch.NewTask($null)
	$task.XmlText = $taskxml
	$folder.RegisterTaskDefinition($newtaskname, $task, 6, $task_user, $task_pass, 1, $null)
}


 








