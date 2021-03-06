# ---------------------------------------------------------
# Remove users from domain, includes removal of
# - home drive
# - citrix profile
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

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $true

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

Function Remove_User_Account {
	param (
		$UserParameters
	) 
			
	$Username = $UserParameters.Username	
	$Result = Search-AD-User $Username
	if ($Result -ne $null) {	
		Echo-Log "$Username : Removing user account: $Username"
		
        $searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"","(&(objectcategory=user)(sAMAccountName=$Username))")
        $user = $searcher.findone().GetDirectoryEntry()
        $user.psbase.DeleteTree()
		
	} else {
		Echo-Log "ERROR: User account $Username does not exist."	
	}	
	
	return $result
} 

Function Remove_Citrix_Home {
	param (
		$UserParameters
	)
	
	$Username = $UserParameters.Username		
	$UserCitrixpath = ($UserParameters.CitrixUserProfilePath + "\" + $Username)
	if(Exists-Dir($UserCitrixpath)) {
		Echo-Log "$Username : Removing Citrix drive $UserCitrixpath"		
		Remove-Item $UserCitrixpath -Force -Recurse
	} else {
		Echo-Log "ERROR: The Citrix path $UserCitrixpath for user $Username does not exist."		
	}
}

Function Remove_User_Home {
	param (
		$UserParameters
	)
	
	$Userhomepath = ($UserParameters.Homepath + "\" + $Username)
	if(Exists-Dir($Userhomepath)) {
		Echo-Log "$Username : Removing home drive $Userhomepath"
		Remove-Item $Userhomepath -Force -Recurse		
	} else {
		Echo-Log "ERROR: The home path $Userhomepath for user $Username does not exist."
	}	
}

#
# Remove accounts from a list (txt) and check Secdump database for specs
#
Function Remove_Accounts_From_Domain {
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
	
	$Userlist = Get-Content D:\Scripts_Source\ERS\remove_users.txt
	foreach ($Username in $Userlist) {				
		# Query lists all AD accounts with the user name from the list
		
		$query = "select * from vw_UserAD_Maintenance where SAMAccountName=" + "'" + "$Username" + "'"
		$data = Query-SQL $query $SQLconn
		Echo-Log ("-"*60)
		if ($data -ne $null) {
			$reccount = $data.Count
			if ($reccount -eq $null) { $reccount = 1 } 
			$Global:Changes_Proposed += $reccount			
			ForEach($rec in $data) {			
		
				#
				# Retrieve data from SQL record
				#
				$ISP_USERID = Reval_Parm $rec.SamAccountName
				
				$USER_OU_DN = Reval_Parm $rec.DN
				$ISP_DISPLAYNAME = Reval_Parm $rec.DisplayName		
				$ISP_EMAIL = Reval_Parm $rec.Email	
				$DISABLED = Reval_Parm $rec.AccountIsDisabled
			
				$USER_DATA_PATH = Reval_Parm $rec.USER_DATA_PATH
				$USER_CTX_PATH = Reval_Parm $rec.USER_CTX_PATH
					
				Echo-Log "($Username) $ISP_DISPLAYNAME ($DISABLED)"
			
				$Parameters = @{
					UserDomain  = $UserDomain
					UserDN		= $USER_OU_DN
					Username 	= $ISP_USERID
					EmailPrim   = $ISP_EMAIL				
					Homepath    = $USER_DATA_PATH
					CitrixUserProfilePath  = $USER_CTX_PATH			
				}
				
				# Remove a home directory 
				[Void](Remove_User_Home $Parameters)
	
				# Remove the Citrix profile 
				[Void](Remove_Citrix_Home $Parameters)
		
				# Create a domain account, fill account fields and add to default domain groups
				[Void](Remove_User_Account $Parameters)											
			}			
		} else {
			Echo-Log "($Username) This account was not found!"
		}					
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
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Create_Users_From_ERS-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

[void](Remove_Accounts_From_Domain)

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if ($Global:Changes_Committed -ne 0) {
	$Title = "Remove AD accounts. $cdtime ($Global:Changes_Committed changes committed to AD)" 	
} else {
	$Title = "Remove AD accounts. $cdtime (No changes committed to AD)" 
}


