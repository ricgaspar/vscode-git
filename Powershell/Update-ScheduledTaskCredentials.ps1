

$tasks = Get-Content 'D:\tasks.txt'
$TaskCredential = $HOST.UI.PromptForCredential("Task Credentials","Please specify credentials for the scheduled task.", "", "")
$tasks | Set-ScheduledTaskCredential -ComputerName vs022.nedcar.nl -TaskCredential $TaskCredential

