# =========================================================
# Export Active Directory users to
# SQL database secdump.
#
# Marcel Jussen
# 7-6-2017
#
# =========================================================
#Requires -version 3.0

Function Replace-SingleQuote-ToDbl {
	param (
		[string]$String = $null
	)	
	$single_quote = [string]([char]39)
	if(($String -eq $null) -or ($String.Length -eq 0)) { return "" }
	$String = $String.Replace($single_quote,$single_quote + $single_quote)
	return $String
}

clear
# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-VNB-Export-DomainUsers.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

$ObjectName = 'VNB_DOMAIN_USERS'
$Computername = $Env:COMPUTERNAME
$Erase = $True

$OuDomain = $(Get-ADInfo).FQDN 
$DomainNetbios = $(Get-ADInfo).Netbios
$ADGroupList = $null

# $ADGroupList = Get-ADUser -Properties * -Identity 'MJ90624'
$ADGroupList = Get-ADUser -Properties * -Filter *

if($ADGroupList) {
	Echo-Log "Retrieved $($ADGrouplist.count) user accounts from the domain $OuDomain"
	Clear-LogCache
	
	$cnt=0
	foreach($UserObject in $ADGroupList) {	
		$cnt++
	
		$UserAccount = "" | Select whenCreated,whenChanged,facsimileTelephoneNumber,givenName,mail, `
		sn,mobile,telephoneNumber,st,wWWHomePage,City,Company,Department,Email,Fax,FirstName,` 
		HomePhone,Initials,LastName,LogonName,Manager,MobilePhone,Office,Pager,PhoneNumber,` 
		PostalCode,PostOfficeBox,PrimaryGroupId,StateOrProvince,StreetAddress,Title,WebPage,` 
		HomeDirectory,HomeDrive,ProfilePath,LogonScript,UserPrincipalName,AccountExpires,` 
		PasswordLastSet,PasswordAge,PasswordExpires,LastLogonTimestamp,LastLogon,LastLogoff,` 
		AccountIsDisabled,AccountIsLockedOut,PasswordNeverExpires,UserMustChangePassword,AccountIsExpired,` 
		PasswordIsExpired,AccountExpirationStatus,PasswordStatus,NTAccountName,SamAccountName,` 
		Domain,LastKnownParent,Notes,Keywords,Path,DN,CanonicalName,CreationDate,ModificationDate,` 
		ParentContainer,ParentContainerDN,Name,ClassName,Type,Sid,Description,DisplayName,otherTelephone
	
		$UserAccount.SamAccountName = Replace-SingleQuote-ToDbl $($UserObject.samaccountname)
		# Replace LogonName with SamAccountName
		$UserAccount.LogonName = Replace-SingleQuote-ToDbl $($UserObject.samaccountname)
		
		Write-Host "$cnt $($UserAccount.SamAccountName)"
		Clear-LogCache
	
		if([string]::IsNullOrEmpty($UserObject.whencreated)) {		
        	$UserAccount.whenCreated = [datetime]'01-01-1900 00:00:00'
		} else { 		
        	$UserAccount.whenCreated = [datetime]$UserObject.whencreated
		}	
		if([string]::IsNullOrEmpty($UserObject.whenchanged)) {		
        	$UserAccount.whenChanged = [datetime]'01-01-1900 00:00:00'
		} else { 		        
        	$UserAccount.whenChanged = [datetime]$UserObject.whenchanged
		}	
		$UserAccount.facsimileTelephoneNumber = Replace-SingleQuote-ToDbl $($UserObject.facsimiletelephonenumber)
		$UserAccount.givenName = Replace-SingleQuote-ToDbl $($UserObject.givenname)
		$UserAccount.mail = Replace-SingleQuote-ToDbl $($UserObject.mail)
		$UserAccount.sn = Replace-SingleQuote-ToDbl $($UserObject.sn)
		$UserAccount.mobile = Replace-SingleQuote-ToDbl $($UserObject.mobile)
		$UserAccount.telephoneNumber = Replace-SingleQuote-ToDbl $($UserObject.telephonenumber)
		$UserAccount.st = Replace-SingleQuote-ToDbl $($UserObject.st)
		$UserAccount.wWWHomePage = Replace-SingleQuote-ToDbl $($UserObject.wwwhomepage)
		$UserAccount.City = Replace-SingleQuote-ToDbl $($UserObject.city)
		$UserAccount.Company = Replace-SingleQuote-ToDbl $($UserObject.company)
		$UserAccount.Department = Replace-SingleQuote-ToDbl $($UserObject.department)
		$UserAccount.Email = Replace-SingleQuote-ToDbl $($UserObject.mail)
		$UserAccount.Fax = Replace-SingleQuote-ToDbl $($UserObject.fax)
		$UserAccount.FirstName = Replace-SingleQuote-ToDbl $($UserObject.givenname)
		$UserAccount.HomePhone = Replace-SingleQuote-ToDbl $($UserObject.homephone)
		$UserAccount.Initials = Replace-SingleQuote-ToDbl $($UserObject.initials)
		$UserAccount.LastName = Replace-SingleQuote-ToDbl $($UserObject.sn)	
		$UserAccount.Manager = Replace-SingleQuote-ToDbl $($UserObject.manager)
		$UserAccount.MobilePhone = Replace-SingleQuote-ToDbl $($UserObject.mobile)
		$UserAccount.Office = Replace-SingleQuote-ToDbl $($UserObject.office)
		$UserAccount.Pager = Replace-SingleQuote-ToDbl $($UserObject.pager)
		$UserAccount.PhoneNumber = Replace-SingleQuote-ToDbl $($UserObject.telephonenumber)
		$UserAccount.PostalCode = Replace-SingleQuote-ToDbl $($UserObject.postalcode)
		$UserAccount.PostOfficeBox = Replace-SingleQuote-ToDbl $($UserObject.PObox)
		$UserAccount.PrimaryGroupId = Replace-SingleQuote-ToDbl $($UserObject.primarygroupid)
		$UserAccount.StateOrProvince = Replace-SingleQuote-ToDbl $($UserObject.state)
		$UserAccount.StreetAddress = Replace-SingleQuote-ToDbl $($UserObject.streetaddress)
		$UserAccount.Title = Replace-SingleQuote-ToDbl $($UserObject.title)		
		$UserAccount.HomeDirectory = Replace-SingleQuote-ToDbl $($UserObject.homedirectory)
		$UserAccount.HomeDrive = Replace-SingleQuote-ToDbl $($UserObject.homedrive)
		$UserAccount.ProfilePath = Replace-SingleQuote-ToDbl $($UserObject.profilepath)
		$UserAccount.LogonScript = Replace-SingleQuote-ToDbl $($UserObject.scriptpath)
		$UserAccount.UserPrincipalName = Replace-SingleQuote-ToDbl $($UserObject.userprincipalname)
		$UserAccount.LastLogoff = Replace-SingleQuote-ToDbl $($UserObject.lastlogoff)
		
		if([string]::IsNullOrEmpty($UserObject.PasswordLastSet)) {
			$UserAccount.PasswordLastSet = [datetime]'01-01-1900 00:00:00'
		} else { 
			$UserAccount.PasswordLastSet = [datetime]$UserObject.passwordlastset
		}
		if([string]::IsNullOrEmpty($UserObject.LastLogonTimestamp)) {
			$UserAccount.LastLogonTimestamp = [datetime]'01-01-1900 00:00:00'
		} else {
			$UserAccount.LastLogonTimestamp = [datetime]$UserObject.lastlogontimestamp
		}
		if([string]::IsNullOrEmpty($UserObject.LastLogonDate)) {
			$UserAccount.LastLogon = [datetime] '01-01-1900 00:00:00'
		} else {
			$UserAccount.LastLogon = [datetime]$UserObject.lastlogondate
		}
		$UserAccount.PasswordNeverExpires = Replace-SingleQuote-ToDbl $($UserObject.passwordneverexpires)
		$UserAccount.AccountExpires = Replace-SingleQuote-ToDbl $($UserObject.accountexpires)
		
		if($UserObject.Enabled -eq 'True') { 
			$UserAccount.AccountIsDisabled = 'False' 
		} else { 
			$UserAccount.AccountIsDisabled = 'True'
		}
		$UserAccount.AccountIsLockedOut = Replace-SingleQuote-ToDbl $($UserObject.LockedOut) 		
			
		try {
			$SpanDays = (New-TimeSpan -Start $ADGroupList.PasswordLastSet.Date -End (Get-Date)).Days
			$UserAccount.PasswordAge = $SpanDays
		}
		catch {
			$UserAccount.PasswordAge = ''
		}
		
		$UserAccount.PasswordIsExpired = Replace-SingleQuote-ToDbl $($UserObject.PasswordExpired)
		$UserAccount.UserMustChangePassword = Replace-SingleQuote-ToDbl $($UserObject.PasswordExpired) 
		
		# This field is calculated by the SP dbo.prc_VNB_UPDATE_PWDEXPIRES
		$UserAccount.PasswordExpires = ''
		
		if($UserObject.passwordexpired -eq 'True') {
			$UserAccount.PasswordStatus = 'Expired'
		} else {
			$UserAccount.PasswordStatus = 'Normal'
		}
		 
	#-----			
	
		$UserAccount.AccountIsExpired = Replace-SingleQuote-ToDbl $($UserObject.AccountExpirationDate)
		$UserAccount.AccountExpirationStatus = Replace-SingleQuote-ToDbl $($UserObject.AccountExpirationDate)				
		
		$UserAccount.NTAccountName = Replace-SingleQuote-ToDbl $($UserObject.Name)
		$UserAccount.Domain = $DomainNetbios
		$UserAccount.LastKnownParent = Replace-SingleQuote-ToDbl $($UserObject.lastknownparent)			
		$UserAccount.Path = Replace-SingleQuote-ToDbl "LDAP://$($UserObject.DistinguishedName)"
		$UserAccount.DN = Replace-SingleQuote-ToDbl $($UserObject.DistinguishedName)
		$UserAccount.CanonicalName = Replace-SingleQuote-ToDbl $($UserObject.CN)	
		$UserAccount.CreationDate = $UserAccount.whenCreated
		$UserAccount.ModificationDate = $UserAccount.whenChanged		 	
		$UserAccount.ParentContainer = Replace-SingleQuote-ToDbl $($UserObject.DistinguishedName)
		$UserAccount.ParentContainerDN = Replace-SingleQuote-ToDbl "LDAP://$($UserObject.DistinguishedName)"	
		$UserAccount.Name = Replace-SingleQuote-ToDbl $($UserObject.name)		
		$UserAccount.Type = Replace-SingleQuote-ToDbl $($UserObject.ObjectClass)
		$UserAccount.Sid = Replace-SingleQuote-ToDbl $($UserObject.SID)
		$UserAccount.Description = Replace-SingleQuote-ToDbl $($UserObject.description)
		$UserAccount.DisplayName = Replace-SingleQuote-ToDbl $($UserObject.displayname)		
		$UserAccount.otherTelephone = Replace-SingleQuote-ToDbl $($UserObject.otherTelephone)	
		
	# Redundant. Leftovers from using QAD-User
		$UserAccount.ClassName = Replace-SingleQuote-ToDbl $('User')
		$UserAccount.Notes = Replace-SingleQuote-ToDbl $('')
		$UserAccount.Keywords = Replace-SingleQuote-ToDbl $('')
		$UserAccount.WebPage = Replace-SingleQuote-ToDbl $('')
	
		$ObjectData = $UserAccount
		$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
		$Erase = $False	
	}	
} else {
	Echo-Log "ERROR: No users were retrieved. Export to SQL failed."
}

Echo-Log "Update table VNB_DOMAIN_USERS with prc_VNB_UPDATE_DOMAIN_USERS"
$query = 'exec dbo.prc_VNB_UPDATE_DOMAIN_USERS'
$SECDUMPDB = New-UDLSQLconnection $Global:UDLConnection
$temp = Invoke-SQLQuery -conn $SECDUMPDB -query $query

Echo-Log "Update table VNB_DOMAIN_USERS with prc_VNB_UPDATE_PWDEXPIRES"
$query = 'exec dbo.prc_VNB_UPDATE_PWDEXPIRES'
$temp = Invoke-SQLQuery -conn $SECDUMPDB -query $query

Remove-SQLconnection -connection $SECDUMPDB

Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================