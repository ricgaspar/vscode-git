# =========================================================
#
# Execute a remote install/update of the TSM client software
#
# Marcel Jussen
# 15-11-2012
#
# =========================================================

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libReg.ps1
. C:\Scripts\Secdump\PS\libServices.ps1

Function Get-ApplicationInfo {
	param (
		[string]$ComputerName = 'localhost',
		[string]$SearchDisplayName
	)
	
	if ($SearchDisplayName -eq $null) {return $null}
	if ($SearchDisplayName.length -le 0) {return $null}
	
	$retval = $null	
	$UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ComputerName)
	$regkey = $reg.OpenSubKey($UninstallKey) 
	$subkeys = $regkey.GetSubKeyNames()	
	foreach($key in $subkeys){
      	$thisKey=$UninstallKey+"\\"+$key 
		$thisSubKey=$reg.OpenSubKey($thisKey) 
       	$DisplayName = $thisSubKey.GetValue("DisplayName")
		if($DisplayName -ne $null) {
			if($DisplayName.contains($SearchDisplayName)) {
				$retval = @{}
				$retval.Add("Publisher", $thisSubKey.GetValue("Publisher"))
				$retval.Add("DisplayVersion", $thisSubKey.GetValue("DisplayVersion"))
				$retval.Add("DisplayName", $DisplayName)
				$retval.Add("InstallDate", $thisSubKey.GetValue("InstallDate"))
				$retval.Add("InstallLocation", $thisSubKey.GetValue("InstallLocation"))
				$retval.Add("UninstallString", $thisSubKey.GetValue("UninstallString"))
				$retval.Add("Version", $thisSubKey.GetValue("Version"))
				$retval.Add("VersionMajor", $thisSubKey.GetValue("VersionMajor"))
				$retval.Add("VersionMinor", $thisSubKey.GetValue("VersionMinor"))			
			}
		}
	}
	Return $Retval
}

Function Get-ApplicationInfoWOW {
	param (
		[string]$ComputerName = 'localhost',
		[string]$SearchDisplayName
	)
	
	if ($SearchDisplayName -eq $null) {return $null}
	if ($SearchDisplayName.length -le 0) {return $null}
	
	$retval = $null	
	$UninstallKey = "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ComputerName)
	$regkey = $reg.OpenSubKey($UninstallKey) 
	$subkeys = $regkey.GetSubKeyNames()	
	foreach($key in $subkeys){
      	$thisKey=$UninstallKey+"\\"+$key 
		$thisSubKey=$reg.OpenSubKey($thisKey) 
       	$DisplayName = $thisSubKey.GetValue("DisplayName")	
		if($DisplayName -ne $null) {
			if($DisplayName.contains($SearchDisplayName)) {
				$retval = @{}
				$retval.Add("Publisher", $thisSubKey.GetValue("Publisher"))
				$retval.Add("DisplayVersion", $thisSubKey.GetValue("DisplayVersion"))
				$retval.Add("DisplayName", $DisplayName)
				$retval.Add("InstallDate", $thisSubKey.GetValue("InstallDate"))
				$retval.Add("InstallLocation", $thisSubKey.GetValue("InstallLocation"))
				$retval.Add("UninstallString", $thisSubKey.GetValue("UninstallString"))
				$retval.Add("Version", $thisSubKey.GetValue("Version"))
				$retval.Add("VersionMajor", $thisSubKey.GetValue("VersionMajor"))
				$retval.Add("VersionMinor", $thisSubKey.GetValue("VersionMinor"))			
			}
		}
	}
	Return $Retval
}

cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-WinZip-Update"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$mycredentials = Get-Credential -Credential nedcar\Adm1

# $SystemList = Get-Content -Path C:\Scripts\Powershell\TSM\systems.ini
$SystemList = "NC032"

