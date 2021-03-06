# =========================================================
#
# Inventory IP settings on this computer and
# - change DNS search order
# - remove WINS search order
#
# Marcel Jussen
# 11-2-2014
#
# =========================================================

# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $true

$Global:glb_EVENTLOG  = $null
$Global:glb_EVENTLOGFile = $null
$Global:glb_EVENTLOGScriptName = $null

# Logo to add to emails
$Global:glb_LogoPath = "C:\Scripts\Secdump\PS\logo-vdl-nl-small.jpg"
# LogoAdd will change to true if the logo file is found.
$Global:glb_LogoAdd = $false

# CSS Styles for emails
$Global:glb_CSSPath = "C:\Scripts\Secdump\PS\css_styles.html"

function Init-Log {
# ---------------------------------------------------------
# Initialize the file log.
# ---------------------------------------------------------
	Param ( 
		[string] $LogFileName = "$$UNDEFINED_LOG_NAME",
		[bool] $append = $false,
		[bool] $alternate_location = $false
	)	
	if([string]::IsNullOrEmpty($Global:glb_EVENTLOGFile)) {
		if($alternate_location -eq $false) {
			if((Test-Path "C:\Logboek" -PathType Container) -eq $false) {New-Item -Path "C:\Logboek" -type directory -Force} 
			$Global:glb_EVENTLOGFile = "C:\Logboek\" + $LogFileName + ".log"
		} else {
			$Global:glb_EVENTLOGFile = $LogFileName
		}
	}
	if(($append -eq $false) -and (test-path $Global:glb_EVENTLOGFile))
	{
		Remove-Item $Global:glb_EVENTLOGFile -Force -ErrorAction SilentlyContinue
	}
	
	if([string]::IsNullOrEmpty($Global:glb_EVENTLOGScriptName)) {	
		$Global:glb_EVENTLOGScriptName = $LogFileName
	}
	
	return $Global:glb_EVENTLOGFile
}

function Getglb_EVENTLOG {	
# ---------------------------------------------------------
# Get the event log object used for logging.
# ---------------------------------------------------------
	if([string]::IsNullOrEmpty($Global:glb_EVENTLOG)) {	
		$Global:glb_EVENTLOG = new-object System.Diagnostics.EventLog("Application")
		$Global:glb_EVENTLOG.Source = $Global:glb_EVENTLOGScriptName
	}
	return $Global:glb_EVENTLOG
}


function Log-Time { 
# ---------------------------------------------------------
# Create text with current time and date.
# ---------------------------------------------------------
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	return $logTime 
}

function Format-Message { 
# ---------------------------------------------------------
# Default format for each line of text in the log
# ---------------------------------------------------------
	param ( 
		[string] $logText = "no message." 
	)
	$logTime = Log-Time
	return ( "[" + $logTime + "]: " + $logText )
}

function File-Log {
# ---------------------------------------------------------
# log text to file
# ---------------------------------------------------------
	Param ( 
		[string] $LogPath, 
		[string] $logText
	)	
	if([string]::IsNullOrEmpty($LogPath)) { return -1 }
	$logText | Out-File -FilePath $LogPath -Append
}

function Echo-Log {
# ---------------------------------------------------------
# Write normal text to console and log file.
# ---------------------------------------------------------
		Param (    	        				
        [string]$logText
    )		
	$Message = Format-Message $logText
	Write-Host $Message
		
	$glb_EVENTLOG = Getglb_EVENTLOG
	$EventType = [System.Diagnostics.EventLogEntryType]::Information
	# $glb_EVENTLOG.WriteEntry( $logText, $EventType, 1000 )
		
	[void](File-Log $Global:glb_EVENTLOGFile $Message)
}

# ---------------------------------------------------------
# Includes
# . C:\Scripts\Secdump\PS\libLog.ps1
# . C:\Scripts\Secdump\PS\libAD.ps1

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
		if($networkAdapters -ne $null) {
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
		} else {
			Echo-Log "DNS: No static configured adapters found."
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
		if($networkAdapters -ne $null) {
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
		} else {
			Echo-Log "WINS: No static configured adapters found."
		}
	}
}

Function SCCM_Hardware_Inventory {	
	$SMSCli = [wmiclass] "\\myComputerName\root\ccm:SMS_Client"
	$SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")
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
Echo-Log ("="*60)

# Changes are executed on the local machine
$computername = "localhost"
Change_DNS_SearchOrder $computername
Remove_WINS_Servers $computername

if($Global:Changes_Committed -ne 0) {
	Echo-Log "Triggering a hardware SCCM inventory."
	SCCM_Hardware_Inventory
}
	
Echo-Log ("-"*60)

Echo-Log "Changes proposed     : $Global:Changes_Proposed"
Echo-Log "Changes committed    : $Global:Changes_Committed"
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)
