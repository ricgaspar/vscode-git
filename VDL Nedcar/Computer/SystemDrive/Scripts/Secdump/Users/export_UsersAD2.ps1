# ---------------------------------------------------------
# Collect user information from AD
# Marcel Jussen
# 9-10-2012
# ---------------------------------------------------------

cls
Add-PSSnapin Quest.ActiveRoles.ADManagement

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

Function Replace-SingleQuote-ToDbl {
	param (
		[string]$String = $null
	)	
	$single_quote = [string]([char]39)
	if(($String -eq $null) -or ($String.Length -eq 0)) { return "" }
	$String = $String.Replace($single_quote,$single_quote + $single_quote)
	return $String
}

Function Import_UsersAD {
	$OuDomain = "DC=nedcar,DC=nl" 
	
	Echo-Log "Query AD for user objects."
	# $colResults  = Get-QADUser -searchRoot $OuDomain -SamAccountName "OKE1690"
	$colResults  = Get-QADUser -searchRoot $OuDomain  -SizeLimit 0
	
	if($colResults -ne $null) {
		$count = $colResults.Count
		Echo-Log "AD User collection: $count accounts."
	
		$query = "delete from UsersAD"
		Echo-Log $query
		$data = Query-SQL $query $SQLconn

		$query = "delete from UsersAD_SAM"
		Echo-Log $query
		$data = Query-SQL $query $SQLconn
	}

	foreach($account in $colResults) {
 	$Path = Replace-SingleQuote-ToDbl $account.Path		
	$whenCreated = Replace-SingleQuote-ToDbl $account.whenCreated
	$whenChanged = Replace-SingleQuote-ToDbl $account.whenChanged
	$facsimileTelephoneNumber = Replace-SingleQuote-ToDbl $account.facsimileTelephoneNumber
	$givenName = Replace-SingleQuote-ToDbl $account.givenName
	$mail = Replace-SingleQuote-ToDbl $account.mail
	$sn	= Replace-SingleQuote-ToDbl $account.sn
	$mobile = Replace-SingleQuote-ToDbl $account.mobile
	$telephoneNumber = Replace-SingleQuote-ToDbl $account.telephoneNumber
	$st = Replace-SingleQuote-ToDbl $account.st
	$wWWHomePage = Replace-SingleQuote-ToDbl $account.wWWHomePage
	$City = Replace-SingleQuote-ToDbl $account.City
	$Company = Replace-SingleQuote-ToDbl $account.Company
	$Department = Replace-SingleQuote-ToDbl $account.Department
	$Email = Replace-SingleQuote-ToDbl $account.Email
	$Fax = Replace-SingleQuote-ToDbl $account.Fax
	$FirstName = Replace-SingleQuote-ToDbl $account.FirstName
	$HomePhone = Replace-SingleQuote-ToDbl $account.HomePhone
	$Initials = Replace-SingleQuote-ToDbl $account.Initials
	$LastName = Replace-SingleQuote-ToDbl $account.LastName
	$LogonName = Replace-SingleQuote-ToDbl $account.LogonName
	$Manager = Replace-SingleQuote-ToDbl $account.Manager
	$MobilePhone = Replace-SingleQuote-ToDbl $account.MobilePhone
	$Office = Replace-SingleQuote-ToDbl $account.Office
	$Pager = Replace-SingleQuote-ToDbl $account.Pager
	$PhoneNumber = Replace-SingleQuote-ToDbl $account.PhoneNumber
	$PostalCode = Replace-SingleQuote-ToDbl $account.PostalCode
	$PostOfficeBox = Replace-SingleQuote-ToDbl $account.PostOfficeBox
	$PrimaryGroupId = Replace-SingleQuote-ToDbl $account.PrimaryGroupId
	$StateOrProvince = Replace-SingleQuote-ToDbl $account.StateOrProvince
	$StreetAddress = Replace-SingleQuote-ToDbl $account.StreetAddress
	$Title = Replace-SingleQuote-ToDbl $account.Title
	$WebPage = Replace-SingleQuote-ToDbl $account.WebPage
	$HomeDirectory = Replace-SingleQuote-ToDbl $account.HomeDirectory
	$HomeDrive = Replace-SingleQuote-ToDbl $account.HomeDrive
	$ProfilePath = Replace-SingleQuote-ToDbl $account.ProfilePath
	$LogonScript = Replace-SingleQuote-ToDbl $account.LogonScript
	$UserPrincipalName = Replace-SingleQuote-ToDbl $account.UserPrincipalName
	$AccountExpires = Replace-SingleQuote-ToDbl $account.AccountExpires
	$PasswordLastSet = Replace-SingleQuote-ToDbl $account.PasswordLastSet
	$PasswordAge = Replace-SingleQuote-ToDbl $account.PasswordAge
	$PasswordExpires = Replace-SingleQuote-ToDbl $account.PasswordExpires
	$LastLogonTimestamp = Replace-SingleQuote-ToDbl $account.LastLogonTimestamp
	$LastLogon = Replace-SingleQuote-ToDbl $account.LastLogon
	$LastLogoff = Replace-SingleQuote-ToDbl $account.LastLogoff
	$AccountIsDisabled = Replace-SingleQuote-ToDbl $account.AccountIsDisabled
	$AccountIsLockedOut = Replace-SingleQuote-ToDbl $account.AccountIsLockedOut
	$PasswordNeverExpires = Replace-SingleQuote-ToDbl $account.PasswordNeverExpires
	$UserMustChangePassword = Replace-SingleQuote-ToDbl $account.UserMustChangePassword
	$AccountIsExpired = Replace-SingleQuote-ToDbl $account.AccountIsExpired
	$PasswordIsExpired = Replace-SingleQuote-ToDbl $account.PasswordIsExpired
	$AccountExpirationStatus = Replace-SingleQuote-ToDbl $account.AccountExpirationStatus
	$PasswordStatus = Replace-SingleQuote-ToDbl $account.PasswordStatus
	$NTAccountName = Replace-SingleQuote-ToDbl $account.NTAccountName
	$SamAccountName = Replace-SingleQuote-ToDbl $account.SamAccountName	
	$Domain = Replace-SingleQuote-ToDbl $account.Domain
	$LastKnownParent = Replace-SingleQuote-ToDbl $account.LastKnownParent
	$Notes = Replace-SingleQuote-ToDbl $account.Notes
	$Keywords = Replace-SingleQuote-ToDbl $account.Keywords
	$Path = Replace-SingleQuote-ToDbl $account.Path
	$DN = Replace-SingleQuote-ToDbl $account.DN
	$CanonicalName = Replace-SingleQuote-ToDbl $account.CanonicalName
	$CreationDate = Replace-SingleQuote-ToDbl $account.CreationDate
	$ModificationDate = Replace-SingleQuote-ToDbl $account.ModificationDate
	$ParentContainer = Replace-SingleQuote-ToDbl $account.ParentContainer
	$ParentContainerDN = Replace-SingleQuote-ToDbl $account.ParentContainerDN
	$Name = Replace-SingleQuote-ToDbl $account.Name
	$ClassName = Replace-SingleQuote-ToDbl $account.ClassName
	$Type = Replace-SingleQuote-ToDbl $account.Type
	$Sid = Replace-SingleQuote-ToDbl $account.Sid
	$Description = Replace-SingleQuote-ToDbl $account.Description
	$DisplayName = Replace-SingleQuote-ToDbl $account.DisplayName
	
	$query = "insert into usersAD (whenCreated,whenChanged,facsimileTelephoneNumber,givenName,mail," + 
		"sn,mobile,telephoneNumber,st,wWWHomePage,City,Company,Department,Email,Fax,FirstName," + 
		"HomePhone,Initials,LastName,LogonName,Manager,MobilePhone,Office,Pager,PhoneNumber," + 
		"PostalCode,PostOfficeBox,PrimaryGroupId,StateOrProvince,StreetAddress,Title,WebPage," + 
		"HomeDirectory,HomeDrive,ProfilePath,LogonScript,UserPrincipalName,AccountExpires," + 
		"PasswordLastSet,PasswordAge,PasswordExpires,LastLogonTimestamp,LastLogon,LastLogoff," + 
		"AccountIsDisabled,AccountIsLockedOut,PasswordNeverExpires,UserMustChangePassword,AccountIsExpired," + 
		"PasswordIsExpired,AccountExpirationStatus,PasswordStatus,NTAccountName,SamAccountName," + 
		"Domain,LastKnownParent,Notes,Keywords,Path,DN,CanonicalName,CreationDate,ModificationDate," + 
		"ParentContainer,ParentContainerDN,Name,ClassName,Type,Sid,Description,DisplayName) VALUES (" + 			
		"'"	+ $whenCreated + "'," +
		"'"	+ $whenChanged + "'," +
		"'"	+ $facsimileTelephoneNumber + "'," +
		"'"	+ $givenName + "'," +
		"'"	+ $mail + "'," + 
		"'"	+ $sn + "'," +
		"'"	+ $mobile + "'," +
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
	# $data = Query-SQL $query $SQLconn
	
	$Query = "INSERT INTO [SECDUMP].[dbo].[UsersAD_SAM] ([systemname],[domainname],[poldatetime],[SamAccountName],[SID],[DN]) "+ 
    	"VALUES (" + 
		"'"	+ $Env:COMPUTERNAME + "'," +
		"'"	+ $Env:USERDOMAIN + "'," +
		"GetDate()," + 
		"'"	+ $SamAccountName + "'," +
		"'"	+ $Sid + "'," +
		"'"	+ $DN + "')"				
	$data = Query-SQL $query $SQLconn
	
	}
}

Function Check_Import {
	$query = "select * from vw_UsersAD_ImportFailures"	
	$data = Query-SQL $query $SQLconn
}

# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($SQLconn.state -eq "Closed") { exit }   	

Echo-Log "---------------------------------"

Import_UsersAD
Check_Import

Echo-Log "---------------------------------"
Echo-Log "End script $ScriptName"

Close-LogSystem
Remove-SQLconnection $SQLconn