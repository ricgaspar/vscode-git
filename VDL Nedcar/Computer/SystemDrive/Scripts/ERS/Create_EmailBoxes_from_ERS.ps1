# ---------------------------------------------------------
# Create_Exchange_Mailboxes from ERS.
#
# Marcel Jussen
# 10-04-2017
# ---------------------------------------------------------
#requires -Version 2

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $false

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


#
# Return the name of the Exch database with the least number of mailboxes
# Returns null if all mailboxes reach their maximum mailbox count.
#
Function Query_Preferred_ExchangeDB {
	$udl = Read-UDL-ConnectionString -UDLFile C:\Scripts\Utils\secdump.udl
	$hash = Invoke-UDL-SQL -connectionstring $udl -query "select [database],Mailbox_count from vw_Exchange_Preferred_DB"			
	return $hash
} 

# 
# Change the count of the SECDUMP Exchange database statistics for the newly created mailbox
#
Function Update_DB_Stats {
	param (
		[string]$database,
		[int]$count
	)	
	
	if($Global:DEBUG) {
		Echo-Log "** Debug: Updating Exchang DB statistics"
		return
	}
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { return $null }
	
	$Query = "update exch_dbstats set Mailbox_count = $count where [DATABASE] = '$database'"
	$data = Query-SQL $query $SQLconn
	
	$Query = "update exch_dbstats set poldatetime = GetDate() where [DATABASE] = '$database'"
	$data = Query-SQL $query $SQLconn
	
	Remove-SQLconnection $SQLconn	
}

#
# Create a new Exchange mailbox
#
Function Create_User_MailBox {
	param (
		$UserParameters		
	)
	
	$ExchManServer="vs090.nedcar.nl"
	$TestWS = Test-WSMan -ComputerName $ExchManServer
	if($TestWS.ProductVendor -ne "Microsoft Corporation") {	
		Echo-Log "Remote Powershell execution is not possible. Cannot connect to WinRM on $ExchManServer"		
		Return -1
	}
	
	$ADInfo = Get-NetbiosDomain
	$Username = $UserParameters.Username	
	$UserEmail = $UserParameters.EmailPrim
	if($Global:DEBUG) {
		Echo-Log "** Debug: Creating Exchange mailbox $UserEmail for $Username"		
	}
	
	# Does this user exist in AD?
	$LDAP = Search-AD-User $Username
	$LDAP = $LDAP.replace("LDAP://","")
	if ($LDAP -ne $null) {
	
		# Check if this user account already has a mailbox
		$MBox = Get-Mailbox -Identity $LDAP -ErrorAction SilentlyContinue
		if($MBox -ne $null) {
			$dbfound = $Mbox.database
			$smtpfound = $MBox.PrimarySmtpAddress
			Echo-Log "ERROR: $Username already has mailbox [$smtpfound] in database [$dbfound]"			
			return -1

		} else {            
            # Check if the email address already is in use.
            $rec = Get-Recipient -Identity $UserEmail -ErrorAction SilentlyContinue            
            If($rec -ne $null) {
                Echo-Log "ERROR: [$UserEmail] is bound to mailbox [$rec]. Cannot create mailbox."			
			    return -1
            }

			# Query Exch database statistics for the preferred Exch mail database			
			$exchdb = Query_Preferred_ExchangeDB
			if ($exchdb -ne $null) {
				$Preferred_DB_name = $exchdb.database
				$DB_Count = $exchdb.Mailbox_count
				Echo-Log "Exchange DB: [$Preferred_DB_name]"
				$UserParameters.EmailDB = $Preferred_DB_name
				
				# Create the mailbox for this user
				# See http://technet.microsoft.com/en-us/library/aa998251.aspx
				#
				# We define the Primary SMTP address which autmatically disabled the naming rule
				#
				if($Global:DEBUG -eq $false) {					
					# Enable-Mailbox -Identity $LDAP -Alias $Username -PrimarySmtpAddress $UserEmail -Database $Preferred_DB_name -RetentionPolicy 'Default Archive and Retention Policy' -AddressBookPolicy 'Addresbook Policy'
					Enable-Mailbox -Identity $LDAP -Alias $Username -PrimarySmtpAddress $UserEmail -Database $Preferred_DB_name -AddressBookPolicy 'Addresbook Policy'
					
					# Set ActiveSync option to disabled.
					Set-CASMailbox -Identity $LDAP -ActiveSyncEnabled:$False					
										
					# Log newly created account
					$Global:Changes_Committed++
					
					$DB_Count++									
					Update_DB_Stats $Preferred_DB_name $DB_Count									
				}								
																
			} else {
				Echo-Log "ERROR: There is no Exchange database available for this mailbox."
				Echo-Log "SQL view [vw_Exchange_Preferred_DB] returned an empty table."
				Echo-Log "This indicates that the Exchange databases have reached their max mailbox counts."
				Echo-Log "Check table [Exchange_Default_DB] for available databases and max mailbox counts."
			}
		}
	} else {
		Echo-Log "The account $Username cannot be found in AD."
	}
}

