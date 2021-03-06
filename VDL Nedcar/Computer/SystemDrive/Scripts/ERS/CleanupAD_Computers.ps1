# ---------------------------------------------------------
#
# Marcel Jussen
# 08-09-2016
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$Global:Chg_Disable_Proposed = 0
$Global:Chg_Disable_Comitted = 0
$Global:Chg_Delete_Proposed = 0
$Global:Chg_Delete_Comitted = 0

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
	if($VarType.Fullname -eq 'System.DBNull') { $Parm = "" }
	if($Parm -ne $null) { 
		$VarType = $Parm.GetType()
		if($VarType -eq 'System.String') { $Parm = $Parm.trim() }
	}
	Return $Parm
} 

Function Remove-ComputerAccount {
	param (
		[string]$Systemname,
		[string]$DN
	) 
	
	if([string]::IsNullOrEmpty($Systemname)) { return $null }
	if([string]::IsNullOrEmpty($DN)) { return $null }
	
	$result = $false					
	$Disabled = Get-AD-Account-DisabledStatus $DN
	if ($Disabled) {
		Echo-Log "Removing computer account: $Systemname"
		if(!$Global:DEBUG) {
			$result = Remove-ADAccount $DN
		} 		
	} else {
		Echo-Log "ERROR: $Systemname was not disabled."	
	}
	
	return $result
} 

Function Update-DeleteRecord {
	param (
		[string] $Systemname,
		[datetime] $LastLogon,
		[string] $DN
	)
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}
	
	# Execute view from SECDUMP.
	$query = "select Systemname from VNB_CLEANUP_CLIENTS where Systemname = '$Systemname'"
	$data = Query-SQL $query $SQLconn
	if($data) {
		Echo-Log "Cleanup record for $Systemname was found."
		$Disabled = Get-AD-Account-DisabledStatus $DN
		if($Disabled) {
			if(!$Global:DEBUG) {
				$query = "update VNB_CLEANUP_CLIENTS Set DateDeleted = Getdate() where Systemname = '$Systemname'"
				$data = Query-SQL $query $SQLconn
				Echo-Log "Updated delete information in cleanup record."
			} else {
				Echo-Log "DEBUG: Updated delete information in cleanup record."
			}
		} else {
			Echo-Log "ERROR: Client $Systemname is not disabled"
		}
	} else {
		Echo-Log "Cleanup record for $Systemname was not found. Cannot update delete information."
	}
	
	Remove-SQLconnection $SQLconn
}

Function Update-DisableRecord {
	param (
		[string] $Systemname,
		[datetime] $LastLogon,
		[string] $DN
	)
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}
	
	# Execute view from SECDUMP.
	$query = "select Systemname from VNB_CLEANUP_CLIENTS where Systemname = '$Systemname'"
	$data = Query-SQL $query $SQLconn
	if(!$data) {
		if(!$Global:DEBUG) {
			Echo-Log "Insert cleanup record for $Systemname"
			$query = "insert into VNB_CLEANUP_CLIENTS (Systemname, LastLogon, DN, DateDisabled) values ('$Systemname', '$LastLogon', '$DN', Getdate())"		
			$data = Query-SQL $query $SQLconn
		} else {
			Echo-Log "DEBUG: Insert cleanup record for $Systemname"
		}
	}
	
	Remove-SQLconnection $SQLconn
}

#
# Take hashlist from view vw_ClientsAD_Cleanup_Disable with old computers and disable their accounts in AD.
# Log the action in table VNB_CLEANUP_CLIENTS
#
Function Disable-Computers {
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

	# Init return value
	$ErrorVal = 0

    if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	
	#
	# View vw_ClientsAD_Cleanup_Disable lists computers not logged on over 180 days and disable date is null and delete date is null
	#
	$query = "select * from vw_ClientsAD_Cleanup_Disable"
	$data = Query-SQL $query $SQLconn
	if($data) { 
		$reccount = $data.Count	
		ForEach($rec in $data) {	
			# Record date
			$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
		
			$Global:Chg_Disable_Proposed++
			$Systemname = Reval_Parm $rec.Systemname
			$LastLogon = Reval_Parm $rec.LastLogon
			$DaysSinceLastLogon = Reval_Parm $rec.DaysSinceLastLogon
			$DN = Reval_Parm $rec.DN
						
			Echo-Log "Disable client computer: $Systemname ($DaysSinceLastLogon days since last logon)"			
			$Disabled = Get-AD-Account-DisabledStatus $DN
			if($Disabled) {				
				Echo-Log "Computer object was already disabled in Active Directory."
				# Update table
				Update-DisableRecord $Systemname $LastLogon $DN
				# Update computer object description field.						
				Set-ADAccountDescription -path $DN -description "* Automatically disabled on $cdtime *"
			} else {
				# Disable computer object
				if(!$Global:DEBUG) {
					$Disabled = Disable-AD-Account $DN								
					if($Disabled) { 									
						$Global:Chg_Disable_Comitted++
						Echo-Log "Successfully disabled object: $DN"
					
						# Register disable in SECDUMP table
						Update-DisableRecord $Systemname $LastLogon $DN
					
						# Update computer object description field.						
						Set-ADAccountDescription -path $DN -description "* Automatically disabled on $cdtime *"
					} else {
						Echo-Log "ERROR: Object was not disabled: $DN"
					}
				} else {
					Echo-Log "DEBUG: disabled object: $DN"
				}
			}
		}					
	} else {
		Echo-Log "No computer objects found to disable."
	}
	
    return $ErrorVal
}

