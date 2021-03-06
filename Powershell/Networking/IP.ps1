# =========================================================
#
# Inventory IP settings per server and 
# disable Dynamic DNS registration on all interfaces.
#
# Marcel Jussen
# 12-11-2013
#
# =========================================================
cls
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $false

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1

function Run-RemoteCMD { 
 
    param ( 
    	[Parameter(Mandatory=$true,valuefrompipeline=$true)] 
    	[string]$compname,
		[string]$command
	)
	
	process { 
		$DoNotChange = $computername.Contains("VC")
		if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("DC") }	
		if($DoNotChange -eq $false) {
			if($Global:DEBUG -ne $true) { 		
       			$newproc = Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ($command) -ComputerName $compname 
       			if ($newproc.ReturnValue -eq 0 ) 
					{ Echo-Log "$compname : *** Command [$($command)] invoked sucessfully on $($compname)" }                 
    		} else {
				Echo-Log "$compname : (DEBUG) Command [$($command)] invoked sucessfully on $($compname)"
			}
		}
	}
	
} 

Function Enable_DynDNSReg {
	Param (
		[string]$Computername = $null
    )         
	if([string]::IsNullOrEmpty($Computername)) { return $null }
	
	# Check if computername is related to Citrix or a domain controller
	$DoNotChange = $computername.Contains("VC")
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("DC") }	
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S014") }	
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S015") }	
	if($DoNotChange -eq $false) {
		$wmiQuery = "select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE and DHCPEnabled=FALSE"
    	$networkAdapters = (Get-WmiObject -ErrorAction SilentlyContinue -ComputerName $computername -Query $wmiQuery)
    	foreach ($networkAdapter in $networkAdapters) { 
			$capt = $networkAdapter.Description	
			$DynDNS = $networkAdapter.FullDNSRegistrationEnabled	
			$IP = [string] $networkAdapter.IPAddress			
			$VLAN88 = $IP.COntains("192.168.88.")
			if($VLAN88 -ne $true) { 
				if($DynDNS -eq $false) {
					$Global:Changes_Proposed++
					if($Global:DEBUG -ne $true) { 
						$ret = $networkAdapter.SetDynamicDNSRegistration($true)
						$Global:Changes_Committed++
						Echo-Log "$computername : $capt : ***  Dynamic DNS registration is set to On."
					} else {
						Echo-Log "$computername : $capt : (DEBUG) ***  Dynamic DNS registration is set to On."
					}
				} else {
					Echo-Log "$computername : $capt : Dynamic DNS registration is already set to On."
				}
			}														
		}	 
	}
}

Function Disable_DynDNSReg {
	Param (
		[string]$Computername = $null
    )         
	if([string]::IsNullOrEmpty($Computername)) { return $null }
	
	# Check if computername is related to Citrix or a domain controller
	$DoNotChange = $computername.Contains("VC")
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("DC") }		
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S014") }	
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S015") }	
	if($DoNotChange -eq $false) {
		$wmiQuery = "select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE and DHCPEnabled=FALSE"
    	$networkAdapters = (Get-WmiObject -ErrorAction SilentlyContinue -ComputerName $computername -Query $wmiQuery)
    	foreach ($networkAdapter in $networkAdapters) { 
			$capt = $networkAdapter.Description	
			$DynDNS = $networkAdapter.FullDNSRegistrationEnabled			
			if($DynDNS -eq $true) {
				$Global:Changes_Proposed++
				if($Global:DEBUG -ne $true) { 
					$ret = $networkAdapter.SetDynamicDNSRegistration($false)
					$Global:Changes_Committed++
					Echo-Log "$computername : $capt : ***  Dynamic DNS registration is set to Off."
				} else {
					Echo-Log "$computername : $capt : (DEBUG) ***  Dynamic DNS registration is set to Off."
				}
			} else {
				Echo-Log "$computername : $capt : Dynamic DNS registration is already set to Off."
			}														
		}	 
	}
}

Function Change_DNS_SearchOrder {
	Param (
		[string]$Computername = $null
    )         
	if([string]::IsNullOrEmpty($Computername)) { return $null }
	
	# Check if computername is related to Citrix or a domain controller
	$DoNotChange = $computername.Contains("VC")
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("DC") }	
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S014") }	
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S015") }	
	if($DoNotChange -eq $false) {
		$wmiQuery = "select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE and DHCPEnabled=FALSE"
    	$networkAdapters = (Get-WmiObject -ErrorAction SilentlyContinue -ComputerName $computername -Query $wmiQuery)
    	foreach ($networkAdapter in $networkAdapters) { 
			$capt = $networkAdapter.Description					
			$CurDNS = $networkAdapter.DNSServerSearchOrder			
			$CurDNS = [string]$CurDNS
			
			$OldDNS = $CurDNS.Contains("10.178.0.6")
			if($OldDNS -eq $false) { $OldDNS = $CurDNS.Contains("10.178.0.7") }
			
			$NewDNS = "10.30.20.10","10.30.20.11"
			if($OldDNS -eq $true) {
				$Global:Changes_Proposed++
				if($Global:DEBUG -ne $true) {
					$ret = $networkAdapter.SetDNSServerSearchOrder($NewDNS)					
					$Global:Changes_Committed++
					Echo-Log "$computername : $capt : ***  New DNS search order: $NewDNS"
				} else {
					Echo-Log "$computername : $capt : (DEBUG) ***  New DNS search order: $NewDNS"
				}
			} else {
				if([string]::IsNullOrEmpty($CurDNS)) {
					Echo-Log "$computername : $capt : No DNS search order specified."
				} else {
					Echo-Log "$computername : $capt : DNS search order is already set."
				}
			}										
		}
	} 
}

