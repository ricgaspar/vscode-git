# ---------------------------------------------------------
# Change user account status from ERS to Active Directory
#
# Marcel Jussen
# 8-9-2016
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0
$Global:SQLChanges_Proposed = 0

$Global:DEBUG = $false
$Global:CurDN = $null

$Global:SMTPRelayAddress = "mail.vdlnedcar.nl"

Function ChkStringDiff {
# Compare two strings with case sensitivity and return true when they are different
	Param (
		[string]$AString,
		[string]$BString
	)
	$retval = $false
	if ($AString.Length -gt 0) {
		$AString = $AString.Trim()
		if ($BString.Length -gt 0) {			
			$BString = $BString.Trim()
			$d = [string]::Compare($AString, $BString, $False)
			$retval = ($d -ne 0) 							
		} else {
			$retval = $true
		}
	} else {
		if ($BString.Length -gt 0) { $retval = $true }
	}
	return $retval
}


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

Function Update-AccountStatus {

	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	Echo-Log ("-"*60)	
	# T-SQL Query to execute	
	# $query = "select * from vw_PND_CHANGE_ACCOUNTSTATUS"
	
	# We only want to see accounts that need to be disabled
	$query = "select * from vw_PND_CHANGE_ACCOUNTSTATUS where ISP_MUTATION_STATUS='DEACTIVATED'"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN
			$Global:Changes_Proposed++
			$SamAccountName = Reval_Parm $rec.SamAccountName
			$ISP_COMPOUND_NAME = Reval_Parm $rec.ISP_COMPOUND_NAME
			$ISP_MUTATION_STATUS = Reval_Parm $rec.ISP_MUTATION_STATUS			
			$AccountIsDisabled = Reval_Parm $rec.AccountIsDisabled
						
			$Status = 'Unchanged'
			Echo-Log ("-"*60)
			Echo-Log "$SamAccountName ($ISP_COMPOUND_NAME) - ERS Status             : $($ISP_MUTATION_STATUS)"
			Echo-Log "$SamAccountName ($ISP_COMPOUND_NAME) - Status is disabled?    : $AccountIsDisabled"
			$AccStatus = Get-ADAccountDisabledStatus $LDAP
			Echo-Log "$SamAccountName ($ISP_COMPOUND_NAME) - AD status is disabled? : $AccStatus"
			switch ($ISP_MUTATION_STATUS) 
    		{ 
        		'VERIFIED' { 										
					if($AccountIsDisabled -ne 'False') { 
						Echo-Log "Doing nothing. (re)enabling accounts is not implemented."
					# 	Echo-Log "Updating status of account $SamAccountName to Enabled."
					# 	$Status = Enable-ADAccountStatus -Path $LDAP
					#	$Global:Changes_Committed++
					} 
				} 
				
        		'DEACTIVATED' { 										
					if($AccountIsDisabled -ne 'True') { 
						if($AccStatus -ne $True) {
							Echo-Log "Updating status of account $SamAccountName to Disabled."
							$AccStatus = [bool]( Disable-ADAccountStatus -Path $LDAP )
							if($AccStatus -eq $true) { $Status = 'Disabled' }
							if($AccStatus -ne $true) { $Status = 'Enabled' }
							$Global:Changes_Committed++
						} else {
							Echo-Log "The account $SamAccountName was already disabled. There is nothing to do."
						}
					}						
				} 
				
        		'DELETED' {					
					if($SamAccountName -ne '') {
						Echo-Log "Doing nothing. Deleting of accounts is not implemented."
					#	# $Global:Changes_Committed++
						
					#	$DN = Get-ADUserDN $SamAccountName
					#	if($DN -eq $null) { 
					#		$Status = 'Not present.' 
					#	} else {
					#		$Status = 'Present.' 
					}
					# }
				} 
				
        	    default {
					Echo-Log "ERROR: The ISP Mutation status [$ISP_MUTATION_STATUS] for account $SamAccountName is not recognised."
				}
    		}	
			
			Echo-Log "New status for account $SamAccountName is now : $Status"
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	rv SQLconn
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Update-AccountStatus-from-ERS-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode : Changes are not committed." }

Update-AccountStatus

Echo-Log ("-"*60)
Echo-Log "SQL queries total proposed changes      : $Global:SQLChanges_Proposed"
Echo-Log "Actual differences proposed             : $Global:Changes_Proposed"
Echo-Log "Changes committed to Active Directory   : $Global:Changes_Committed"
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
$query = "INSERT INTO [dbo].[VNB_PND_HISTORY_MAINTAIN_USER_STATUS] ([Systemname],[Domainname],[Poldatetime],[SQLChanges_Proposed],[Changes_Proposed],[Changes_Committed])" + `
			"VALUES ('" + $ENV:COMPUTERNAME + "','" + $ENV:USERDOMAIN + "'," + `
			"Getdate(),$($Global:SQLChanges_Proposed),$($Global:Changes_Proposed),$($Global:Changes_Committed))"
$data = Query-SQL $query $SQLconn

if($Global:DEBUG) { 
	Echo-Log "** DEBUG mode: changes are not committed." 
	return	
}

Close-LogSystem

$computername = $Env:computername
$SendFrom = "ERS PS Scripts Active Directory <$computername@vdlnedcar.nl>"

$MainTitle = 'ERS: Update Active Directory user account status.'
if ($Global:Changes_Committed -ne 0) {
	$Title = "$MainTitle [$Global:Changes_Committed changes committed to AD]"
	$SendTo = "events@vdlnedcar.nl"
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
	$SendTo = "helpdesk@vdlnedcar.nl"
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
} else {
	$Title = "$MainTitle [No changes commited to AD]"
	$TempLog = $env:TEMP + "\templog.txt"
	$LogText = $Title
	$logText | Out-File -FilePath $TempLog
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
	Remove-Item -Path $TempLog -ErrorAction SilentlyContinue
}