#
# Take hashlist from view vw_ClientsAD_Cleanup_Delete with old and disabled computers and delete their accounts in AD.
# Log the action in table VNB_CLEANUP_CLIENTS
#
Function Delete-Computers {
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

	# Init return value
	$ErrorVal = 0	

    if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
			
	#
	# View vw_ClientsAD_Cleanup_Delete lists computer who were disabled 30 days ago (datedisabled <> null) and datedeleted is null
	#
	$query = "select * from vw_ClientsAD_Cleanup_Delete"
	$data = Query-SQL $query $SQLconn
	if($data) { 
		$reccount = $data.Count			
		ForEach($rec in $data) {	
			$Global:Chg_Delete_Proposed++
			$Systemname = Reval_Parm $rec.Systemname
			$DN = Reval_Parm $rec.DN
			
			$DateDisabled = Reval_Parm $rec.DateDisabled
			$DateDeleted = Reval_Parm $rec.DateDeleted
			$DaysSinceDisabled = Reval_Parm $rec.DaysSinceDisabled
			$LastLogon = Reval_Parm $rec.LastLogon
			
			Echo-Log "Delete client computer: $Systemname ($DaysSinceDisabled days since object disable)"
			
			$Disabled = Get-AD-Account-DisabledStatus $DN
			if($Disabled) {				
				if(!$Global:DEBUG) {
					# Delete computer object				
					$Deleted = Remove-ComputerAccount $Systemname $DN
					$Status = Get-ADObjectDN -ObjectName $Systemname -Filter "(&(objectCategory=Computer)(name=$Systemname))"
					if($Status -eq $null) { 
						$Global:Chg_Delete_Comitted++
						Echo-Log "Successfully deleted object: $DN"
					
						# Register disable in SECDUMP table
						Update-DeleteRecord $Systemname $LastLogon $DN					
					} else {
						Echo-Log "ERROR: Object was not deleted: $DN"
					}
				} else {
					Echo-Log "DEBUG: Deleted object: $DN"
				}
			} else {
				Echo-Log "ERROR: This computer was not disabled in AD."
				Echo-Log "ERROR: Skipping this computer."
			}
		}					
	} else {
		Echo-Log "No computer objects found to delete."
	}
	
	return $ErrorVal
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-CleanupAD_Computers-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

Echo-Log ("-"*60)
Echo-Log "Disable computer that have not logged on to the domain in 180 days."
[void](Disable-Computers)

Echo-Log ("-"*60)
if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
Echo-Log "Proposed computers to disable : $Global:Chg_Disable_Proposed"
Echo-Log "Actual computers disabled     : $Global:Chg_Disable_Comitted"
Echo-Log ("-"*60)

[void](Delete-Computers)

Echo-Log ("-"*60)
if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
Echo-Log "Proposed computers to delete  : $Global:Chg_Delete_Proposed"
Echo-Log "Actual computers deleteded    : $Global:Chg_Delete_Comitted"
Echo-Log ("-"*60)	
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
$query = "INSERT INTO [dbo].[VNB_PND_HISTORY_MAINTAIN_COMPUTERS] ([Systemname],[Domainname],[Poldatetime],[Chg_Disable_Proposed],[Chg_Disable_Comitted],[Chg_Delete_Proposed],[Chg_Delete_Comitted])" + `
			"VALUES ('" + $ENV:COMPUTERNAME + "','" + $ENV:USERDOMAIN + "'," + `
			"Getdate(),$($Global:Chg_Disable_Proposed),$($Global:Chg_Disable_Comitted),$($Global:Chg_Delete_Proposed),$($Global:Chg_Delete_Comitted))"
$data = Query-SQL $query $SQLconn

Close-LogSystem

$MainTitle = "ERS: Cleanup computer objects from Active Directory."
if (($Global:Chg_Disable_Comitted -ne 0) -or ($Global:Chg_Delete_Comitted -ne 0)) {
	$Title = "$MainTitle" 		
	
	$computername = $Env:computername
	$SendFrom = "Secdump PS Scripts Active Directory <$computername@vdlnedcar.nl>"
	
	$SendTo = "events@vdlnedcar.nl"	
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
	
	$SendTo = "helpdesk@vdlnedcar.nl"	
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
}
