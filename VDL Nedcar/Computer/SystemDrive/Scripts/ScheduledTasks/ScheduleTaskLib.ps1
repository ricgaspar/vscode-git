# =========================================================
#
# Marcel Jussen
# 17-04-2014
#
# =========================================================
cls
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1

Function Remote-ExecCmd {
	param (
		[string]$FQDN,	
		[string]$Command
  	)
	Write-Host "Executing remote command: $command"
	$RemoteProcess=([wmiclass]"\\$FQDN\root\cimv2:Win32_Process").create($Command)
}

Function Remote-GPUpdate {
	param (
		[string]$FQDN		
  	)
	Remote-ExecCmd $FQDN "cmd /c gpupdate /force"		
}

function CheckComputerConnectivity($computer) {
	$bPing = $false
	$bShare = $false
	$result = $false
	#Firstly check if the computer can be pinged.
	"checking $computer"
	$ping = New-Object Net.NetworkInformation.Ping
	$PingResult = $ping.send($computer)
	if ($PingResult.Status.Tostring().ToLower() -eq "success")
	{
		$bPing = $true
		#Secondly check if can browse to the scheduled task share
		$path = "\\$computer\admin`$\tasks"
		$ShareErr = $null
		$ShareResult = Get-ChildItem $path -ErrorVariable ShareErr
		if ($ShareErr.count -eq 0) { $bShare = $true }
						
	}
	if ($bPing -eq $true -and $bShare -eq $true)
	{ 		
		$result = $true 
	} 
	return $result
	
}

