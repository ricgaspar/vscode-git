# ---------------------------------------------------------
#
# Marcel Jussen
# 17-09-2012
#
# ---------------------------------------------------------
cls

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1
. C:\Scripts\Secdump\PS\libSchtasks.ps1

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName $ScriptName
Echo-Log "Started script $ScriptName"  

$TaskName = "STD-SysInfo"

$ServerList = collectAD_Servers
Foreach ($server in $serverlist)
{
	$ServerName = $server.Properties.name
	if(IsComputerAlive $ServerName) {
		Echo-Log "Retrieve scheduled tasks list on server $ServerName"  	
		$tasklist = Get-ScheduledTask -ComputerName $ServerName 
		$JobFound = $false
		foreach($task in $tasklist) {
			if($task -ne $null) {
				if($task.contains($TaskName)) {
					$JobFound = $True
				}
			}
		}
		if($JobFound -eq $true) { 
			Echo-Log "Starting script '$TaskName' on server $ServerName"  	
			Run-ScheduledTask -ComputerName $ServerName -TaskName $TaskName
		} else {
			Echo-Log "Task '$TaskName' on server $ServerName was not found."  	
		}
	} else {
		Echo-Log "Server $ServerName cannot be contacted."  	
	}
}
Echo-Log "End script $ScriptName"