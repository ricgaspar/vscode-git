# =========================================================
# SCCM Client installation on servers
# Determines best location for CCMCACHE and installs client
#
# Marcel Jussen
# 23-04-2014
#
# =========================================================
param(
	[string]$hostname
)
cls

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1

# Location of SCCM management point, fallback service point 
# and site code
$CFGMGR_MP = 's007.nedcar.nl'
$CFGMGR_FSP = 's008.nedcar.nl'
$CFGMGR_CODE = 'VNB'

# Location and Size of SCCM cache
$CFGMGR_CSD = 'C:\'
$CFGMGR_CSZ = '5120'
# Non-standard client parameters
$CFG_PARAMS = "CCMENABLELOGGING=TRUE CCMLOGMAXHISTORY=2"

# Construct location of client and installation parameters
$CFG_CLIENT = "\\$CFGMGR_MP\SMS_$CFGMGR_CODE\Client\ccmsetup.exe"
$CFG_INST = "/mp:$CFGMGR_MP SMSSITECODE=$CFGMGR_CODE FSP=$CFGMGR_FSP SMSCACHESIZE=$CFGMGR_CSZ $CFG_PARAMS"

Function Remote-ExecCmd {
	param (
		[string]$FQDN,	
		[string]$Command
  	)
	Echo-Log "Executing remote command: $command"	
	$wsman = new-pssession -computername $FQDN
	$output = invoke-command -session $wsman -scriptblock { $Command }
	Echo-Log "Output: $output"
	remove-pssession -session $wsman	
}

Function Remote-GPUpdate {
	param (
		[string]$FQDN		
  	)
	Echo-Log "Update GPO remotely."	
	$wsman = new-pssession -computername $FQDN
	$output = invoke-command -session $wsman -scriptblock { gpupdate /force }
	Echo-Log "Output: $output"
	remove-pssession -session $wsman	
}

Function Remote-SCCM-Agent-Install {
	param (
		[string]$FQDN,
		[string]$Command
  	)
	Echo-Log "Installing SCCM agent remotely."	
	
	# Copy setup executable to temp folder
	Copy-Item "\\$CFGMGR_MP\SMS_$CFGMGR_CODE\Client\ccmsetup.exe" "\\$Computername\C$\Windows\Temp\ccmsetup.exe" -Force -ErrorAction SilentlyContinue

	# Create installation batch file
	$BatchFile = "\\$Computername\C$\Windows\Temp\ccminstall.cmd"
	if(Test-Path $BatchFile) { Remove-Item $BatchFile -Force -ErrorAction SilentlyContinue }
	Add-Content $BatchFile $Command -Force -ErrorAction SilentlyContinue

	#Create session object 
	$Session = New-PSSession -ComputerName $ComputerName 

	#Invoke-Command
	$Script = { C:\Windows\Temp\ccminstall.cmd } 
	$Job = Invoke-Command -Session $Session -Scriptblock $Script -AsJob
	$Null = Wait-Job -Job $Job

	#Close Session
	Remove-PSSession -Session $Session	
}

Function Remote-CFGCLIENT-Bits {
	param (
		[string]$FQDN
	)	
	$system = gwmi Win32_OperatingSystem -ComputerName $FQDN -ErrorAction SilentlyContinue
	if($system -eq $null) { return $null } 
	$ProdSysdrive = $system.SystemDrive
	$ProdSysdrive = $ProdSysdrive.Replace(':','$')
	$Path = "\\"+ $FQDN + "\C$\Windows\System32\qmgr.dll"
	Echo-Log "Checking version of $Path"
	$File = get-item $Path	
	$result = $File.VersionInfo.Productversion
	Echo-Log "Version: $result"
	return $result
}

Function Remote-CFGCLIENT-Role {
	param (
		[string]$FQDN
	)
	Echo-Log "Retrieve system information from $FQDN"
	$system = gwmi Win32_OperatingSystem -ComputerName $FQDN -ErrorAction SilentlyContinue
	if($system -eq $null) { return $null } 
	$ProdType = $system.ProductType
	$ProdName = $system.Caption
	$ProdDesc = $system.Description
	$ProdSysdrive = $system.SystemDrive	
	Echo-Log "FQDN: $FQDN"
	Echo-Log "Description: $ProdDesc"
	Echo-Log "Caption: $ProdName"
	Echo-Log "System drive: $ProdSysdrive"
	return $ProdType
}

Function Remote-CFGCLIENT-Installed {
	param (
		[string]$FQDN
	)	
	if($FQDN -eq $null) { return $null } 	
	
	$ccmexec = Get-Process CcmExec -ComputerName $FQDN -ErrorAction silentlycontinue
	if([string]::IsNullOrEmpty($ccmexec)) {
		$ccmsetup = Get-Process CcmSetup -ComputerName $FQDN -ErrorAction silentlycontinue
		if([string]::IsNullOrEmpty($ccmsetup)) {
			Echo-Log "No active SCCM process running on $FQDN"
		} else {
			Echo-Log "ERROR: SCCM Client installation is already running on $FQDN."
			return 2
		}
	} else {
		Echo-Log "ERROR: SCCM Client process is already running on $FQDN."
		return 1
	}
	
	return 0
}

