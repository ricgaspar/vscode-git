# ---------------------------------------------------------
# Create_Users_from_PND
#
# Marcel Jussen
# 16-11-2017
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

$Global:SMTPRelayAddress = "mail.vdlnedcar.nl"

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

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

#
# Create a user account in the domain
# and define user properties
#
Function Update-NCUserAccount {
	param (
		$UserParameters
	)

	$Username = $UserParameters.Username
	if($Global:DEBUG) {
		Echo-Log "** Debug: Updating $Username in AD"
    }

    $DomainGroup = "LDAP://CN=Security_PwdSettings_HighSecurity_Users,OU=Security_Groups,OU=Groups,OU=NEDCAR,DC=nedcar,DC=nl"
	$Result = Get-ADUserDN $Username
	if ($Result -ne $null) {

		# Check Username with pattern match regex
        $NUIDCheck = $($Username -match '[a-z][a-z]\d\d\d\d\d')
        $QUIDCheck = $($Username -match '[a-z]\d\d\d\d\d\d')
        $EUIDCheck = $($Username -match '[a-z][a-z]E\d\d\d\d')

        if($NUIDCHeck -or $QUIDCheck -or $EUIDCheck) {
            # Add user to default domain groups
            $LDAP = $Result
            if ($LDAP -ne $null) {
				# Check if account is an E account
                $UIDCheck = $Username -match '[a-z][a-z]E\d\d\d\d'
                if ($UIDCheck) {
                    Echo-Log "$Username : E accounts are not added to secure account group."
                }
                else {
                    $members = Get-DomainGroupMembers $DomainGroup
                    $present = $members -match $Username
                    if ($present) {
                        # Echo-Log "$Username is already member of the group."
                    }
                    else {
                        if ($Global:DEBUG) {
                            Echo-Log "DEBUG: Adding $Username to secure account group."
                        }
                        else {
                            Echo-Log "Adding $Username to secure account group."
                            Echo-Log "       $($UserParameters.Displayname) [$($UserParameters.Department)] [$($UserParameters.Title)]"
                            # Add-UserToDomainGroup $DomainGroup $LDAP
                            $Global:Changes_Committed++
                        }
                    }
                }
            }
        } else {
            Echo-Log "ERROR: The user account '$Username' does not adhere to company UID naming rules."
        }
    } else {
        Echo-Log "ERROR: User account $Username does not exist."
    }

	return $result
}

#
# Query SEDCUMP for list of new AD accounts to create.
#
Function Update-SecureAccounts {
	# ------------------------------------------------------------------------------
	# Connect to SQL server

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

    $query = "select * from vw_VNB_P_DOMAIN_USERS_SECURE_ACCOUNTS_UPDATES"
	Echo-Log "Parse query: $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 }
		Echo-Log "Number of records returned: $reccount"
		$Global:Changes_Proposed = $reccount

		ForEach($rec in $data) {

			#
			# Retrieve data from SQL record
			#
            $ISP_DEPARTMENT_NR = Reval_Parm $rec.ISP_DEPARTMENT_NR
            $ISP_DEPARTMENT_NAME = Reval_Parm $rec.ISP_DEPARTMENT_NAME
            $ISP_USERID = Reval_Parm $rec.ISP_USERID
            $ISP_COMPOUND_NAME = Reval_Parm $rec.ISP_COMPOUND_NAME
            $ISP_FUNCTION = Reval_Parm $rec.ISP_FUNCTION
            $SECUREID = Reval_Parm $rec.SECUREID
			$DN = Reval_Parm $rec.DN

            $Parameters = @{
                UserName    = $ISP_USERID
                UserDomain  = $UserDomain
                UserDN      = $DN
                Displayname = $ISP_COMPOUND_NAME
                Department  = "($ISP_DEPARTMENT_NR) $ISP_DEPARTMENT_NAME"
                Title       = $ISP_FUNCTION
                SECUREID    = $SECUREID
            }

            if ($SECUREID.Length -ne 0) {
                [Void](Update-NCUserAccount $Parameters)
            }
            else {
                # Echo-Log "Remove from group $($Parameters.Username) [$($Parameters.Displayname)]"
            }
		}
	} else {
		Echo-Log "No records found."
	}

	# ------------------------------------------------------------------------------
	Echo-Log ("-"*60)

	if($Global:DEBUG) {
		Echo-Log "** DEBUG mode: changes are not committed."
	} else {
		$ChP = $Global:Changes_Proposed
		$ChC = $Global:Changes_Committed
		Echo-Log "Proposed changes found in SQL result    : $($ChP)"
		Echo-Log "Changes committed to Active Directory   : $($CHC)"
	}
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

	Echo-Log ("-"*60)
	Echo-Log "Closing SQL connection."
	Remove-SQLconnection $SQLconn
	return $ErrorVal
}

# ------------------------------------------------------------------------------
# Start script
Clear-Host
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Update-SecureAccounts-$cdtime"
$GlobLog = New-LogFile -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

[void](Update-SecureAccounts)

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if($Global:DEBUG) {
	Echo-Log "** Debug: Sending resulting log as a mail message."
}

Close-LogSystem

$MainTitle = "ERS: Update secure accounts."
if ($Global:Changes_Committed -ne 0) {
	$Title = "$MainTitle [$Global:Changes_Committed changes committed to AD]"
} else {
	$Title = "$MainTitle [No changes committed to AD]"
}

$computername = $Env:computername
$SendFrom = "ERS PS Scripts Active Directory <$computername@vdlnedcar.nl>"

$SendTo = "events@vdlnedcar.nl"
Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title

$SendTo = "helpdesk@vdlnedcar.nl"
Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title