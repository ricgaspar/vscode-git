# =========================================================
#
# Execute a remote install/update of the TSM client software
#
# Marcel Jussen
# 29-01-2018
#
# =========================================================

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libReg.ps1
. C:\Scripts\Secdump\PS\libServices.ps1

$Global:TSM_SOURCE_SHARE = '\\s031.nedcar.nl\IBMSP'
Function Get-TSMClientInfo {
	param (
		[string]$ComputerName = 'localhost'
	)

	$retval = $null

	$UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$ComputerName)
	$regkey = $reg.OpenSubKey($UninstallKey)
	$subkeys = $regkey.GetSubKeyNames()
	foreach($key in $subkeys){
      	$thisKey=$UninstallKey+"\\"+$key
		$thisSubKey=$reg.OpenSubKey($thisKey)
       	$DisplayName = $thisSubKey.GetValue("DisplayName")
		$DisplayVersion = $thisSubKey.GetValue("DisplayVersion")
		$Publisher = $thisSubKey.GetValue("Publisher")
		if(($Publisher -eq "IBM") -and ($DisplayName -eq "IBM Tivoli Storage Manager Client")) {
			$retval = @{}
			$retval.Add("Publisher", $Publisher)
			$retval.Add("DisplayVersion", $DisplayVersion)
			$retval.Add("DisplayName", $DisplayName)
			$retval.Add("InstallDate", $thisSubKey.GetValue("InstallDate"))
			$retval.Add("InstallLocation", $thisSubKey.GetValue("InstallLocation"))
			$retval.Add("UninstallString", $thisSubKey.GetValue("UninstallString"))
			$retval.Add("Version", $thisSubKey.GetValue("Version"))
			$retval.Add("VersionMajor", $thisSubKey.GetValue("VersionMajor"))
			$retval.Add("VersionMinor", $thisSubKey.GetValue("VersionMinor"))
		}
	}
	Return $Retval
}

Function Get-ServicesAtLocation {
	param (
		[string]$ComputerName = 'localhost',
		[string]$InstallLocation
	)
	$Services = Get-WmiObject win32_service -Computername $Computername | where {$_.PathName.contains($InstallLocation)}
	Return $Services
}

Function Remote-ExecCmd {
	param (
		[string]$FQDN,
		[string]$Command
  	)
	Write-Host "  Executing remote command: $command"
	$RemoteProcess = ([wmiclass]"\\$FQDN\root\cimv2:Win32_Process").create($Command)
}

cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-TSM_Update"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$SystemList = Get-Content -Path C:\Scripts\Powershell\TSM\systems.ini
$SystemList = "VS012"
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

		$TSMClientInfo = Get-TSMClientInfo -ComputerName $System
		if($TSMClientInfo -ne $null) {

			$TSMVersion = $TSMClientInfo.Get_Item("DisplayVersion")
			Echo-Log "  TSM Client version:  $TSMVersion"
			$TSMInstall = $TSMClientInfo.Get_Item("InstallLocation")
			Echo-Log "  Installed at:        $TSMInstall"

			# Collect service information before upgrade
			Echo-Log "  Collection TSM services information."
			$ServColl = Get-ServicesAtLocation $System $TSMInstall
			if($ServColl -ne $null) {
				$ServOk = $True
				foreach($Service in $ServColl) {
					$ServName = $Service.Name
					Echo-Log "    Service: $ServName"
					if($Service.Started -eq "True") {
						Echo-Log "    Status:   Started"
						Echo-Log "              Stopping service remotely"
						$Stopped = Remote-StopService $System $ServName
						if($Stopped) {
							Echo-Log "              Service $ServName is now stopped."
						} else {
							$ServOk = $False
							Echo-Log "              Service $ServName could not be stopped."
						}
					} else {
						Echo-Log "    Status:   Stopped"
					}
				}
			} else {
				Echo-Log "No TSM services could be found."
			}

			$IncExcl = $TSMInstall + "\baclient\inclexcl.dsm"
			$IncExcl = $IncExcl.replace("C:", "\\" + $System + "\C$")

			# Perform upgrade action remotely
			Copy \\S005\TSM\TSM_BA_CONFIG\inclexcl.dsm $IncExcl

			# Restarting services that were running before the upgrade
			if($ServColl -ne $null) {
				foreach($Service in $ServColl) {
					$ServName = $Service.Name
					if($Service.Started -eq "True") {
						Echo-Log "  Starting services previously stopped."
						Echo-Log "    Service: " $ServName
						Echo-Log "              Starting service remotely"
						$Started = Remote-StartService $System $ServName
						if($Started) {
							Echo-Log "              Service $ServName is started."
						} else {
							$ServOk = $False
							Echo-Log "              Service $ServName could not be started."
						}
					}
				}
			}

		} else {
			Echo-Log "No TSM client found on $System"
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