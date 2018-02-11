# ---------------------------------------------------------
#
# Marcel Jussen
# 17-09-2012
#
# ---------------------------------------------------------
cls

Import-Module VNB_PSLib -Force -ErrorAction Stop

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName $ScriptName
Echo-Log "Started script $ScriptName"  

$TaskName = "VNB-System configuration info"

$ServerList = Get-ADServers
Foreach ($server in $serverlist)
{
	$ServerName = $server.Properties.name
    write-host $Servername
	if(IsComputerAlive $ServerName) {
		schtasks /RUN /S $servername /TN "$TaskName"
	} else {
		Echo-Log "Server $ServerName cannot be contacted."  	
	}
}
Echo-Log "End script $ScriptName"