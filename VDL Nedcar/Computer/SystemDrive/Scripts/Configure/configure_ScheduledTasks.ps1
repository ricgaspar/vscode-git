# =========================================================
#
# Marcel Jussen
# 29-03-2016
#
# =========================================================
param (
	[string]$NCSTD_VERSION = '6.0.0.0'
)

# ---------------------------------------------------------
# Pre-defined variables

$Global:SERVER_AGE_DAYS = 7

# ---------------------------------------------------------
Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

function CheckComputerConnectivity($computer) {
	$bPing = $false
	$bShare = $false
	$result = $false
	#Firstly check if the computer can be pinged.
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
		$task_user = 'SYSTEM', 
		$task_pass = ''
	)	
	$result = schtasks /Create /TN "$task_name" /XML "$xml" /RU "$task_user" /RP "$task_pass"
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
				Append-Log "Successfully deleted task $taskname"
				return $true 
			} else {
				Append-Log "ERROR: Failed to delete task $taskname"
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
					Append-Log "Succesfully copied task $taskname to $newtaskname"
					return $true 
				} else {
					Append-Log "ERROR: Failed to copy task $taskname to $newtaskname"
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
		$task_user = 'SYSTEM', 
		$task_pass = ''
	)	
	$res = Copy_Task $hostname $taskname $newtaskname $task_user $task_pass
	if( $res ) {
		if( Delete_Task $hostname $taskname	) {	
			Append-Log "Successfully renamed task $taskname to $newtaskname"
			return $true 
		} else {
			Append-Log "ERROR: Failed to rename task $taskname to $newtaskname"
		}
	} 
	
	return $false
}

