# =========================================================
#
# Delete distinct WUAU client registry entries and 
# restart WUAU service if needed.
#
# Marcel Jussen
# 19-5-2014
#
# =========================================================
clear
# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libServices.ps1

# ------------------------------------------------------------------------------

$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-TSM_Update"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$SystemNameList = "VS003"

# These are the WUAU value names we do not want.
$UnwantedKeys = @()
$UnwantedKeys += "AUOptions"
$UnwantedKeys += "ResetAU"
$UnwantedKeys += "BehindAuthProxy"
$UnwantedKeys += "ScheduledInstallDate"
$UnwantedKeys += "ForcedReboot"

Function Get-RegKeyValueNames {
	param (
		[string]$ComputerName = 'localhost',
		[string]$Key = $null
	)	
	if([string]::IsNullOrEmpty($ComputerName)) { return $null }	
	if([string]::IsNullOrEmpty($Key)) { return $null }
	$retval = $null		
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ComputerName)	
	$regkey = $reg.OpenSubKey($Key) 
	$RetVal = $regkey.GetValueNames()		
	Return $Retval
}

Function Exist-RegValue {
	param (
		[string]$ComputerName = 'localhost',
		[string]$Key = $null,
		[string]$Value = $null
	)	
	if([string]::IsNullOrEmpty($ComputerName)) { return $null }	
	if([string]::IsNullOrEmpty($Key)) { return $null }
	if([string]::IsNullOrEmpty($Value)) { return $null }
	$retval = $null	
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ComputerName)	
	$regkey = $reg.OpenSubKey($Key) 
	$KeyVals = $regkey.GetValueNames()
	$retval = $KeyVals -contains $Value
	Return $Retval
}

Function Delete-RegValue {
	param (
		[string]$ComputerName = 'localhost',
		[string]$Key = $null,
		[string]$Value = $null
	)
	if([string]::IsNullOrEmpty($ComputerName)) { return $null }	
	if([string]::IsNullOrEmpty($Key)) { return $null }
	if([string]::IsNullOrEmpty($Value)) { return $null }
	
	if(  Exist-RegValue $ComputerName $Key $Value) {
		$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ComputerName)
		# Open key with read/write permission
		$regkey = $reg.OpenSubKey($Key, $True) 
		[Void]$regkey.DeleteValue($Value)	
	}
}

$Key = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update"

$colResults = collectAD_Servers
$total = $colResults.Count
foreach ($objResult in $colResults) {
	$syscount++
	$objItem = $objResult.Properties
	$Systemname = [string]$objItem.name
	Echo-Log "[$Systemname]"

	If (Test-Connection -ComputerName $SystemName -Count 1 -Quiet) {	
		$OSInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $SystemName
  		foreach($os in $OSInfo) {
    		$Caption = $os.Caption    		
    		$OSVersion = $os.Version    	    
  		}		
		$ProcInfo = Get-WmiObject -Class Win32_Processor -ComputerName $SystemName
  		foreach ($proc in $ProcInfo) { $Arch = $proc.AddressWidth }				
		Echo-Log "[$SystemName] $Caption ($Arch bit)"	
		
		$WUAUInfo = Get-RegKeyValueNames -ComputerName $SystemName -Key $Key
		
		$valdeleted = $false
		foreach($wukey in $WUAUInfo) {
			$found = $false
			foreach($Unwanted in $UnwantedKeys) {
				if($found -eq $false) {
					$found = $wukey -contains $Unwanted
				}
			}
			if($found) {
				Echo-Log "[$SystemName] $wukey key was found."				
				Delete-RegValue -ComputerName $SystemName -Key $Key -Value $wukey
				$ValExists = Exist-RegValue -ComputerName $SystemName -Key $Key -Value $wukey
				if($ValExists -ne $true) {
					Echo-Log "[$SystemName] $wukey key was successfully deleted."
					$valdeleted = $true
				} else {
					Echo-Log "[$SystemName] ERROR: $wukey key was not successfully deleted."
				}
			}
		}
		
		if($valdeleted) {
			$ServiceName = 'WUAUSERV'
			$Stopped = Remote-StopService $SystemName $ServiceName
			if($Stopped) {
				Echo-Log "[$SystemName] Service $ServiceName has stopped."
				$Started = Remote-StartService $SystemName $ServiceName
				if($Started) {
					Echo-Log "[$SystemName] Service $ServiceName is started."
				} else {				
					Echo-Log "[$SystemName] ERROR: Service $ServiceName could not be started."
				}
			} else {				
				Echo-Log "[$SystemName] ERROR: Service $ServiceName could not be stopped."
			}
		} else {
			Echo-Log "[$SystemName] No unwanted registry keys have been found."
		}
	} else {
		Echo-Log "ERROR: $SystemName cannot be contacted."		
	}
}

# ------------------------------------------------------------------------------
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)