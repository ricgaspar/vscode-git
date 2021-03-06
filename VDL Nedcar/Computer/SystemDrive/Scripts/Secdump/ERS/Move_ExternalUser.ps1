# ---------------------------------------------------------
# Move_External_Users
#
# Marcel Jussen
# 5-2-2013
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0
$Global:DEBUG = $False

$Global:SMTPRelayAddress = "mail.vdlnedcar.nl"

#----
# Check type of variable returned by SQL
# If type DBNull then replace with empty string
#----
Function Reval_Parm { 
	Param (
		$Parm
	)
	if(($Parm -eq $null) -or ($Parm.Length -eq 0)) { $Parm = "" }
	$VarType = $Parm.GetType()	
	if($VarType.Fullname -eq "System.DBNull") { $Parm = "" }
	if($Parm -ne $null) { $Parm = $Parm.trim() }
	Return $Parm
} 

Function Move_ADObject {
	Param (
		[string]$DN,
		[string]$NewOU
	)	
	if($DN -eq $null) { return -1 }
	if($DN.Length -eq 0) { return -1 } 	
	if($NewOU -eq $null) { return -1 }
	if($NewOU.Length -eq 0) { return -1 } 
	
	$OrigDN = $DN
	
	$ADObject = [ADSI]($OrigDN)
	if($ADObject.Path -eq $OrigDN) {		
		$MoveToOU = [ADSI]($NewOU)	
		if($MoveToOU.Path -eq $NewOU) {
			$ClassName = $MoveToOU.Path
			if($MoveToOU.SchemaClassName -eq "organizationalUnit") {					
				if($Global:DEBUG) {
					Echo-Log "DEBUG: Move $OrigDN -> $NewOU"				
				} else {
					Echo-Log "Move $OrigDN -> $NewOU"		
					$ADObject.PSBase.moveto($MoveToOU)
					$Global:Changes_Committed += 1
				}
			}
		}
	}
}

#
# Query SEDCUMP for list of external users that must be moved to their appropriate OU.
#
Function Move_AD_Accounts {
	# ------------------------------------------------------------------------------
	# Connect to SQL server

	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Error-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

	#Init return value
	$ErrorVal = 0	
	
	$query = "select * from vw_PND_CHANGE_MOVE_EXTERNAL_Q"
	Echo-Log "Parse query: $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 } 
		Echo-Log "Number of records returned: $reccount"
		$Global:Changes_Proposed = $reccount
		Echo-Log ("-"*60)
		ForEach($rec in $data) {			
		
			# Retrieve data from SQL record
			$PND_NAME = Reval_Parm $rec.NAME
			$PND_SAMACCOUNTNAME= Reval_Parm $rec.SAMACCOUNTNAME
			$PND_DN = Reval_Parm $rec.DN
			$PND_NEWOU = Reval_Parm $rec.NEWOU			
			
			Move_ADObject $PND_DN $PND_NEWOU
						
		}			
	} else {
		Echo-Log "No records found."
	}	
	
	$query = "select * from vw_PND_CHANGE_MOVE_EXTERNAL_E"
	Echo-Log "Parse query: $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 } 
		Echo-Log "Number of records returned: $reccount"
		$Global:Changes_Proposed += $reccount
		Echo-Log ("-"*60)
		ForEach($rec in $data) {			
		
			# Retrieve data from SQL record
			$PND_NAME = Reval_Parm $rec.NAME
			$PND_SAMACCOUNTNAME= Reval_Parm $rec.SAMACCOUNTNAME
			$PND_DN = Reval_Parm $rec.DN
			$PND_NEWOU = Reval_Parm $rec.NEWOU
			Move_ADObject $PND_DN $PND_NEWOU			
						
		}			
	} else {
		Echo-Log "No records found."
	}

	# ------------------------------------------------------------------------------
	Echo-Log ("-"*60)	
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log "Proposed changes found in SQL result    : $Global:Changes_Proposed"
	Echo-Log "Changes committed to Active Directory   : $Global:Changes_Committed"
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log ("-"*60)	
	Echo-Log "Closing SQL connection."
	Remove-SQLconnection $SQLconn
	return $ErrorVal
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Move_External_Users_From_PND-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

[void](Move_AD_Accounts)

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

Close-LogSystem

$computername = $Env:computername
$SendFrom = "Secdump PS Scripts Active Directory <$computername@vdlnedcar.nl>"

$MainTitle = "ERS PS Scripts Move external accounts in AD."
if ($Global:Changes_Committed -ne 0) {
	$Title = "$MainTitle [$Global:Changes_Committed changes committed to AD]"
} else {
	$Title = "$MainTitle [No changes commited to AD]"
}

$computername = $Env:computername
$SendFrom = "ERS PS Scripts Active Directory <$computername@vdlnedcar.nl>"
$SendTo = "events@vdlnedcar.nl"

Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title