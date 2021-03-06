# ---------------------------------------------------------
#
# Marcel Jussen
# 9-3-2015
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$Global:Chg_AccEnable_Proposed = 0
$Global:Chg_AccEnable_Comitted = 0
$Global:Chg_AccDisable_Proposed = 0
$Global:Chg_AccDisable_Comitted = 0

$Global:DEBUG = $TRUE

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
	if($VarType.Fullname -eq 'System.DBNull') { $Parm = "" }
	if($Parm -ne $null) { 
		$VarType = $Parm.GetType()
		if($VarType.Fullname -eq 'System.String') { $Parm = $Parm.trim() }
	}
	Return $Parm
} 

Function EnableAccounts {
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

	# Init return value
	$ErrorVal = 0
	
	# What is our domain.
	$UserDomain = Get-NetbiosDomain
		
	$query = "select * from VW_PND_ACCOUNTS_NOT_ENABLED"
	$data = Query-SQL $query $SQLconn
	if($data) { 
		$reccount = $data.Count	
		ForEach($rec in $data) {
			$Global:Chg_AccEnable_Proposed++
			
			$ISP_USERID = Reval_Parm $rec.ISP_USERID
			$ISP_FIRST_NAME = Reval_Parm $rec.ISP_FIRST_NAME
			$ISP_LAST_NAME = Reval_Parm $rec.ISP_LAST_NAME
			$DN =  Get-ADUserDN $ISP_USERID
			if($DN) { 
				Echo-Log "Enable account : $ISP_USERID ($ISP_FIRST_NAME $ISP_LAST_NAME)"
				Echo-Log "DN $ISP_USERID : $DN"
				
				$Status = Get-ADAccountDisabledStatus $DN				
				if($Status) {					
					if(!$Global:DEBUG) {
						Echo-Log "Enabling object: $DN"
						# $Status = Enable-AD-Account $DN
						
						$Status = Get-ADAccountDisabledStatus $DN
						if($Status -eq $False) { 
							Echo-Log "Account succesfully enabled."
							$Global:Chg_AccEnable_Comitted++ 							
							
							Echo-Log "Reset password to default value."
							# Set-AD-Account-Pwd $DN 'nedcar'
									
							Echo-Log "Set account to change password at next logon."
							# Set-AD-Account-ChngPwdAtNextLogon $DN
							
						} else {
							Echo-Log "ERROR: Account was not succesfully enabled."
						}
					} else {
						Echo-Log "DEBUG: Enabling object: $DN"
					}					
				}
				Echo-Log "Disabled status $ISP_USERID : $Status"
			} else {
				Echo-Log "ERROR: This account cannot be found in Active Directory!"
			}
		}
	}
}

Function DisableAccounts {
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

	# Init return value
	$ErrorVal = 0
	
	# What is our domain.
	$UserDomain = Get-NetbiosDomain
		
	$query = "select * from VW_PND_ACCOUNTS_NOT_DISABLED_IN_AD"
	$data = Query-SQL $query $SQLconn
	if($data) { 
		$reccount = $data.Count	
		ForEach($rec in $data) {
			$Global:Chg_AccDisable_Proposed++
			
			$ISP_USERID = Reval_Parm $rec.ISP_USERID
			$ISP_FIRST_NAME = Reval_Parm $rec.ISP_FIRST_NAME
			$ISP_LAST_NAME = Reval_Parm $rec.ISP_LAST_NAME
			$DN =  Get-ADUserDN $ISP_USERID
			if($DN) { 
				Echo-Log "Disable account : $ISP_USERID ($ISP_FIRST_NAME $ISP_LAST_NAME)"
				Echo-Log "DN $ISP_USERID : $DN"
				
				$Status = Get-ADAccountDisabledStatus $DN
				if($Status -eq $False) {					
					if(!$Global:DEBUG) {
						Echo-Log "Disabling object: $DN"
						# $Status = Disable-ADAccount $DN
						if($Status) { 
							Echo-Log "Account succesfully disabled."
							$Global:Chg_AccDisable_Comitted++ 
						} 
					} else {
						Echo-Log "DEBUG: Disabling object: $DN"
					}					
				}
				Echo-Log "Disabled status $ISP_USERID : $Status"
			} else {
				Echo-Log "ERROR: This account cannot be found in Active Directory!"
			}
		}
	}
}


Function UpdateAccountStatus {

	EnableAccounts
	DisableAccounts 
	
	# ------------------------------------------------------------------------------
	Echo-Log ("-"*60)	
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log "Proposed accounts to enable : $Global:Chg_AccEnable_Proposed"
	Echo-Log "Committed accounts to enable: $Global:Chg_AccEnable_Comitted"
	Echo-Log "Proposed accounts to disable: $Global:Chg_AccDisable_Proposed"
	Echo-Log "Committed accounts to disable: $Global:Chg_AccDisable_Comitted"
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log ("-"*60)
}


# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "ERS-ChangeAccountStatus-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

[void](UpdateAccountStatus)

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

$Title = "Change Account status"
if ($Global:Chg_AccEnable_Comitted -ne 0) {
	$Title = "$cdtime ($Global:Chg_AccEnable_Comitted user objects are enabled in AD)"
}

if ($Global:Chg_AccDisable_Comitted -ne 0) {
	$Title = "$cdtime ($Global:Chg_AccDisable_Comitted user objects are disabled in AD)"
}

if (($Global:Chg_AccEnable_Comitted -ne 0) -or ($Global:Chg_AccDisable_Comitted -ne 0)) {
	# $SendTo = "events@vdlnedcar.nl"
	$SendTo = "m.jussen@vdlnedcar.nl"
	$dnsdomain = 'vdlnedcar.nl'
	$computername = gc env:computername
	$SendFrom = "$computername@$dnsdomain"

	Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
}

