# ---------------------------------------------------------
# Create_Users_from_PND
#
# Marcel Jussen
# 10-04-2017
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

$Global:SMTPRelayAddress = "mail.vdlnedcar.nl"

# ---------------------------------------------------------
Import-Module VNB_PSLib
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
Function Create-NCUserAccount {
	param (
		$UserParameters
	) 
			
	$Username = $UserParameters.Username
	if($Global:DEBUG) {
		Echo-Log "** Debug: Creating $Username in AD"
		return
		
	} 
	$Result = Get-ADUserDN $Username
	if ($Result -eq $null) {
        
		# Check Username with pattern match regex
        $NUIDCheck = $($Username -match '[a-z][a-z]\d\d\d\d\d')
        $QUIDCheck = $($Username -match '[a-z]\d\d\d\d\d\d')
        $EUIDCheck = $($Username -match '[a-z][a-z]E\d\d\d\d')
        
        if($NUIDCHeck -or $QUIDCheck -or $EUIDCheck) {
            Echo-Log "$Username : Creating user account: $Username"
            $NotNew = $false
            $LDAP = "LDAP://"+ $UserParameters.UserDN
		
            # Connect to the OU where the account must be made		
            $objOU=[ADSI]($LDAP)
            $userPrincipalname = ($Username + "@" + $UserParameters.UserDNSname)
		
            # And start making the account
            # Start with required information
            $objUser= $objOU.Create("user", "CN=" + $Username)						
            $objUser.Put("userPrincipalname", $userPrincipalname )
            $objUser.Put("sAMAccountName", $Username )			
		
            # Set personal info
            Echo-Log "$Username : define properties for user object."
            Echo-Log "$Username : Firstname: $($UserParameters.Firstname)"
            if($UserParameters.Firstname.length -gt 0) { $objUser.Put("givenName", $($UserParameters.Firstname)) }		
            Echo-Log "$Username : Lastname: $($UserParameters.Lastname)"
            if($UserParameters.Lastname.length -gt 0) { $objUser.Put("sn", $($UserParameters.Lastname)) }
            Echo-Log "$Username : Displayname: $($UserParameters.Displayname)"
            if($UserParameters.Displayname.length -gt 0) { $objUser.Put("displayname", $UserParameters.Displayname) }
		
            Echo-Log "$Username : Department: $($UserParameters.Department)"
            if($UserParameters.Department.length -gt 0) { $objUser.Put("Department", $($UserParameters.Department)) }
            Echo-Log "$Username : Extension: $($UserParameters.Extension)"
            if($UserParameters.Extension.length -gt 0) { $objUser.Put("telephoneNumber", $($UserParameters.Extension)) }
            Echo-Log "$Username : MobilePhone: $($UserParameters.MobilePhone)"
            if($UserParameters.MobilePhone.length -gt 0) { $objUser.Put("mobile", $($UserParameters.MobilePhone)) }
            Echo-Log "$Username : Fax: $($UserParameters.Fax)"
            if($UserParameters.Fax.length -gt 0) { $objUser.Put("facsimileTelephoneNumber", $($UserParameters.Fax)) }
            Echo-Log "$Username : Company: $($UserParameters.UserCompany)"
            if($UserParameters.UserCompany.length -gt 0) { $objUser.Put("Company", $($UserParameters.UserCompany)) } 
            Echo-Log "$Username : Title: $($UserParameters.Title)"
            if($UserParameters.Title.length -gt 0) { $objUser.Put("Title", $($UserParameters.Title)) } 
		
            # Commit to AD
            Echo-Log "$Username : commit user object to active directory."
            $objUser.SetInfo()
		
            # Wait 15 seconds so all the domain controllers are aware of the new account.
            Start-Sleep -s 15
		
            # Add user to default domain groups
            $LDAP = Get-ADUserDN $Username
            if ($LDAP -ne $null) { 
                # The new account is confirmed to exist.		
                Echo-Log "$Username : account was created successfully. Adding account to default domain groups."			
                $Global:Changes_Committed++
				
                # Default Internet weer verwijderd d.d. 10-1-2014 iov. R.Hofman via M.v.Dongen
                # $DomainGroup = "LDAP://CN=Internet,OU=Groups,OU=NEDCAR,DC=nedcar,DC=nl"
                # Add-UserToDomainGroup $DomainGroup $LDAP
				
				# Check if account is an E account
                $UIDCheck = $Username -match '[a-z][a-z]E\d\d\d\d'
		
                # Standaard lid van XMPP Openfire op VS054
                $DomainGroup = "LDAP://CN=Openfire-Users,OU=Users_Groups,OU=C-LAN,DC=nedcar,DC=nl"
                Echo-Log "$Username : group: $DomainGroup"
                Add-UserToDomainGroup $DomainGroup $LDAP
			
                # Toegang tot Citrix XenApp d.d. 3-12-2014
				if($UIDCheck) {
					Echo-Log "$Username : Not added to XENAPP Desktop access group"
                } else {
                	$DomainGroup = "LDAP://CN=FCT-XenApp-VDLNedcar-Desktop,OU=FCT-Groups,OU=XenApp-User-Groups,OU=XenApp-Groups,OU=XenApp,DC=nedcar,DC=nl"
                	Echo-Log "$Username : group: $DomainGroup"
                	Add-UserToDomainGroup $DomainGroup $LDAP
				}
            
                # Toegang tot WEBIso d.d. 8-1-2016                
                if($UIDCheck) {
                    Echo-Log "$Username : Not added to WEBISO access group"
                } else {
                    $DomainGroup = "LDAP://CN=WebISO_Acces,OU=Groups,OU=NEDCAR,DC=nedcar,DC=nl"
                    Echo-Log "$Username : group: $DomainGroup"
                    Add-UserToDomainGroup $DomainGroup $LDAP    
                }            			
            } 
        } else {
            Echo-Log "ERROR: The user account '$Username' does not adhere to company UID naming rules."    
        }
    } else {
        Echo-Log "ERROR: User account $Username already exists."
        $NotNew = $true
    }
		
	# Search new account 
	$LDAP = Get-ADUserDN $Username
	$Result = $LDAP		
	if ($Result -ne $null) { 			
		# Only change account parameters if the account is new
		if($NotNew -eq $false) {
			Echo-Log "$Username : Setting default user account parameters."
			# Set default password
			$pwd = "nedcar"
			Echo-Log "$Username : set password value."
			Set-ADAccountPwd $LDAP $pwd
		
			# Set change password at next logon
			Echo-Log "$Username : set change password at next logon."
			Set-ADAccountChngPwdAtNextLogon $LDAP
	
			# enable the account and set the description field.
			Echo-Log "$Username : enable user account."
			Enable-ADAccountStatus $LDAP						
		}
	} else {
		Echo-Log "ERROR: The account $Username was not created successfully."
	}
	
	return $result
} 