foreach($System in $SystemList) {		
	If (Test-Connection -ComputerName $System -Count 1 -Quiet) {	
		$OSInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $System
  		foreach($os in $OSInfo) {
    		$Caption = $os.Caption    		
    		$OSVersion = $os.Version    	    
  		}		
		$ProcInfo = Get-WmiObject -Class Win32_Processor -ComputerName $System
  		foreach ($proc in $ProcInfo) { $Arch = $proc.AddressWidth }				
		Echo-Log "$System $OSVersion $Caption ($Arch bit)"						
		
		# Search for WinZip 9.0
		if($Arch -eq 32) { $WinZipAppInfo = Get-ApplicationInfo -ComputerName $System "WinZip" }
		if($Arch -eq 64) { $WinZipAppInfo = Get-ApplicationInfoWOW -ComputerName $System "WinZip" }
		$WinZip9 = $False
		if($WinZipAppInfo -ne $null) { 			
			$WinZipVer = $WinZipAppInfo.Get_Item("DisplayVersion")
			$WinZipDispl = $WinZipAppInfo.Get_Item("DisplayName")
			$WinZipPath = $WinZipAppInfo.Get_Item("InstallLocation")
			
			# Check for Winzip 9.0
			if( ($WinZipVer -ne $null) -and ($WinZipVer.Contains("9.0")) ) { 				
				Echo-Log "  WinZip version:      $WinZipVer"				
				Echo-Log "  Installed at:        $WinZipPath"	
				$WinZip9 = $True
			}
			
			# Check for WinZip Command Line
			if( ($WinZipDispl -ne $null) -and ($WinZipDispl.Contains("Command Line Support Add-On 1.1 SR-1")) ) { 				
				Echo-Log "  $WinZipDispl was found"				
				$WinZip9 = $True
			}
						
			if($WinZip9) {			
				Echo-Log "  Starting upgrade to WinZip 16.5 on $System"
				
				# Create temporary folder with installation source
				$TempFldr = $false
				if ((Test-Path -path "\\$System\C$\Temp\") -eq $false) { 
					$x = New-Item \\$System\C$\Temp -type directory -ErrorAction SilentlyContinue
					$TempFldr = $true
				}
				if ((Test-Path -path "\\$System\C$\Temp\Winzip16" ) -eq $false) { 
					$x = New-Item \\$System\C$\Temp\Winzip16 -type directory -ErrorAction SilentlyContinue
				}
				Copy-Item "\\S001\standaard\Scripts\WinZip16\*.*" "\\$System\C$\Temp\WinZip16"
				
				# Start install script with PS remoting session
				$wsman = new-pssession -computername $System -Credential $mycredentials
				$output = invoke-command -session $wsman -scriptblock {				
					C:\TEMP\WinZip16\install-local.cmd
				}									
				remove-pssession -session $wsman
				
				# Cleanup
				Remove-Item "\\$System\C$\Temp\Winzip16" -Recurse -Force -ErrorAction SilentlyContinue
				if($TempFldr) {Remove-Item "\\$System\C$\Temp" -Recurse -Force -ErrorAction SilentlyContinue}
			} else {
				Echo-Log "  No upgrade to WinZip 16.5 on $System"
			}
			
		} else {
			Echo-Log "No WinZip software was found on $System"
		}
		
		# Show Winzip version information
		$WinZipAppInfo = Get-ApplicationInfo -ComputerName $System "WinZip" 		
		if($WinZipAppInfo -ne $null) {
			$WinZipVer = $WinZipAppInfo.Get_Item("DisplayVersion")
			Echo-Log "  WinZip version:      $WinZipVer"
			$WinZipPath = $WinZipAppInfo.Get_Item("InstallLocation")
			Echo-Log "  Installed at:        $WinZipPath"				
		} else {
			Echo-Log "No WinZip software was found on $System"
		}
        
	} else {
		Echo-Log "$System cannot be contacted."		
	}
}

# ------------------------------------------------------------------------------
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)