Function Create_Task_XML { 
	param (
		$host_name, 
		$task_name, 
		$xml,
		$task_user = "NEDCAR\Scheduler", 
		$task_pass = "pandadroom2002"
	)

	$sch = New-Object -ComObject("Schedule.Service")
	$sch.connect($host_name)
	$folder = $sch.GetFolder("\")
	
	$task = $sch.NewTask($null)  
	$task.XmlText = $xml
	$t = $folder.RegisterTaskDefinition($task_name, $task, 6, $task_user, $task_pass, 1, $null) 
}

Function Exists_Task {
	param (
		$hostname, 
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

Function Delete_Task {
	param (
		$hostname, 
		$taskname
	)	
	if(CheckComputerConnectivity($hostname)) {
		if( Exists_Task $hostname $taskname ) {
			$result = schtasks /Delete /S $hostname /TN "$taskname" /F			
			if( (Exists_Task $hostname $taskname ) -eq $false) { 
				Echo-Log "[$hostname] Successfully deleted task $taskname"
				return $true 
			} else {
				Echo-Log "[$hostname] ERROR: Failed to delete task $taskname"
			}
		}	
	}
	
	return $false
}

Function Copy_Task {
	param (
		$hostname, 
		$taskname, 
		$newtaskname
	)	
	if(CheckComputerConnectivity($hostname)) {
		if( Exists_Task $hostname $taskname ) {
			if( (Exists_Task $hostname $newtaskname) -eq $false ) {
				# Read task parameters 
				$taskxml = schtasks /query /S $hostname /TN $taskname /XML				
				
				# Create new task with old params
				Create_Task_XML $hostname $newtaskname $taskxml

				if( Exists_Task $hostname $newtaskname ) { 
					Echo-Log "[$hostname] Succesfully copied task $taskname to $newtaskname"
					return $true 
				} else {
					Echo-Log "[$hostname] ERROR: Failed to copy task $taskname to $newtaskname"
				}
			} 
		} 		
	} 
	
	return $false
}

Function Rename_Task {
	param (
		$hostname, 
		$taskname, 
		$newtaskname,
		$task_user = "NEDCAR\Scheduler", 
		$task_pass = "pandadroom2002"
	)	
	$res = Copy_Task $hostname $taskname $newtaskname $task_user $task_pass
	if( $res ) {
		if( Delete_Task $hostname $taskname	) {	
			Echo-Log "[$hostname] Successfully renamed task $taskname to $newtaskname"
			return $true 
		} else {
			Echo-Log "[$hostname] ERROR: Failed to rename task $taskname to $newtaskname"
		}
	} 
	
	return $false
}

Function Rename_Task_Batch {
	param (
		$hostname
	)
	
	$tasklist = @()
	$tasklist += "STD-Cleanup"
	$tasklist += "STD-SysInfo"
	$tasklist += "STD-Configure"
	$tasklist += "STD-System-Reboot"
	$tasklist += "STD-DumpNTFSv3"
	$tasklist += "Wekelijkse Reboot"
	$tasklist += "Auto reboot"
	$tasklist += "Automatische reboot"
	
	$namelist = @()
	$namelist += "VNB-Cleanup files"
	$namelist += "VNB-System configuration info"
	$namelist += "VNB-System configuration check"
	$namelist += "VNB-Weekly reboot task"
	$namelist += "VNB-NTFSv3 info dump"
	$namelist += "VNB-Weekly reboot task"
	$namelist += "VNB-Weekly reboot task"
	$namelist += "VNB-Weekly reboot task"

	$max = $tasklist.Count
	$t = 0
	do {
		$result = Rename_Task $hostname $tasklist[$t] $namelist[$t]
		$t++		
	} while ($t -lt $max)	
}

Function Delete_Task_Batch {
	param (
		$hostname
	)
	
	$tasklist = @()
	$tasklist += "STD-WUClientCleanup"	
	$tasklist += "Std-OCS3 Inventory"
	$tasklist += "Std-NETTIME"
	$tasklist += "Std-NTFS-Analyze"
	$tasklist += "Std-NTFS-Defrag"
	$tasklist += "Std-MOM-DeSnooze"
	$tasklist += "Std-MOM-Snooze"
	$tasklist += "Std-W32TM"
	$tasklist += "Std-TSM-Config"
	
	$max = $tasklist.Count
	$t = 0
	do {		
		$result = Delete_Task $hostname $tasklist[$t]
		$t++		
	} while ($t -lt $max)	
}

Function Main {
	$strPath="J:\CLAN\Documentatie\Server_Patching\Reboot scheduled tasks.xlsx"
	$objExcel=New-Object -ComObject Excel.Application
	$objExcel.Visible=$false
	$WorkBook=$objExcel.Workbooks.Open($strPath)
	$worksheet = $workbook.sheets.item("PLAN")
	$intRowMax =  ($worksheet.UsedRange.Rows).count
	$Columnnumber = 1

	for($intRow = 2 ; $intRow -le $intRowMax ; $intRow++)
	{
 		$hostname = $worksheet.cells.item($intRow, 1).value2
		$env = $worksheet.cells.item($intRow, 2).value2
		$pta = $worksheet.cells.item($intRow, 3).value2
		$desc = $worksheet.cells.item($intRow, 4).value2
		$check = $worksheet.cells.item($intRow, 5).value2
		$sched = $worksheet.cells.item($intRow, 6).value2	
		$done = $worksheet.cells.item($intRow, 7).value2
		
		Echo-Log "[$hostname]"
	
		if(($check -eq "NEW")) {
			if(($env -eq "APOLLO") -and ($pta -eq "PROD")) {
				if(CheckComputerConnectivity($hostname)) {
					Echo-Log "[$hostname] Successfully connected to $hostname ($desc)"
				
					Echo-Log "[$hostname] Successfully connected to $hostname"
					Echo-Log "[$hostname] Deleting unused tasks on $hostname"
					Delete_Task_Batch $hostname
					Echo-Log "[$hostname] Deleting unused tasks on $hostname is done."					
				
					Echo-Log "[$hostname] Renaming tasks on $hostname"
					Rename_Task_Batch $hostname 	
					Echo-Log "[$hostname] Renaming tasks on $hostname is done."
										
					if($sched -ne $null) {
						$sched = $sched.Replace(" ","")
						$sched = $sched.Replace(":","")								
						$taskxmlfile = 'D:\Scripts\Powershell\Scheduled Tasks Inventory\Schedules\' + $sched + '.xml'
						Echo-Log "[$hostname] Creating task by $taskxmlfile"
						Create_Task_byXMLFile $hostname $taskxmlfile
					}
					
				} else {
					Echo-Log "[$hostname] ERROR: Could not connect to $hostname"
				}
			}
		} 
	}
	$objexcel.quit()
}

Function Create_Task_byXMLFile {
	param (
		$hostname,
		$xmlfile
	)
	
	$taskname = 'VNB-Weekly reboot task'
	$task_user = 'NEDCAR\Scheduler'
	$task_pass = 'pandadroom2002'
	
	$t = Delete_Task $hostname $taskname	
	if( (Exists_Task $hostname $taskname) -eq $false ) {
		$sch = New-Object -ComObject("Schedule.Service")
		$sch.connect($hostname)
		$folder = $sch.GetFolder("\")

		$taskxml = Get-Content $xmlfile 
	
		$task = $sch.NewTask($null)  
		$task.XmlText = $taskxml
		$t = $folder.RegisterTaskDefinition($taskname, $task, 6, $task_user, $task_pass, 1, $null)
		
		if (Exists_Task $hostname $taskname) {
			Echo-Log "[$hostname] Successfully created task $taskname"
		} else {
			Echo-Log "[$hostname] ERROR: failed to create task $taskname"
		}
	}	
}

Function Main_PC {
	param (
		$hostname,
		$sched
	)
	
	if(CheckComputerConnectivity($hostname)) {
		Echo-Log "[$hostname] Successfully connected to $hostname"
				
		Echo-Log "[$hostname] Successfully connected to $hostname"
		Echo-Log "[$hostname] Deleting unused tasks on $hostname"
		Delete_Task_Batch $hostname
		Echo-Log "[$hostname] Deleting unused tasks on $hostname is done."					
		
		Echo-Log "[$hostname] Renaming tasks on $hostname"
		Rename_Task_Batch $hostname 	
		Echo-Log "[$hostname] Renaming tasks on $hostname is done."
		
		if($sched -ne $null) {
			$sched = $sched.Replace(" ","")
			$sched = $sched.Replace(":","")								
			$taskxmlfile = 'D:\Scripts\Powershell\Scheduled Tasks Inventory\Schedules\' + $sched + '.xml'
			Echo-Log "[$hostname] Creating task by $taskxmlfile"
			Create_Task_byXMLFile $hostname $taskxmlfile
		}		
		Remote-GPUpdate $hostname

	} else {
		Echo-Log "[$hostname] ERROR: Could not connect to $hostname"
	}
}

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "ScheduledTask_VNB"
Echo-Log "Started script $ScriptName"  

# Main

Main_PC 'VS301' 'ZO 04:00'
Main_PC 'VS302' 'ZO 04:00'
Main_PC 'VS303' 'ZO 04:00'
Main_PC 'VS304' 'ZO 04:00'
Main_PC 'VS305' 'ZO 04:00'
Main_PC 'VS306' 'ZO 04:00'
Main_PC 'VS307' 'ZO 04:00'
Main_PC 'VS308' 'ZO 04:00'
Main_PC 'VS309' 'ZO 04:00'
Main_PC 'VS310' 'ZO 04:00'
Main_PC 'VS311' 'ZO 04:00'

# Main_PC 'VS071' 'DO 04:00'
# Main_PC 'VS080' 'DO 04:00'

Echo-Log "End script $ScriptName"