# =========================================================
#
# Marcel Jussen
# 16-05-2014
#
# =========================================================

Function Append-Log {
	param (	
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$Message
	)
	Process {
		if($Message) {
			Write-host $message
			Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
		}
	}
}

Function Create-ScheduledTask-ByXML { 
	param (
		[string]$Computername = $env:COMPUTERNAME,
		[Parameter(Mandatory=$True)][ValidateNotNull()] [string]$Taskname,
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$TaskXMLfile,
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$RunAsUsername, 
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$RunAsPassword
	)	
	Process {
		Try {
			[Void](schtasks /S $Computername /Create /TN "$Taskname" /XML "$TaskXMLfile" /RU "$RunAsUsername" /RP "$RunAsPassword" /F)
		}
		Catch [system.exception] {
			
  			"caught a system exception"
		}
	}
}

Function Exists-ScheduledTask {
	param (		
		[string]$Computername = $env:COMPUTERNAME, 
		[Parameter(Mandatory=$True)][ValidateNotNull()] [string]$Taskname		
	)	
	Process {
		$sch = New-Object -ComObject("Schedule.Service")		
		$sch.connect($Computername)
		$tasks = $sch.getfolder("\").gettasks(0)
		foreach ($task in $tasks) {
			if($task.Name -match $Taskname) { return $true }
		}
		return $false
	}
}

Function Delete-ScheduledTask {
	param (
		[string]$Computername = $env:COMPUTERNAME,
		[Parameter(Mandatory=$True)][ValidateNotNull()] [string]$Taskname
	)	
	Process {
		if( Exists-ScheduledTask -Computername $Computername -Taskname $Taskname ) {
			$result = schtasks /Delete /S $Computername /TN "$Taskname" /F			
			if( (Exists-ScheduledTask -Computername $Computername -Taskname $Taskname ) -eq $false) { return $true }						
		}
	}
}

Function Renew-ScheduledTask-ByXML {
	param (
		[string]$Computername = $env:COMPUTERNAME,
		[Parameter(Mandatory=$True)][ValidateNotNull()] [string]$Taskname,
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$TaskXMLfile,
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$RunAsUsername, 
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$RunAsPassword
	)
	
	Process {
		Delete-ScheduledTask -Computername $Computername -Taskname $Taskname
		Create-ScheduledTask-ByXML -Computername $Computername `
			-TaskXMLfile $TaskXMLFile -Taskname $Taskname `
			-RunAsUsername $RunAsUsername -RunAsPassword $RunAsPassword 
	}
}

Function Copy-ScheduleTask {
	param (
		[string]$Computername = $env:COMPUTERNAME,
		[Parameter(Mandatory=$True)][ValidateNotNull()] [string]$Taskname, 
		[Parameter(Mandatory=$True)][ValidateNotNull()] [string]$newtaskname,
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$RunAsUsername, 
		[Parameter(Mandatory=$True)][ValidateNotNull()]	[string]$RunAsPassword
	)	
	
	Process {		
		if( Exists-ScheduledTask -Computername $Computername -Taskname $Taskname ) {
			if( (Exists-ScheduledTask -Computername $Computername -Taskname $newtaskname) -eq $false ) {
				# Read task parameters 
				$taskxml = schtasks /query /S $Computername /TN $Taskname /XML								
				# Create new task with old params
				Create-ScheduledTask-ByXML -Computername $Computername -Taskname $newtaskname -TaskXMLfile $taskxml -RunAsUsername $RunAsUsername -RunAsPassword $RunAsPassword
				if( Exists-ScheduledTask -Computername $Computername -Taskname $newtaskname ) { return $true } 							
			} 
		} 		
	} 	
}

Function Set-LSA-DisableDomainCreds {
	param (
		[string]$Computername = $env:COMPUTERNAME,
		[Parameter(Mandatory=$True)][ValidateNotNull()] $Value
	)
	Process {
		$LSAKEY = 'SYSTEM\CurrentControlSet\Control\Lsa'
		$LSAVal = 'disabledomaincreds'
		
		$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computername)				
		$Key = [regex]::Escape($LSASubKey)		
		
		# Open key for writing
		$RegKey= $Reg.OpenSubKey($Key, $True)
		Append-Log "Setting LSA registry parameter $LSAVal to $Value"
		$RegKey.SetValue($LSAVal, $Value, [Microsoft.Win32.RegistryValueKind]::DWORD)
	}
}