Function Remove_WINS_Servers {
	Param (
		[string]$Computername = $null
    )         
	if([string]::IsNullOrEmpty($Computername)) { return $null }
	
	# Check if computername is related to Citrix or a domain controller
	$DoNotChange = $computername.Contains("VC")
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("DC") }	
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S014") }	
	if($DoNotChange -eq $false) { $DoNotChange = $computername.Contains("S015") }	
	if($DoNotChange -eq $false) {
		$wmiQuery = "select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE and DHCPEnabled=FALSE"
    	$networkAdapters = (Get-WmiObject -ErrorAction SilentlyContinue -ComputerName $computername -Query $wmiQuery)
    	foreach ($networkAdapter in $networkAdapters) { 			
			$capt = $networkAdapter.Description	
			$CurNBTIP = $networkAdapter.tcpipnetbiosoptions
			$WINSPrimaryServer = [string] $networkAdapter.WINSPrimaryServer 
           	$WINSSecondaryServer = [string] $networkAdapter.WINSSecondaryServer
				
			Echo-Log "$computername : $capt : Primary WINS server: $WINSPrimaryServer"
			Echo-Log "$computername : $capt : Secondary WINS server: $WINSSecondaryServer"
			
			# Check primary WINS record
			$OldWINS = $WINSPrimaryServer.Contains("10.178.0.6")
			if($OldWINS -eq $false) { $OldWINS = $WINSPrimaryServer.Contains("10.178.0.7") }
			
			#Check sec WINS record
			if($OldWINS -eq $false) { $OldWINS = $WINSSecondaryServer.Contains("10.178.0.6") }
			if($OldWINS -eq $false) { $OldWINS = $WINSSecondaryServer.Contains("10.178.0.7") }
			
			if($OldWINS -eq $true) {
				$Global:Changes_Proposed++				
				if($Global:DEBUG -ne $true) {
					$ret = $networkAdapter.SetWINSServer('','')
					$Global:Changes_Committed++
					Echo-Log "$computername : $capt : ***  Clear WINS servers records."
				} else {
					Echo-Log "$computername : $capt : (DEBUG) ***  Clear WINS servers records."
				}
			} else {
				if([string]::IsNullOrEmpty($WINSPrimaryServer)) {
					Echo-Log "$computername : $capt : No primary WINS server specified."
				} 
				if([string]::IsNullOrEmpty($WINSSecondaryServer)) {
					Echo-Log "$computername : $capt : No secondary WINS server specified."
				} 
			}	
			
			if($CurNBTIP -ne 2) {				
				# A value of 1 for settcpipnetbios enables it, and 2 disables it. 0 is to use the DHCP default (from memory).				
				$Global:Changes_Proposed++
				if($Global:DEBUG -ne $true) {
					$ret = $networkAdapter.settcpipnetbios(2)
					$Global:Changes_Committed++
					Echo-Log "$computername : $capt : ***  Disable NETBIOS over TCP/IP option."
				} else {
					Echo-Log "$computername : $capt : (DEBUG) ***  Disable NETBIOS over TCP/IP option."
				}
			} else {
				Echo-Log "$computername : $capt : NETBIOS over TCP/IP option is already disabled."
			}
		}
	}
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-IP-Configuration-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
$computers = collectAD_Servers
$compcount = 0
# $computername = "S170"

foreach ($computer in $computers) { 
	$computername = $computer.properties.name	
	if($computername -ne $null) {
		$computername = [string]$computername		
		$compcount++		
		
		# Enable_DynDNSReg $computername
		# Disable_DynDNSReg $computername
		
		Change_DNS_SearchOrder $computername
		Remove_WINS_Servers $computername
		
		# Run-RemoteCMD -compname $computername -command "ipconfig /registerdns"
		
		Echo-Log ("-"*60)
    } 
}

Echo-Log "Number of systems    : $compcount"
Echo-Log "Changes proposed     : $Global:Changes_Proposed"
Echo-Log "Changes committed    : $Global:Changes_Committed"

Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)
