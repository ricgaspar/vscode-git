#-----------------------------------------------------------------------
# VDL Nedcar Windows server standaard
#
# Configure SNMP script
#
# Author: Marcel Jussen
#-----------------------------------------------------------------------

param (
	[string]$NCSTD_VERSION = '6.0.0.1'
)

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-SNMP-$NCSTD_VERSION.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

Function Get-Manufacturer {
	$Man = Get-WmiObject Win32_Computersystem
	$retval = $Man.Manufacturer
	return $retval
}

Function IsVMware {
	$Man = Get-Manufacturer 
	$retval = $Man -contains 'VMware, Inc.'
	return ($retval)
} 

Function IsHP {
	$Man = Get-Manufacturer
	$retval = ($Man -contains 'HP') -or ($Man -contains 'Hewlett Packard')
	return ($retval)
} 

Function IsDell {
	$Man = Get-Manufacturer
	$retval = $Man -contains 'Dell Inc.'
	return ($retval) 
}

Write-Host "Started NCSTD Configure $NCSTD_VERSION"

$SName = "\" + $MyInvocation.MyCommand.Name
$SPath = $MyInvocation.MyCommand.Path
$SPath = $SPath.Replace($SName, $null)

if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {	

	# Determine manufacturer
	$IsHP = IsHP
	if($IsHP) {
		Append-Log "This is a HP system."
		$PermittedManager = 'vs102.nedcar.nl'		
		$TrapDestination = 'vs102.nedcar.nl'
	}
	
	$IsDell = IsDell
	if($IsDell) {
		Append-Log "This is a Dell system."		
		$PermittedManager = 'vs045.nedcar.nl'		
		$TrapDestination = 'vs045.nedcar.nl'
	}
	
	$IsVMware = IsVMware
	if($IsVMware) {
		Append-Log "This is a VMware system. No SNMP traps or managers are needed."		
		$PermittedManager = $null
		$TrapDestination = $null
	}
			
	# Define SNMP properties
	Append-Log "Configuring SNMP parameter settings."
	$t = Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters -Name 'EnableAuthenticationTraps' -Value 0 -Force -ErrorAction SilentlyContinue
	$t = Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\RFC1156Agent -Name 'sysLocation' -Value 'Born' -Force -ErrorAction SilentlyContinue
	$t = Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\RFC1156Agent -Name 'sysContact' -Value 'VDL Nedcar - IT' -Force -ErrorAction SilentlyContinue
	
	# Define SNMP communities
	Append-Log "Configuring SNMP communities."
	$t = Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities -Recurse	-ErrorAction SilentlyContinue	
	$t = New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters -Name 'ValidCommunities' -Force -ErrorAction SilentlyContinue
	$t = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities -Name "NedCarSNMPread" -PropertyType dword -Value 4 -Force -ErrorAction SilentlyContinue
	$t = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities -Name "NedCarSNMPcom" -PropertyType dword -Value 8 -Force -ErrorAction SilentlyContinue
	$t = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities -Name "public" -PropertyType dword -Value 4 -Force -ErrorAction SilentlyContinue
	
	# Define SNMP Permitted managers
	Append-Log "Configuring SNMP permitted managers."
	$t = Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers -Recurse -ErrorAction SilentlyContinue
	$t = New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters -Name 'PermittedManagers' -Force -ErrorAction SilentlyContinue
	
	if($PermittedManager -ne $null) {
		Append-Log "Permitted SNMP manager is $PermittedManager"
		$t = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers -Name '1' -PropertyType string -Value 'nagios.nedcar.nl' -Force -ErrorAction SilentlyContinue 
		$t = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers -Name '2' -PropertyType string -Value $PermittedManager -Force -ErrorAction SilentlyContinue 
	} else {
		Append-Log "No permitted manager defined."
	}
	
	# Define SNMP Trap destinations
	Append-Log "Configuring SNMP trap destinations."
	$t = Remove-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration -Recurse -ErrorAction SilentlyContinue
	$t = New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters -Name 'TrapConfiguration' -Force -ErrorAction SilentlyContinue
	
	if($TrapDestination -eq $null) {
		Append-Log "No trap destination defined."
	} else {
		Append-Log "Traps are send to $TrapDestination"
		if($IsHP) { 						
			$t = New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration -Name 'NedCarSNMP' -Force -ErrorAction SilentlyContinue	
			$t = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration\NedCarSNMP -Name '1' -PropertyType string -Value $TrapDestination -Force -ErrorAction SilentlyContinue
		} 
	
		if($IsDell) { 
			$t = New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration -Name 'NedCarSNMPDell' -Force -ErrorAction SilentlyContinue	
			$t = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration\NedCarSNMPDell -Name '1' -PropertyType string -Value $TrapDestination -Force -ErrorAction SilentlyContinue
		}
	}	
	
	Append-Log "SNMP configuration completed."
}