Function Remote-CFGCLIENT-CACHE {
	param (
		[string]$FQDN,
		[string]$PreferredVolume = 'C:'
	)
		
	$minimumfreegb = 5
	$preferedfreegb = 5
	$PrefVolname = $null
	
	$logicaldisks = gwmi Win32_LogicalDisk -ComputerName $FQDN -Filter "DriveType=3" -ErrorAction SilentlyContinue |
		select Name,FileSystem,FreeSpace,BlockSize,Size | % {$_.BlockSize=(($_.FreeSpace)/($_.Size))*100;$_.FreeSpace=($_.FreeSpace/1GB);$_.Size=($_.Size/1GB);$_} 	
	if($logicaldisks -eq $null) { return $null} 
	
	# First check if there is a C: volume
	$volstd = $logicaldisks | Where-Object {$_.Name -eq $PreferredVolume}
	$NoC = [string]::IsNullOrEmpty($volstd)
	if($NoC) {
		# No volume C: was found.
		Echo-Log "No volume $PreferredVolume was found."
	} else {
		# Volume C: was found, but is the prefered minimum size free?
		$sizeC = $volstd.FreeSpace
		Echo-Log "Volume $PreferredVolume has $sizeC free space."
		if($sizeC -ge $preferedfreegb) { 
			Echo-Log "Volume $PreferredVolume has the minimum required free size of $preferedfreegb Gb."
			$PrefVolname = $PreferredVolume
		} else {
			Echo-Log "Volume $PreferredVolume does not have the minimum required free size of $preferedfreegb Gb."
		}
	}
	
	# If a prefered volume has not been found, check all volumes
	if($PrefVolname -eq $null) {
		$vols5gb = $logicaldisks | Where-Object {$_.Freespace -gt $minimumfreegb}
		if([string]::IsNullOrEmpty($vols5gb)) { 
			# No volume found that has the minimum required freespace
			# Revert to standard location C:
			if($NoC -eq $false) { 
				Echo-Log "No volume was found with minimum free size of $minimumfreegb Gb."
				$PrefVolname = 'C:'
			}
		} else {
			# volumes where found. Sort table descending and retrieve first volume
			$sorted = $vols5gb | Sort-Object BlockSize -Descending
			$PrefVolname = $sorted[0].Name
			$preferedvolsize = $sorted[0].FreeSpace
			Echo-Log "Volume with most free space is $PrefVolname with $preferedvolsize Gb free."
		}
	}
	
	return $PrefVolname
}

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
$t = Init-Log -LogFileName "SCCM_Client_installation"
Echo-Log "Started script $ScriptName"  

# If no hostname is parsed use localhost
if([string]::IsNullOrEmpty($hostname)) {
	$hostname = [System.Net.Dns]::GetHostName()
}
$hostname = 'vdlnc00167'

# Construct execution command
$hostname = ([system.net.dns]::GetHostByName($hostname)).hostname 

Echo-Log ('-'*70)
$role = Remote-CFGCLIENT-Role $hostname
if($role -le 1) { 
	Echo-Log "The remote host is not a server system."	
	# return 1
}

$processcheck = Remote-CFGCLIENT-Installed $hostname
if($processcheck -ne 0) {
	Echo-Log "Cannot continue with installation process."
	# return 2
}

$bitsversion = Remote-CFGCLIENT-Bits $hostname
$bitshighver = $bitsversion[0]
$bitslowver = $bitsversion[2]
if($bitshighver -eq '6') {
	switch ($bitslowver) {
		2 { Echo-Log "ERROR: BITS version 1.2 detected."; return 3 } 
		5 { Echo-Log "ERROR: BITS version 1.5 detected."; return 3 } 
		6 { Echo-Log "ERROR: BITS version 2.0 detected."; return 3 } 
		7 { Echo-Log "ERROR: BITS version 2.5 detected." } 
	}
}
if($bitshighver -eq '7') {
	switch ($bitslowver) {
		0 { Echo-Log "BITS version 3.0 detected." } 
		5 { Echo-Log "BITS version 4.0 detected." } 
		default { Echo-Log "BITS version 4.x detected." } 
	}
}

# Remote-GPUpdate $hostname

$prefered_volume = Remote-CFGCLIENT-CACHE $hostname 'Z:'
if($prefered_volume -ne $null) { 
	if ($prefered_volume -ne 'C:') {		
		$CFGMGR_CSD = "$prefered_volume\"
		Echo-Log "Using volume $CFGMGR_CSD as client cache location."
		$CFG_INST += " SMSCACHEDIR=$CFGMGR_CSD"
	} else {
		Echo-Log "Using client defaults as client cache location."
	}	
	
	$TxtArray = $CFG_INST.Split()
	Echo-Log "Start installation of SCCM client with parameters:"
	ForEach($txt in $TxtArray) { 
		Echo-Log "  $Txt"
	}
	
	# Remote-SCCM-Agent-Install -FQDN $hostname -Command  $CFG_INST

} else {
	Echo-Log "ERROR: No suitable volume was found!"
}

Echo-Log ('-'*70)
Echo-Log "End script $ScriptName"