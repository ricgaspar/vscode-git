# ------------------------------------------------------------------------------
<#
.SYNOPSIS
    Log Wifi signal data to cyclic log file

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	13-07-2015

.CHANGE_DATE
	13-07-2015
 
.DESCRIPTION
    Logs Wifi data to a cyclic log file
#>
# ------------------------------------------------------------------------------
#-requires 3.0


Function Create_Task_XML { 
	param (
		[string] $task_name, 
		[string] $xml,
		[string] $task_user = "SYSTEM", 
		[string] $task_pass = ""
	)	
    Append-Log "Create task name: $task_name"
    Append-Log "Definition: $xml"
	$result = schtasks /Create /TN "$task_name" /XML "$xml" /RU "$task_user" /RP "$task_pass"
    Append-Log "Result: $result"
}

Function Exists_Task {
	param (
		[string] $taskname
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
		[string] $Message
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
	catch { }
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

#
# Create new log file
#
$SCRIPTLOG = 'C:\Windows\Patchlog\Wifi_Data_Logging.log'
if(Test-Path($SCRIPTLOG)) { Remove-Item $SCRIPTLOG -ErrorAction SilentlyContinue }
Append-Log ("-" * 80)
Append-Log "Version = $version"
if($TS) { Append-Log "This script is running during a SCCM Task Sequence." }
Append-Log "Source folder: $TasksSourcePath"
Append-Log ("-" * 80)

#
# Check LSA for credentials issue
#
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
# Create scheduled task if it does not exist
#
$ScheduleTaskName = "Log wifi data"
$ScheduleTaskXML = $TasksSourcePath + "\Log wifi data.xml"
$IndicatorFile = 'C:\Windows\Patchlog\Task.Log wifi data.present'
$bl_ScheduledTaskCreated = $False
if(-not(Exists_Task $ScheduleTaskName)) {	
	if ([IO.File]::Exists($ScheduleTaskXML)) {
		Create_Task_XML -task_name $ScheduleTaskName -xml $ScheduleTaskXML				
	} else {
		Append-Log "CRITICAL ERROR: Scheduled task configuration file '$ScheduleTaskXML' was not found."
		Return -2
	}
}

if(Exists_Task $ScheduleTaskName) {	
	$message = 'Found scheduled task'
	Add-Content $IndicatorFile $message -ErrorAction SilentlyContinue
	Append-Log "$message '$ScheduleTaskName'"
} else {
	remove-item $IndicatorFile -Force -ErrorAction SilentlyContinue		
	Append-Log "ERROR: Scheduled task $Configure_Task was not created."
}

if($val.disabledomaincreds -ne 0) {
    Append-Log "Setting LSA disabledomaincreds to previous value."
    Set-ItemProperty -Path $RegPath -Name disabledomaincreds -Value $val.disabledomaincreds -ErrorAction SilentlyContinue		
}

Append-Log ("-" * 80)

#
# Collect Wifi data and save it to a CSV log per day
#
Append-Log "Collecting WIFI data from NETSH"
$DATA_Logpath = "C:\Windows\Patchlog\WIFI"
$DATA_filename = $DATA_Logpath + '\WIFI-Data-'+ (Get-Date –f "yyyy-MM-dd") + '.csv'
if(Test-Path($DATA_Logpath)) {
	# Log path exists
} else {
	New-Item -ItemType directory -Path $DATA_Logpath -Force -ErrorAction SilentlyContinue
}

$Wifi_Data = (netsh wlan show interfaces)
$DataList = ("Name","Description","GUID", "Physical address", "State", "SSID", "BSSID", "Network type" , "Radio type", "Authentication", "Cipher", "Connection mode", "Channel", "Signal", "Profile")
$Collected = @()
if($Wifi_data) {
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	foreach($parm in $DataList) {
		$Collected += ($Wifi_Data) -Match "^\s+$parm" -Replace "^\s+$parm\s+:\s+",''	-Replace '%',''			
	}
	$Collected += ($Wifi_Data) -Match '^\s+Receive' -replace '\s+Receive\s+rate\s+\(+Mbps\)+\s+:\s+',''
	$Collected += ($Wifi_Data) -Match '^\s+Transmit' -replace '\s+Transmit\s+rate\s+\(+Mbps\)+\s+:\s+',''
	$Collected += $logTime
}
$DataList += 'Receive rate'
$DataList += 'Transmit rate'
$DataList += 'Date'

#
# Create object to hold data
#
$holdarr = @()
$obj = New-Object PSObject
for($i=0; $i -lt 18; $i++) {
	$obj | Add-Member NoteProperty -Name $Datalist[$i] -Value $Collected[$i]
}
$holdarr += $obj
$obj = $null

#
# Export data to log file
#
Append-Log "Exporting data to log"
if(-not (Test-Path $DATA_filename)) {
	Append-Log "Creating new log file"
	$holdarr | export-csv $DATA_filename -NoTypeInformation -Delimiter ';'
} else {
	Append-Log "Appending to pre-existing log file"
	$holdarr | export-csv $DATA_filename -NoTypeInformation -Append -NoClobber -Delimiter ';'
}


#
# Cleanup old
#
Append-Log ("-" * 80)
$Age_in_days = 90
$Now = Get-Date		
$Include = '*.csv'
$Exclude = ''
$LastWrite = $Now.AddDays(- $Age_in_days)
Append-Log "Search log path $DATA_Logpath for logs older than $Age_in_days days"
$Files = Get-ChildItem -path $DATA_Logpath -Include $Include -Exclude $Exclude -Recurse -errorAction SilentlyContinue  |			
	where {$_.psIsContainer -eq $false} | 
	where {$_.DirectoryName -eq $DATA_Logpath} |
	where {$_.LastWriteTime -le "$LastWrite"}

if($files) {
	foreach($file in $files) { 
		$OldFilePath = $File.FullName
		Append-Log "Cleanup old log file: $OldFilepath"
		Remove-Item -Path $OldFilepath -Force -ErrorAction SilentlyContinue
	}
} else {
	Append-Log "No old log files found to delete."
}

#
# Done!
#
Append-Log ("-" * 80)
Append-Log "Ended script $PSScriptName from $PSScriptRoot"
Append-Log ("-" * 80)