#
# Create Citrix profile home folder
#
Function Create-NCCitrixHome {
	param (
		$UserParameters
	)
	#############################
	# Disabled d.d. 21-07-2015  #
	#############################
	return

	$Username = $UserParameters.Username
	if($Global:DEBUG) {
		Echo-Log "** Debug: Creating Citrix profile for $Username"
		return
	}	
	
	$Result = Get-ADUserDN $Username
	if ($Result -ne $null) {		
		$UserCitrixpath = ($UserParameters.CitrixUserProfilePath + "\" + $Username)
		
		if(Test-DirExists($UserCitrixpath)) {
			Echo-Log "ERROR: The Citrix path $UserCitrixpath for user $Username already exists."
		} else {
			Echo-Log "$Username : Creating Citrix drive $UserCitrixpath"
			md -Path $UserCitrixpath
			
			if(Test-DirExists($UserCitrixpath)) {			
				$DefCtxProfile = $UserParameters.CitrixDefaultProfile + "\*"
				Echo-Log "$Username : Copying default Citrix profile to $UserCitrixpath"
				Copy-Item $DefCtxProfile $UserCitrixpath -Recurse -Force -ErrorAction SilentlyContinue
			} else {
				Echo-Log "ERROR: The path $UserCitrixpath for user $Username was not successfully created."
			}
		}		
		
	}
}

Function Create-Folder($path) {	
	if(!(Test-DirExists $path)) { 
		Echo-Log "$Username : Creating folder $path"
		[Void](md -Path $Path)
	}
}

#
# Create User home directory
#
Function Create-NCUserHome {
	param (
		$UserParameters
	)
	
	$Username = $UserParameters.Username
	$Username = $Username.ToUpper()
	
	if($Global:DEBUG) {
		Echo-Log "** Debug: Creating home for $Username"
		return
	}	
	
	$Result = Get-ADUserDN $Username
	if ($Result -ne $null) {		
		$Userhomepath = ($UserParameters.Homepath + "\" + $Username)
		
		if(Test-DirExists($Userhomepath)) {
			Echo-Log "ERROR: The home path $Userhomepath for user $Username already exists."
			return -1
		} else {
			Echo-Log "$Username : Creating home drive $Userhomepath for user $Username"
			[void](md -Path $Userhomepath)
		}
		
		if(Test-DirExists($Userhomepath)) {						
		
			$acl = get-acl -path $Userhomepath
			$Access = $acl.AccessToString
			$Access = $Access.ToUpper()
			
			if ($Access.Contains($Username)) { 
				Echo-Log "ERROR: ACL on $Userhomepath already contains permission for user $Username"
			} else { 
				Echo-Log "$Username : Adding Modify ACL for user $Username on $Userhomepath"
				$permission = "$Username","Modify","ContainerInherit,ObjectInherit","None","Allow"
				$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
				$acl.SetAccessRule($accessRule)
				$acl | Set-Acl $Userhomepath 
			}
			
			Echo-Log "$Username : Creating subfolders in user home."
			$HomeSubFolders = @('Profile', 'My Documents', 'My Downloads', 'My Pictures', 'Windows', 'Windows\SAP')
			ForEach($SubFolder in $HomeSubFolders) { 
				$SubPath = "$Userhomepath\$SubFolder"
				Create-Folder($SubPath)			
			}									
			
			# SAPLOGON.INI
			$SAPConfigFolder = "$Userhomepath\Windows\SAP"
			$temp = Test-DirExists $SAPConfigFolder
			if ($temp -eq $true) {
				Echo-Log "$Username : Copy default SAP logon $SAP_LOGON to $SAPConfigFolder"
				$SAP_LOGON = $UserParameters.SAP_LOGON + "\*"
				Copy-Item $SAP_LOGON $SAPConfigFolder -Recurse -Force -ErrorAction SilentlyContinue
			} else {
				Echo-Log "ERROR: Could not copy default SAP logon to $SAPConfigFolder"			
			}			
			
		} else {
			Echo-Log "ERROR: The home path $Userhomepath for user $Username was not successfully created."
		}				
	}	
}

#
# Query SEDCUMP for list of new AD accounts to create.
#
Function Create-NCADAccounts {
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
	$query = "select * from vw_PND_NEW_AD_ACCOUNTS"
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
			$ISP_REG_NR = Reval_Parm $rec.ISP_REG_NR
			$REG_NR_LEAD = Reval_Parm $rec.REG_NR_LEAD			
			$ISP_USERID = Reval_Parm $rec.ISP_USERID			
			$USER_DNS_DOMAINNAME = Reval_Parm $rec.USER_DNS_DOMAINNAME
			$USER_OU_DN = Reval_Parm $rec.USER_OU_DN
			
			$ISP_FIRST_NAME = Reval_Parm $rec.ISP_FIRST_NAME
			$ISP_LAST_NAME = Reval_Parm $rec.ISP_LAST_NAME
			
			#
			# The composition of the display name is determined in SQL. Not here.
			#
			$ISP_DISPLAYNAME = Reval_Parm $rec.DISPLAYN
			
			$USER_COMPANY = Reval_Parm $rec.USER_COMPANY			
			$ISP_DEPARTMENT_NAME = Reval_Parm $rec.ISP_DEPARTMENT_NAME
			$DEPARTMENT_NR = Reval_Parm $rec.DEPARTMENT_NR
			$ISP_FUNCTION = Reval_Parm $rec.ISP_FUNCTION
			
			$ISP_EMAIL = Reval_Parm $rec.ISP_EMAIL			
			$ISP_EXTENSION = Reval_Parm $rec.ISP_EXTENSION
			$ISP_GSM = Reval_Parm $rec.ISP_GSM
			$ISP_FAX = Reval_Parm $rec.ISP_FAX
			$ISP_EMAIL_DISTRIBUTED = Reval_Parm $rec.ISP_EMAIL_DISTRIBUTED
			
			#
			# This data is set in SQL table dbo.AD_PND_Users
			#
			$USER_DATA_PATH = Reval_Parm $rec.USER_DATA_PATH			
			$USER_SAP_INI = Reval_Parm $rec.USER_SAP_INI

			# Disabled d.d. 21-07-2015
			# $USER_CTX_PATH = Reval_Parm $rec.USER_CTX_PATH
			# $USER_CTX_DEF = Reval_Parm $rec.USER_CTX_DEF
											
			$Parameters = @{
				UserDomain  = $UserDomain
				UserDNSname = $USER_DNS_DOMAINNAME
				UserCompany = $USER_COMPANY
				UserDN		= $USER_OU_DN
				Username 	= $ISP_USERID
				Firstname   = $ISP_FIRST_NAME
				Lastname	= $ISP_LAST_NAME
				Displayname = $ISP_DISPLAYNAME
				Department  = "($DEPARTMENT_NR) $ISP_DEPARTMENT_NAME"
				Title       = $ISP_FUNCTION
				Extension   = $ISP_EXTENSION
				MobilePhone = $ISP_GSM
				Fax         = $ISP_FAX	
				EmailPrim   = $ISP_EMAIL				
				EmailDB     = ''				
				Homepath    = $USER_DATA_PATH
				CitrixUserProfilePath  = $USER_CTX_PATH
				CitrixDefaultProfile  = $USER_CTX_DEF
				SAP_LOGON   = $USER_SAP_INI
			}
			
			Echo-Log ("-"*60)
			Echo-Log "$($Parameters.Username) : Compoundname [$($Parameters.Displayname)]"
			# Create a domain account, fill account fields and add to default domain groups
			[Void](Create-NCUserAccount $Parameters)
			
			# Create a home directory with default folders and files (ex. SAP logon)
			[Void](Create-NCUserHome $Parameters)
											
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
		
	
		# Retrieve latest domain user object count
		$domainusercount = (get-aduser –filter * ).count
	
		# Retieve previous domain user count
		$query = "select top 1 * from VNB_PND_HISTORY_CREATE_USERS ORDER BY POLDATETIME DESC"
		$data = Query-SQL $query $SQLconn
	
		# Update statistics
		$Total_Users_Previous = $data.Total_Users_New
		$Total_Users_New = $domainusercount

		$query = "INSERT INTO [dbo].[VNB_PND_HISTORY_CREATE_USERS] ([Systemname],[Domainname],[UID],[Poldatetime],[Changes_Proposed],[Changes_Committed],[Total_Users_New],[Total_Users_Previous])" + `
			"VALUES ('" + `
			$ENV:COMPUTERNAME + "','" + `
			$ENV:USERDOMAIN + "'," + `
			"NEWID()," + `
			"Getdate()," + `
			"$($ChP), $($ChC),$($Total_Users_New),$($Total_Users_Previous))"
		$data = Query-SQL $query $SQLconn
	}	
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
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Create_Users_From_ERS-$cdtime"
$GlobLog = New-LogFile -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

[void](Create-NCADAccounts)

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if($Global:DEBUG) {
	Echo-Log "** Debug: Sending resulting log as a mail message."
}

Close-LogSystem

$MainTitle = "ERS: Create Active Directory accounts."
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