Function Reset-LSA-DisableDomainCreds {
	Param (
		[string]$Computername = $env:COMPUTERNAME
	)
	Process {				
		$LSASubKey = 'SYSTEM\CurrentControlSet\Control\Lsa'
		$LSAVal = 'disabledomaincreds'
		
		$Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computername)				
		$Key = [regex]::Escape($LSASubKey)		
		$RegKey= $Reg.OpenSubKey($Key)
		$Value = $RegKey.GetValue($LSAVal)
		
		if($value -ne 0) { 	Set-LSA-DisableDomainCreds -Computername $Computername -Value 0	}
		return $value
	}
}

cls

# Init log file
$SCRIPTLOGPath = $env:SystemRoot + "\Patchlog"
if(![System.IO.Directory]::Exists($SCRIPTLOGPath)) { [System.IO.Directory]::CreateDirectory($SCRIPTLOGPath) }
$SCRIPTLOG = $SCRIPTLOGPath + '\configure-ScheduledTasks.log'
if([System.IO.File]::Exists($SCRIPTLOG)) { Remove-Item -Path $SCRIPTLOG -Force -ErrorAction SilentlyContinue } 

$ScriptPath = $myInvocation.MyCommand.Path
$ScriptFolder = Split-Path $ScriptPath -Parent
$TasksSourcePath = $ScriptFolder

$RunAsUsername = 'NEDCAR\BSPScheduler'
$RunAsPassword = 'scheduler'

# Use local computer to update scheduled tasks
$Computername = $Env:COMPUTERNAME

Append-Log "Maintain scheduled tasks on $Computername"

# Make sure we can save credentials in a scheduled task by checking LSA
$LSAValue = Reset-LSA-DisableDomainCreds -Computername $Computername

# Delete unwanted scheduled tasks
Delete-ScheduledTask -Computername $Computername -Taskname 'STD-Cleanup'
Delete-ScheduledTask -Computername $Computername -Taskname 'UDI_Cleanup'
Delete-ScheduledTask -Computername $Computername -Taskname 'UDI_Regcleanup'
 
Delete-ScheduledTask -Computername $Computername -Taskname 'Spatz_Prelaunch_Checker'

Delete-ScheduledTask -Computername $Computername -Taskname 'CreateChoiceProcessTask'
Delete-ScheduledTask -Computername $Computername -Taskname 'Adobe Flash Player Updater'
Delete-ScheduledTask -Computername $Computername -Taskname 'GoogleUpdateTaskMachineCore'
Delete-ScheduledTask -Computername $Computername -Taskname 'GoogleUpdateTaskMachineUA'

# Search location of script for XML task definitions
$XMLTasks = Get-ChildItem $TasksSourcePath -force -Filter "*.xml"
if($XMLTasks -ne $null) {
	ForEach($task in $XMLTasks) {	
		# Create task name from XML file name
		$Taskname = [System.IO.Path]::GetFileNameWithoutExtension($task.name)
		$taskxmlfile = $task.FullName
		
		$TaskExists = Exists-ScheduledTask -Computername $Computername -Taskname $Taskname
		if ($TaskExists) {
			$t = Renew-ScheduledTask-ByXML -Computername $Computername `
				-TaskXMLfile $taskxmlfile -Taskname $Taskname `
				-RunAsUsername $RunAsUsername -RunAsPassword $RunAsPassword
		} else {							
			$t = Create-ScheduledTask-ByXML -Computername $Computername `
				-TaskXMLfile $taskxmlfile -Taskname $Taskname `
				-RunAsUsername $RunAsUsername -RunAsPassword $RunAsPassword 
		}
	}	
}

# Write back save LSA subkey value
if($LSAValue) { Set-LSA-DisableDomainCreds -Computername $Computername $LSAVAlue }