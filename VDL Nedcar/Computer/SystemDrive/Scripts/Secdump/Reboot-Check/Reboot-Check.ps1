# ---------------------------------------------------------
# Export SQL reboot queries to email
#
# Marcel Jussen
# 16-2-2016
# ---------------------------------------------------------

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$Global:DEBUG = $False

#----
# Check type of variable returned by SQL
# If type DBNull then replace with empty string
#----
Function Reval_Parm { 
	Param (
		$Parm
	)
	if(($Parm -eq $null) -or ($Parm.Length -eq 0)) { $Parm = '' }
	$VarType = $Parm.GetType()	
	if($VarType.Fullname -eq "System.DBNull") { $Parm = '' }
	if($Parm -ne $null) { $Parm = $Parm.trim() }
	Return $Parm
} 


Function Check-RogueReboots {
	
	$UDL = Read-UDLConnectionString $glb_UDL
	$UDLConnection = New-UDLSQLconnection $UDL
	
	# Query lists all new accounts with status ISP_VERIFIED=Y and ISP_AD_INSERT=Y
	# Query is extended with account create information.
	$query = "select * from vw_VNB_SYSINFO_EVENTS_ROGUE_REBOOTS_LASTWEEK"
	Echo-Log "Parse query: $query"
	$data = Invoke-SQLQuery $query $UDLConnection
	$reccount = 0
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 } 
		Echo-Log "Number of records returned: $reccount"		
		Echo-Log ("-"*60)
		Echo-Log (' ')
		Echo-Log "Rogue reboots detected on the following systems:"
		$Global:Changes_Proposed = $reccount
		ForEach($rec in $data) {
			# Retrieve data from SQL record
			$SYSTEMNAME = Reval_Parm $rec.SYSTEMNAME
			$DESCRIPTION = Reval_Parm $rec.DESCRIPTION
			$REBOOTEVENT = $rec.TIMEGENERATED
			$REBOOTPLAN = $rec.LASTRUNTIME
			echo-log "$SYSTEMNAME [$DESCRIPTION] | Planned reboot:[$REBOOTPLAN] | Rogue reboot event:[$REBOOTEVENT]"
		}
		Echo-Log (' ')
		Echo-Log ('Rogue reboots are usually a result of installing updates and waiting to long (>10 hours) to restart the system.')
		Echo-Log ('Check when the updates are installed and plan the reboot scheduled task to execute within 10 hours after the installation.')
		Echo-Log (' ')
		Echo-Log ("-"*60)
	} else {
		Echo-Log "No records found."
	}	
	return $reccount
}

Function Check-TrustedInstallerReboots {
	
	$UDL = Read-UDLConnectionString $glb_UDL
	$UDLConnection = New-UDLSQLconnection $UDL
	
	# Query lists all new accounts with status ISP_VERIFIED=Y and ISP_AD_INSERT=Y
	# Query is extended with account create information.
	$query = "select * from vw_VNB_SYSINFO_EVENTS_EXTRA_RESTARTS_BY_TRUSTEDINSTALLER"
	Echo-Log "Parse query: $query"
	$data = Invoke-SQLQuery $query $UDLConnection
	$reccount = 0
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 } 
		Echo-Log "Number of records returned: $reccount"
		Echo-Log ("-"*60)
		Echo-Log (' ')
		Echo-Log "Extra reboots triggered by TrustedInstaller detected on the following systems:"
		$Global:Changes_Proposed = $reccount
		ForEach($rec in $data) {
			# Retrieve data from SQL record
			$SYSTEMNAME = Reval_Parm $rec.SYSTEMNAME
			$DESCRIPTION = Reval_Parm $rec.DESCRIPTION
			$REBOOTEVENT = $rec.TIMEGENERATED
			$REBOOTPLAN = $rec.LASTRUNTIME
			echo-log "$SYSTEMNAME [$DESCRIPTION] | Planned reboot:[$REBOOTPLAN] | Rogue reboot event:[$REBOOTEVENT]"
		}
		Echo-Log (' ')
		Echo-Log ('Extra reboots occur if multiple reboots are required to install an update.')
		Echo-Log ('This behaviour can not be altered. Live with it!')
		Echo-Log (' ')
		Echo-Log ("-"*60)
	} else {
		Echo-Log "No records found."
	}	
	return $reccount
}


# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Reboot-Check"
$GlobLog = New-LogFile -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

$records = Check-RogueReboots
$records += Check-TrustedInstallerReboots

Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if($Global:DEBUG) {
	Echo-Log "** Debug: Sending resulting log as a mail message."
} 

Close-LogSystem

$SendTo = "m.jussen@vdlnedcar.nl"
$dnsdomain = 'vdlnedcar.nl'
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

if($records -gt 0) { 
	$title = "Warning: unscheduled server reboots detected."
	$MailLog = $GlobLog 
	Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $MailLog -Headline $Title	
}