#
# Query SEDCUMP for list of new AD accounts to create
#
Function Create_Exchange_Accounts {
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

	# Query lists all new accounts with status ISP_VERIFIED=Y and ISP_AD_INSERT=Y
	# Query is extended with account create information.
	$query = "select * from vw_PND_NEW_EXCHANGE_ACCOUNTS"
	Echo-Log "Parse query: $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 } 
		Echo-Log "Number of records returned: $reccount"		
		Echo-Log ("-"*60)
		ForEach($rec in $data) {			
		
			# Retrieve data from SQL record			
			$ISP_USERID = Reval_Parm $rec.ISP_USERID												
			$ISP_FIRST_NAME = Reval_Parm $rec.ISP_FIRST_NAME
			$ISP_LAST_NAME = Reval_Parm $rec.ISP_LAST_NAME
			$ISP_DISPLAYNAME = Reval_Parm $rec.DISPLAYNAME					
			
			$ISP_EMAIL = Reval_Parm $rec.ISP_EMAIL			
			$ISP_EMAIL_DISTRIBUTED = Reval_Parm $rec.ISP_EMAIL_DISTRIBUTED
			
			$USER_OU_DN = Reval_Parm $rec.DN
									
			Echo-Log "($USER_OU_DN) $ISP_DISPLAYNAME"
			
			$Parameters = @{
				UserDomain  = $UserDomain			
				UserDN		= $USER_OU_DN
				Username 	= $ISP_USERID
				Firstname   = $ISP_FIRST_NAME
				Lastname	= $ISP_LAST_NAME
				Displayname = $ISP_DISPLAYNAME				
				EmailPrim   = $ISP_EMAIL				
				EmailDB     = ""								
			}						
			
			# Create a mailbox in Exchange for this user.
			if($ISP_EMAIL_DISTRIBUTED -eq 'Y') {				
				if($ISP_EMAIL.length -ne 0) {
					$Global:Changes_Proposed++
					Echo-Log "Email address to create: $ISP_EMAIL"
					[Void](Create_User_MailBox $Parameters)						
				} else {
					Echo-Log "Mail adres field is empty. No mailbox created."
				}
			} 						
		}			
	} else {
		Echo-Log "No records found."
	}	

	# ------------------------------------------------------------------------------
	Echo-Log ("-"*60)	
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	$ChP = $Global:Changes_Proposed
	$ChC = $Global:Changes_Committed
	Echo-Log "Proposed changes found in SQL result : $($ChP)"
	Echo-Log "Changes committed to Exchange        : $($ChC)"
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

    $query = "select top 1 * from VNB_PND_HISTORY_CREATE_MAILBOXES ORDER BY POLDATETIME DESC"
	$data = Query-SQL $query $SQLconn

    $MailboxStats = Get-MailboxStatistics –Server "vs091.nedcar.nl" -Verbose:$false 
    $vs091 = $MailboxStats.Count

    $MailboxStats = Get-MailboxStatistics –Server "vs094.nedcar.nl" -Verbose:$false 
    $vs094 = $MailboxStats.Count
    $total = $vs091 + $vs094

	$Total_Mailboxes_Previous = $data.Total_Mailboxes_New
	$Total_Mailboxes_New = $total
	
	$query = "INSERT INTO [dbo].[VNB_PND_HISTORY_CREATE_MAILBOXES] ([Systemname],[Domainname],[UID],[Poldatetime],[Changes_Proposed],[Changes_Committed],[Total_Mailboxes_New],[Total_Mailboxes_Previous])" + `
			"VALUES ('" + `
			$ENV:COMPUTERNAME + "','" + `
			$ENV:USERDOMAIN + "'," + `
			"NEWID(), Getdate(), $($ChP), $($ChC), $($Total_Mailboxes_New), $($Total_Mailboxes_Previous))"
	$data = Query-SQL $query $SQLconn
	
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

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
Connect-ExchangeServer -auto

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Create_Exchange_Mailboxes_From_ERS-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

[void](Create_Exchange_Accounts)

# $ISP_USERID = "PV38411"
# $ISP_EMAIL = "p.vermeulen@vdlnedcar.nl"
# $Parameters = @{
#				UserDomain  = $UserDomain			
#				UserDN		= $USER_OU_DN
#				Username 	= $ISP_USERID
#				Firstname   = $ISP_FIRST_NAME
#				Lastname	= $ISP_LAST_NAME
#				Displayname = $ISP_DISPLAYNAME				
#				EmailPrim   = $ISP_EMAIL				
#				EmailDB     = ""								
#			}
# [Void](Create_User_MailBox $Parameters)	

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if ($Global:Changes_Committed -ne 0) {
	$Title = "Create emailboxes from ERS. $cdtime ($Global:Changes_Committed changes committed to Exchange)" 	
} else {
	$Title = "Create emailboxes from ERS. $cdtime (No changes committed to Exchange)" 
}

$computername = $Env:computername
$SendFrom = "ERS PS Scripts Exchange<$computername@vdlnedcar.nl>"

$SendTo = "events@vdlnedcar.nl"
Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title

$SendTo = "helpdesk@vdlnedcar.nl"
Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title