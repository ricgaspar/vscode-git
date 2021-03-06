#------------------------------------------------------------------
# Check W32TM configuration and status
#
# Author: Marcel Jussen
# (27-6-2014)
#
# Revised: 2-6-2015
#
#------------------------------------------------------------------

$VERSION = "2.00a"

$returnStateOK = 0
$returnStateWarning = 1
$returnStateCritical = 2
$returnStateUnknown = 3

#------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
$logpath = "C:\Logboek\NAGIOS_" + $scriptName + ".log"
if(Test-Path $logpath) { Remove-Item $logpath -Force -ErrorAction SilentlyContinue }
Add-Content $logpath "Start script $ScriptName"

#------------------------------------------------------------------
Function OS_Ver {
	$OSVER = (gwmi Win32_OperatingSystem).version	
	$Version = $null
	if($OSVER -ne $null) { $Version = $OSVER.Split(".") }
	return $Version
}

#------------------------------------------------------------------

Function Get_W32TM_Source {	
 	# Windows 2003 servers. Source cannot be checked.	
	$result = $null

    $Version = OS_Ver
	# Windows 2008 or 2012 servers
	if($Version[0] -eq '6') {	
		# Check source NTP server
		$W32tmResult = w32tm /query /source
        Add-Content $logpath "Source query result: $W32tmResult"
		$W32tmResult = $W32tmResult.ToUpper()
	} 
    $Result = $W32tmResult
	return $result
}

Function Check_W32TM_Source {
	Param(    	
    	[string]$SourceServers,
        [string]$W32tmResult
	)		
	$NTPArray = $SourceServers.split(',')	
    $SourceFound = $false
    if($W32tmResult -ne $null) {
		foreach($NTP in $NTPArray) {
			$Server = $NTP.ToUpper()
			if($SourceFound -eq $false) { 
                $SourceFound = $W32tmResult.Contains($Server)                
            }            
            if($SourceFound -eq $True) {
                $result = $Server
            }
		}       
   		$Server = $NTP.ToUpper()
		$Result = $W32tmResult.Contains($Server)                        
	} 
    $result = $SourceFound	
	return $result
}

#------------------------------------------------------------------
Function Rediscover_W32TM_Source {
    Write-Host "Forcing to rediscover NTP source."
	$W32tmResult = w32tm /resync /rediscover
	$W32tmResult = $W32tmResult.ToUpper()
    Add-Content $logpath "Rediscover result: $W32tmResult"
	$Result = $W32tmResult.Contains("COMPLETED SUCCESSFULLY")
	return $result
}

#------------------------------------------------------------------
Function Monitor_W32TM_Source {
	Param(
    	[string]$SourceServers,
		[string]$LatencyMax
	)	

    if($LatencyMax -as [double] -is [double]) { $LatencyMaxDbl = [double]::Parse($LatencyMax)} else { $LatencyMaxDbl = 10 }

 	# Windows 2003 servers. Source cannot be checked.
	$Version = OS_Ver
	if($Version[0] -eq '5') { 
		$W32tmResult = w32tm /monitor /computers:$SourceServers        
	} 

	# Windows 2008 or 2012 servers
	if($Version[0] -eq '6') {	
		# Check source NTP server
		$W32tmResult = w32tm /monitor /nowarn /computers:$SourceServers
	}

    Add-Content $logpath "Monitor result: $W32tmResult"
	
	# Use a regex to search for monitor results
	$Monitor = $W32tmResult -match " NTP: ([+-][0-9]+\.[0-9]+)s"
	
	if($Monitor.Length -ne 0) { 
		$LatencyCheck = $true
	} else {
		$LatencyCheck = $false
	}
	foreach($SourceCheck in $Monitor) {
		$SourceCheck = $SourceCheck.Trim()
        # write-host $SourceCheck
		$SourceArr = $SourceCheck.split(' ')
		
		# Remove unwanted chars in result string
		$LatencyStr = $SourceArr[1].ToUpper()
		
		# If the latency check causes a timeout the result is an empty string.
		# This is a potentially dangerous assumption! If both values are set to 0 there will not be an error reported.
		if($LatencyStr.Length -eq 0) { 
            $LatencyStr = '0'
        }
		
        Add-Content $logpath "Latency result: $LatencyStr"

		$Culture = ((Get-Culture).Name)
		$CI = New-Object System.Globalization.CultureInfo($Culture)
		$DecSep = $CI.NumberFormat.NumberDecimalSeparator

		# Remove unwanted characters from the string.
		$LatencyStr = $LatencyStr.replace('S','')
		$LatencyStr = $LatencyStr.replace('.',$DecSep)
		$LatencyStr = $LatencyStr.SubString(1)		
		
		#Convert result to double		
		if($LatencyStr -as [double] -is [double]) {
			$LatencyDbl = [double]::Parse($LatencyStr)			
		} else {
			# if conversion failed make result huge
			$LatencyDbl = 9999
		}        
		
		# Check if value is within parameters.
		if($LatencyCheck -eq $true) {			
			$LatencyCheck = (($LatencyDbl -ge 0) -and ($LatencyDbl -le $LatencyMaxDbl))
		}
        
        Add-Content $logpath "Conversion result: $LatencyDbl"
	}
	$result = $LatencyCheck
	return $result
}