Function Rename_Task_Batch {
	param (
		$hostname
	)
	
	# Old names
	$tasklist = @()
	$tasklist += "STD-Cleanup"
	$tasklist += "STD-SysInfo"
	$tasklist += "STD-Configure"
	$tasklist += "STD-System-Reboot"
	$tasklist += "STD-DumpNTFSv3"
	$tasklist += "Wekelijkse Reboot"
	$tasklist += "Auto reboot"
	$tasklist += "Automatische reboot"
	
	# New names
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
	
	# Forced removal of old tasks
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

Function Create_Task_byXMLFile {
	param (
		$hostname,
		$xmlpath,
		$taskname,
		$taskuser,
		$taskpass
	)
	
	$taskuser = 'SYSTEM'
	$taskpass = ''		
	
	Append-Log "Remove previous task $taskname"
	$result = Delete_Task $hostname $taskname	
	
	Append-Log "Creating task $taskname"
	Create_Task_XML $hostname $taskname $xmlpath $taskuser $taskpass				
	if (Exists_Task $hostname $taskname) {
		Append-Log "Successfully created task $taskname"
	} else {
		Append-Log "ERROR: failed to create task $taskname"
	}
}

Function MaintainTasks {
	param (
		$hostname		
	)
	
	if(CheckComputerConnectivity($hostname)) {				
		Append-Log "Successfully connected to $hostname"
		
		Append-Log "Deleting unused tasks on $hostname"
		$result = Delete_Task_Batch $hostname
		Append-Log "Deleting unused tasks on $hostname is done."		
		
		Append-Log "Renaming tasks on $hostname"
		Rename_Task_Batch $hostname 	
		Append-Log "Renaming tasks on $hostname is done."		

	} else {
		Append-Log "ERROR: Could not connect to $hostname"
	}
}

Function Validate_OS {
	param (
		$OSMajor,
		$OSMinor,
		$OSSubminor
	)
	$result = $false
	
	$os = Get-WmiObject -class Win32_OperatingSystem 
	$version = $os.Version
	Append-Log "OS Version: $version"
	$osarr = $version.split(".")	
	$ver_major = [int]$osarr[0]
	$ver_minor = [int]$osarr[1]
	$ver_subminor = [int]$osarr[2]
	
	if(($ver_major -ge $OSMajor) -and ($ver_minor -ge $OSMinor) -and ($ver_subminor -ge $OSSubminor)) {
		$result = $true
	}	
	
	return $result
}

# ------------------------------------------------------------------------------
Write-Host "Started NCSTD Configure $NCSTD_VERSION"

# Make sure to run this script from the config folder or else no scheduled tasks are created.
set-location 'C:\Scripts\Config'

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-ScheduledTasks-$NCSTD_VERSION.log"
if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {

    #
    # Check LSA for credentials issue
    #
    Append-Log "Checking LSA registry parameter."
    $RegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    $lsaval = Get-ItemProperty -Path $RegPath -Name "disabledomaincreds"
    if($lsaval.disabledomaincreds -ne 0) {
	    Append-Log "LSA DisableDomaincreds is not zero. Value is now set to zero."
	    # Enforce values if exists
	    Set-ItemProperty -Path $RegPath -Name disabledomaincreds -Value 0 -ErrorAction SilentlyContinue		
    } else {
        Append-Log "LSA DisableDomainCreds is zero. We can create tasks."
    }

	# Rename tasks to new name format
	# Delete unused tasks.
	MaintainTasks $Env:COMPUTERNAME

	# Replace tasks from folder TASKS 
	$TasksSourcePath = ".\ScheduledTasks\Tasks"
	$XMLTasks = Get-ChildItem $TasksSourcePath -force -Filter "*.xml"
	if($XMLTasks -ne $null) {
		ForEach($task in $XMLTasks) {
			$taskname = [System.IO.Path]::GetFileNameWithoutExtension($task)
			$taskxmlfile = $TasksSourcePath + '\' + $task		

			# Make sure we do NOT create the reboot task by accident
			if($taskname -ne 'VNB-Weekly reboot task') {				
				Append-Log "Create task from XML file $taskxmlfile $taskname"
				Create_Task_byXMLFile $Env:COMPUTERNAME $taskxmlfile $taskname
			} else {				
				if (Exists_Task $Env:COMPUTERNAME $taskname) {
					Append-Log "Task $taskname already exists. Skipping task."					
				} else {				
					Append-Log "Checking if this is system is freshly installed."
					# Determine the installation date.
					$InstallDateStr = (Get-WmiObject -Class Win32_OperatingSystem).InstallDate
					$InstallDateStr = $InstallDateStr.Substring(0,8) 
					$InstallDate = [datetime]::ParseExact($InstallDateStr, "yyyyMMdd", $null)
					
					# Calculate the age in days
					$date = Get-Date
					$diffdatedays = [int](New-Timespan $InstallDate $Date).days
					Append-Log "System install date: $InstallDate"
					Append-Log "Difference: $diffdatedays"
					
					# Configure the reboot task only if the system is not older than 7 days
					if($diffdatedays -le $Global:SERVER_AGE_DAYS) {						
						Create_Task_byXMLFile $Env:COMPUTERNAME $taskxmlfile $taskname
					} else {
						Append-Log "System is too old to configure Reboot scheduled task."
					}
				}
			}
		}
	}	
	
	# Replace tasks from folder REBOOT
	$TasksSourcePath = ".\ScheduledTasks\Reboot"
	$XMLTasks = Get-ChildItem $TasksSourcePath -force -Filter "*.xml"
	if($XMLTasks -ne $null) {
		ForEach($task in $XMLTasks) {
			$taskname = [System.IO.Path]::GetFileNameWithoutExtension($task)
			$taskxmlfile = $TasksSourcePath + '\' + $task		
			# Make sure we do NOT create the reboot task by accident
			if($taskname -ne 'VNB-Weekly reboot task') {				
				Create_Task_byXMLFile $Env:COMPUTERNAME $taskxmlfile $taskname
			} else {				
				if (Exists_Task $Env:COMPUTERNAME $taskname) {
					Append-Log "Task $taskname already exists. Skipping task."					
				} else {				
					Append-Log "Checking if this is system is freshly installed."
					# Determine the installation date.
					$InstallDateStr = (Get-WmiObject -Class Win32_OperatingSystem).InstallDate
					$InstallDateStr = $InstallDateStr.Substring(0,8) 
					$InstallDate = [datetime]::ParseExact($InstallDateStr, "yyyyMMdd", $null)
					
					# Calculate the age in days
					$date = Get-Date
					$diffdatedays = [int](New-Timespan $InstallDate $Date).days
					Append-Log "System install date: $InstallDate"
					Append-Log "Difference: $diffdatedays"
					
					# Configure the reboot task only if the system is not older than 7 days
					if($diffdatedays -le $Global:SERVER_AGE_DAYS) {						
						Create_Task_byXMLFile $Env:COMPUTERNAME $taskxmlfile $taskname
					} else {
						Append-Log "System is too old to configure Reboot scheduled task."
					}
				}
			}
		}
	}

    if($lsaval.disabledomaincreds -ne 0) {
        Append-Log "Setting LSA disabledomaincreds to previous value."
        Set-ItemProperty -Path $RegPath -Name disabledomaincreds -Value $lsaval.disabledomaincreds -ErrorAction SilentlyContinue		
    }

	Append-Log "End script $ScriptName"
}

