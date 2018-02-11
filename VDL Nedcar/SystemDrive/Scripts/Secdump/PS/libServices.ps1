# ---------------------------------------------------------
#
# (remote) Services Functions (usefull for old OS)
# Marcel Jussen
# 26-07-2012
#
# ---------------------------------------------------------

Function Remote-StopService {
	param (
		[string]$FQDN = "localhost",
		[string]$ServiceName
  	)
	[void][System.Reflection.Assembly]::LoadWithPartialName('System.ServiceProcess')
	$Wuauserv=new-Object System.ServiceProcess.ServiceController($ServiceName, $FQDN)
	$Stopped=$true
	if($wuauserv.Status -ne "Stopped" ) {
		try {
        	$Wuauserv.Stop()
			$wuauserv.WaitForStatus('Stopped',(new-timespan -seconds 10))
    	}
		catch {
			$Stopped=$false
		}
	}
	return $Stopped
}

Function Remote-StartService {
	param (
		[string]$FQDN = "localhost",
		[string]$ServiceName
  	)
	[void][System.Reflection.Assembly]::LoadWithPartialName('System.ServiceProcess')
	$Wuauserv=new-Object System.ServiceProcess.ServiceController($ServiceName, $FQDN)
	$Started=$true
	if($wuauserv.Status -ne "Running" ) {
		try {
        	$Wuauserv.Start()
			$wuauserv.WaitForStatus('Running',(new-timespan -seconds 10))
    	}
		catch {
			$Started=$false
		}
	}
	return $Started
}