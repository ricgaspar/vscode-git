# =========================================================
#
# Force a remote GPUpdate on a computer still not transitioned to VS024
#
# Marcel Jussen
# 11-10-2012
#
# =========================================================

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libReg.ps1
. C:\Scripts\Secdump\PS\libServices.ps1
. C:\Scripts\Secdump\PS\libWUAU.ps1

Function Change-UpdateServer { 
	param (
		[string]$FQDN,
		[string]$New_WUServer = "http://vs024.nedcar.nl",
		[string]$TargetGroup = "DESKTOPS;DESKTOP-PROD"
  	)
	$settings = Get-ClientWSUSSetting -Computername $FQDN
	$WUServer = $settings.WUServer
	if($WUServer.contains("vs053") -eq $true) {
		Write-Host "$FQDN points to $WUServer"	
		$result = Set-ClientWSUSSetting -Computername $FQDN -UpdateServer $New_WUServer -TargetGroup $TargetGroup
		$settings = Get-ClientWSUSSetting -Computername $FQDN
		$WUServer = $settings.WUServer
		if($WUServer.contains("vs053") -eq $true) {
			Write-Host "ERROR: $FQDN still points to $WUServer"	
		} else {
			Write-Host "$FQDN is now $NEW_WUServer"
		}
	} else {
		Write-Host "$FQDN is $NEW_WUServer. No change needed."	
	}
}

Function Remote-ExecCmd {
	param (
		[string]$FQDN,	
		[string]$Command
  	)
	Write-Host "Executing remote command: $command"
	$RemoteProcess=([wmiclass]"\\$FQDN\root\cimv2:Win32_Process").create($Command)
}

Function Remote-ResetWUAU {
	param (
		[string]$FQDN		
  	)
	
	Write-Host "$FQDN Stopping wuauserv"
	$Stopped = Remote-StopService $FQDN "wuauserv" 
	if ($Stopped) {		
		$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $FQDN)
    	$regKey= $reg.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate", $true)
    	$regKey.DeleteValue("SusClientId")
    	$regKey.DeleteValue("SusClientIdValidation")
    	# $regKey.DeleteValue("PingID")
    	# $regKey.DeleteValue("AccountDomainSid")
		
		$Started = Remote-StartService $FQDN "wuauserv" 
		Write-Host "$FQDN Starting wuauserv"
		if ($Started) {		
			Start-Sleep -Seconds 5
			Write-Host "$FQDN Update Group Policy."
			Remote-ExecCmd $FQDN "cmd /c gpupdate /force"		
		
			Start-Sleep -Seconds 30
			Write-Host "$FQDN Initialize Windows Update client."
			Remote-ExecCmd $FQDN "cmd /c wuauclt /resetauthorization /detectnow"				
		} 
	} else { 
		Write-Host "$FQDN ERROR: wuauserv did not stop within timeframe of 10 seconds."
	} 
	
}

Function Remote-DisableWUAU {
	param (
		[string]$FQDN		
  	)
	$Stopped = Remote-StopService $FQDN "wuauserv" 	
	$res = Set-RegDWord -server $FQDN -hive "LocalMachine" -keyname "SYSTEM\CurrentControlSet\Services\wuauserv" -valuename "Start" -Value "4"	
}

cls

[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer("vs053.nedcar.nl",$False)
$targets = $wsus.SearchComputerTargets("B")
foreach($computer in $targets) {
	$OSVersion = $computer.OSDescription
	$FQDN = $computer.FullDomainName	
		
	if ( IsComputerAlive($FQDN) ) {
		if($OSVersion.contains("XP") -eq $true) {
			Write-Host "$FQDN is a Windows XP client."
			$res = Change-UpdateServer $FQDN
			$res = Remote-ResetWUAU $FQDN
			Write-Host "$FQDN Delete host from VS053."
			$client = $wsus.SearchComputerTargets($FQDN)
			$client[0].Delete()
		} 
		if($OSVersion.contains("2000 Professional") -eq $true) {
			Write-Host "$FQDN is a Windows 2000 Pro client."
			$res = Remote-DisableWUAU $FQDN
			Write-Host "$FQDN Delete host from VS053."
			$client = $wsus.SearchComputerTargets($FQDN)
			$client[0].Delete()
		} 
	} else {
			Write-Host "$FQDN is not alive. No response to ping command."
	}			
}

