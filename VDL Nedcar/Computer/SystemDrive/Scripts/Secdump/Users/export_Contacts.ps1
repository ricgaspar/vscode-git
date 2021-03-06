# ---------------------------------------------------------
# Collect contact information from AD
# Marcel Jussen
# 28-11-2012
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------
cls

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($conn.state -eq "Closed") { exit }   	

$query = "delete from ContactsAD"
$data = Query-SQL $query $SQLconn

$ADSearchFilter = "(&(objectCategory=User)(objectClass=contact))"
$colProplist = "name"
$colResults = Search-AD $ADSearchFilter $colProplist

foreach($ADObj in $colResults) {
 	$Path = $ADObj.Path
	# $Path = "LDAP://CN=Marcel Jussen KPN,OU=Contacts,OU=Exchange resource users,DC=nedcar,DC=nl"
	
	if($Path -ne $null) {
		Echo-Log $Path	
	
		$account = [ADSI]$Path
		$DN = $account.DistinguishedName.Value
		$mailNickname = $account.mailNickname.Value
		$mail = $account.mail.Value
		$name = $account.name.Value
		$givenName = $account.givenName.Value
		$sn	= $account.sn.Value
		$company = $account.company.Value
		$department = $account.department.Value
		$telephoneNumber = $account.telephoneNumber.Value
		$MobilePhone = $account.mobile.Value
		$facsimileTelephoneNumber = $account.facsimileTelephoneNumber.Value	
		$wWWHomePage = $account.wwwHomePage.Value
		$title = $account.title.Value
		$Description = $account.Description.Value
		$DisplayName = $account.DisplayName.Value
		$whenCreated = $account.whenCreated.Value
		$whenChanged = $account.whenChanged.Value
		$ParentContainer = $account.Parent
		$HomePhone = $account.HomePhone.Value
		$StreetAddress = $account.StreetAddress.Value
		$PostalCode = $account.PostalCode.Value
		$PostOfficeBox = $account.PostOfficeBox.Value
	
		$query = "insert into ContactsAD (whenCreated,whenChanged,facsimileTelephoneNumber,mailNickname,givenName,mail," + 
			"sn,mobile,telephoneNumber,st,wWWHomePage,City,Company,Department,Email,Fax,FirstName," + 
			"HomePhone,Initials,LastName,LogonName,Manager,MobilePhone,Office,Pager,PhoneNumber," + 
			"PostalCode,PostOfficeBox,PrimaryGroupId,StateOrProvince,StreetAddress,Title,WebPage," + 
			"HomeDirectory,HomeDrive,ProfilePath,LogonScript,UserPrincipalName,AccountExpires," + 
			"PasswordLastSet,PasswordAge,PasswordExpires,LastLogonTimestamp,LastLogon,LastLogoff," + 
			"AccountIsDisabled,AccountIsLockedOut,PasswordNeverExpires,UserMustChangePassword,AccountIsExpired," + 
			"PasswordIsExpired,AccountExpirationStatus,PasswordStatus,NTAccountName,SamAccountName," + 
			"Security,Domain,LastKnownParent,Notes,Keywords,Path,DN,CanonicalName,CreationDate,ModificationDate," + 
			"ParentContainer,ParentContainerDN,Name,ClassName,Type,Sid,Description,DisplayName) VALUES (" + 			
			"'"	+ $whenCreated + "'," +
			"'"	+ $whenChanged + "'," +			
			"'"	+ $facsimileTelephoneNumber + "'," +
			"'"	+ $mailNickname + "'," +
			"'"	+ $givenName + "'," +
			"'"	+ $mail + "'," + 
			"'"	+ $sn + "'," +
			"'"	+ $MobilePhone + "'," +
			"'"	+ $telephoneNumber + "'," +
			"'"	+ $st + "'," +
			"'"	+ $wWWHomePage + "'," + 
			"'"	+ $City + "'," +
			"'"	+ $Company + "'," +
			"'"	+ $Department + "'," +
			"'"	+ $Email + "'," + 
			"'"	+ $Fax + "'," +
			"'"	+ $FirstName + "'," +
			"'"	+ $HomePhone + "'," +
			"'"	+ $Initials + "'," +
			"'"	+ $LastName + "'," +
			"'"	+ $LogonName + "'," +
			"'"	+ $Manager + "'," +
			"'"	+ $MobilePhone + "'," +
			"'"	+ $Office + "'," +
			"'"	+ $Pager + "'," +
			"'"	+ $PhoneNumber + "'," +
			"'"	+ $PostalCode + "'," + 
			"'"	+ $PostOfficeBox + "'," + 
			"'"	+ $PrimaryGroupId + "'," + 
			"'"	+ $StateOrProvince + "'," + 
			"'"	+ $StreetAddress + "'," + 
			"'"	+ $Title + "'," +
			"'"	+ $WebPage + "'," +
			"'"	+ $HomeDirectory + "'," +
			"'"	+ $HomeDrive + "'," +
			"'"	+ $ProfilePath + "'," +
			"'"	+ $LogonScript + "'," +
			"'"	+ $UserPrincipalName + "'," +
			"'"	+ $AccountExpires + "'," +
			"'"	+ $PasswordLastSet + "'," +
			"'"	+ $PasswordAge + "'," +
			"'"	+ $PasswordExpires + "'," +
			"'"	+ $LastLogonTimestamp + "'," +
			"'"	+ $LastLogon + "'," +
			"'"	+ $LastLogoff + "'," +
			"'"	+ $AccountIsDisabled + "'," +
			"'"	+ $AccountIsLockedOut + "'," +
			"'"	+ $PasswordNeverExpires + "'," +
			"'"	+ $UserMustChangePassword + "'," +
			"'"	+ $AccountIsExpired + "'," +
			"'"	+ $PasswordIsExpired + "'," +
			"'"	+ $AccountExpirationStatus + "'," +
			"'"	+ $PasswordStatus + "'," +
			"'"	+ $NTAccountName + "'," +
			"'"	+ $SamAccountName + "'," +
			"'"	+ $Security + "'," +
			"'"	+ $Domain + "'," +
			"'"	+ $LastKnownParent + "'," +
			"'"	+ $Notes + "'," +
			"'"	+ $Keywords + "'," +
			"'"	+ $Path + "'," +
			"'"	+ $DN + "'," +
			"'"	+ $CanonicalName + "'," +
			"'"	+ $CreationDate + "'," +
			"'"	+ $ModificationDate + "'," +
			"'"	+ $ParentContainer + "'," +
			"'"	+ $ParentContainerDN + "'," +
			"'"	+ $Name + "'," +
			"'"	+ $ClassName + "'," +
			"'"	+ $Type + "'," +
			"'"	+ $Sid + "'," +
			"'"	+ $Description + "'," +
			"'"	+ $DisplayName + "')"
		$data = Query-SQL $query $SQLconn
		
		$account = $null
	}	
}

Remove-SQLconnection $SQLconn

Echo-Log "End script $ScriptName"

Close-LogSystem