#------------------------------------------------------------------
# Hard coded crap. 
$SourceServers = 'dc07.nedcar.nl,dc08.nedcar.nl'  # Reference for source checking
$DriftSource = 'ntp1.nedcar.nl'
$LatencyMaxStr = '1'

# Source servers for domain controlers are specific.
if($env:COMPUTERNAME -eq 'DC07') { $SourceServers = "ntp1.nedcar.nl,ntp2.nedcar.nl" }
if($env:COMPUTERNAME -eq 'DC08') { $SourceServers = "dc07.nedcar.nl" }

#------------------------------------------------------------------

$msg = "Checking W32TM NTP sources and time latency. "
Add-Content $logpath $msg

$SourceServers = $SourceServers.ToUpper()
$msg = "Source servers expected: $SourceServers"
Add-Content $logpath $msg

# Check if NTP sources are OK.
Add-Content $logpath "Source check started."
$W32tmResult = Get_W32TM_Source

if($W32tmResult -eq $null) {
    write-host "NTP source: Cannot be determined. This is expected on a W2k3 server."			        
    $SourceCheck = $W32tmResult
} else {
    write-host "NTP source: $W32tmResult"			        
    Add-Content $logpath "NTP source: $W32tmResult"
    $SourceCheck = Check_W32TM_Source $SourceServers $W32tmResult    

    # If NTP source is not OK, force a rediscover and resync
    if($SourceCheck -eq $false) {    
        $msg = "W32TM resync and rediscover was started."
        Add-Content $logpath $msg    

	    $Rediscover = Rediscover_W32TM_Source
	    Add-Content $logpath "Rediscover ended."
	
	    # If rediscovery succeeded, check NTP source again.
	    if($Rediscover -eq $true) {
		    Add-Content $logpath "Second source check started."
		    $SourceCheck = Check_W32TM_Source $SourceServers
		    Add-Content $logpath "Second source check ended."
	    }
    }
    Add-Content $logpath "Source check ended."
}


# Check latency/drift check
Add-Content $logpath "Max. time drift: $LatencyMaxStr seconds."
Add-Content $logpath "Monitor drift check started."
$MonitorCheck = Monitor_W32TM_Source $DriftSource $LatencyMaxStr
Add-Content $logpath "Monitor drift check ended."

#------------------------------------------------------------------
# create output result string
if(($SourceCheck -eq $True) -and ($MonitorCheck -eq $True)) { 
    $msg = "NTP Sources and latency are ok." 
    Write-Host $msg
	Add-Content $logpath $msg
    exit $returnStateOK
}
if(($SourceCheck -eq $False) -and ($MonitorCheck -eq $False)) { 
    $msg = "Critical: NTP source is not correct. Time latency is not within $LatencyMaxStr seconds."
    Write-Host $msg
	Add-Content $logpath $msg
    exit $returnStateCritical
}
if(($SourceCheck -eq $True) -and ($MonitorCheck -eq $False)) { 
    $msg = "Warning: NTP source is correct. Time latency is larger than $LatencyMaxStr seconds."
    Write-Host $msg
	Add-Content $logpath $msg
    exit $returnStateWarning
}
if(($SourceCheck -eq $False) -and ($MonitorCheck -eq $True)) { 
    $msg = "Warning: NTP source is not correct. Time latency is within $LatencyMaxStr seconds." 
    Write-Host $msg
	Add-Content $logpath $msg
    exit $returnStateWarning
}

# If SourceCheck is NULL the system was a Win2K3 server
if(($SourceCheck -eq $null) -and ($MonitorCheck -eq $True)) {
    $msg = "Ok: NTP source is unknown on a W2k3 server. Time latency is within $LatencyMaxStr seconds." 
    Write-Host $msg
	Add-Content $logpath $msg

    # We assume status Ok
    exit $returnStateOk
}
if(($SourceCheck -eq $null) -and ($MonitorCheck -eq $False)) { 
    $msg = "Warning: NTP source is unknown on a W2k3 server. Time latency is larger than $LatencyMaxStr seconds."
    Write-Host $msg
	Add-Content $logpath $msg
    exit $returnStateCritical
}

#------------------------------------------------------------------
Add-Content $logpath "End script $ScriptName"
exit $returnStateOK
