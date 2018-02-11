#-----------------------------------------------------------------------
#
# Configure Display PC 
# Marcel Jussen
# 8-6-2015
#
#-----------------------------------------------------------------------
Function Create_Task_XML { 
	param (
		[string]
		$host_name, 
		[string]
		$task_name, 
		$xml,
		[string]
		$task_user = "SYSTEM", 
		[string]
		$task_pass = ""
	)	
    Append-Log "Task name: $task_name"
    Append-Log "Definition: $xml"
	$result = schtasks /Create /TN "$task_name" /XML "$xml" /RU "$task_user" /RP "$task_pass"
    Append-Log "Result: $result"
}

Function Exists_Task {
	param (
		[string]
		$hostname, 
		
		[string]
		$taskname
	)	
	$sch = New-Object -ComObject("Schedule.Service")
	$sch.connect($hostname)
	$tasks = $sch.getfolder("\").gettasks(0)
	foreach ($task in $tasks) {
		if($task.Name -match $taskname) { return $true }
	}
	return $false
}

#-----------------------------------------------------------------------
#
# Write text to screen and log file at the same time
#
Function Append-Log {
	param (
		[string]
		$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

#
# Check if we are running during a SCCM Task Sequence
#
Function SCCM_TaskSeq_Active {
	$tsenv = $null	
	try { $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue }
	catch { 	}
	$result = [Boolean](($tsenv -ne $null))
	return $result	
}

#-----------------------------------------------------------------------
$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$ComputerName = $Env:COMPUTERNAME
$version = '0.0.0'
$TS = SCCM_TaskSeq_Active

$bl_ScheduledTaskCreated = $False
$TasksSourcePath = $PSScriptRoot 

$IndicatorFile = $env:SystemDrive + "\Windows\Patchlog\Task.Force domain group policy update.present"
if(Test-Path($IndicatorFile)) { Remove-Item $SCRIPTLOG -ErrorAction SilentlyContinue }

$SCRIPTLOG = $env:SystemDrive + "\Windows\Patchlog\Configure-SchedTask.log"	
if(Test-Path($SCRIPTLOG)) { Remove-Item $SCRIPTLOG -ErrorAction SilentlyContinue }
Append-Log ("-" * 80)
Append-Log "Version = $version"
if($TS) { Append-Log "This script is running during a SCCM Task Sequence." }
Append-Log "Source folder: $TasksSourcePath"
Append-Log ("-" * 80)


Append-Log "Checking registry parameter."
$RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
$val = Get-ItemProperty -Path $RegPath -Name "disabledomaincreds"
if($val.disabledomaincreds -ne 0) {
	Append-Log "LSA DisableDomaincreds is not set to zero."
	# Enforce values if exists
	Set-ItemProperty -Path $RegPath -Name disabledomaincreds -Value 0 -ErrorAction SilentlyContinue		
} else {
    Append-Log "LSA DisableDomaiCreds is zero. We can create tasks."
}

#
# Check if scheduled task is present. If not, create the task.
#
$Configure_Task = 'Force domain group policy update'
$xml_task = "$TasksSourcePath\Force domain group policy update.xml"

Append-Log ("-" * 80)
Append-Log "Checking presence of scheduled task $Configure_Task"
$task = Exists_Task -hostname $ComputerName -taskname $Configure_Task
if($task) {
	Append-Log "Scheduled task $Configure_Task exist."
} else {	
	Append-Log "Scheduled task $Configure_Task does not exist."
	Append-Log "Create task with $xml_task"
	if ([IO.File]::Exists($xml_task)) {
		Create_Task_XML -host_name $ComputerName -task_name $Configure_Task -xml $xml_task
		$bl_ScheduledTaskCreated = Exists_Task -hostname $ComputerName -taskname $Configure_Task		 
	} else {
		Append-Log "CRITICAL ERROR: Scheduled task configuration file '$xml_task' was not found."
		Return -2
	}
}

if($bl_ScheduledTaskCreated -eq $True) {
    Add-Content $IndicatorFile $message -ErrorAction SilentlyContinue
    Append-Log "$message '$Configure_Task' was successfully created."
} else {
	Append-Log "ERROR: Scheduled task $Configure_Task was not created."
}

if($val.disabledomaincreds -ne 0) {
    Append-Log "Setting LSA disabledomaincreds to previous value."
    Set-ItemProperty -Path $RegPath -Name disabledomaincreds -Value $val.disabledomaincreds -ErrorAction SilentlyContinue		
}

#
# Done!
#
Append-Log ("-" * 80)
Append-Log "Ended script $PSScriptName from $PSScriptRoot"
Append-Log ("-" * 80)