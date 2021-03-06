# =========================================================
# Export Active Directory contacts to
# SQL database secdump.
#
# Marcel Jussen
# 19-01-2016
#
# =========================================================
#Requires -version 3.0

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

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

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-VNB-Export-DomainContacts.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

$Global:UDLConnection = Read-UDLConnectionString $glb_UDL
$ObjectName = 'VNB_DOMAIN_CONTACTS'
$Computername = $Env:COMPUTERNAME

# Indicate table erase = true (switched on for first record insertion)
$Erase = $True

$OuDomain = $(Get-ADInfo).FQDN 
$ADSearchFilter = "(&(objectCategory=User)(objectClass=contact))"
$colProplist = "*"
$ADGroupList = Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist

if($ADGroupList) {
	Echo-Log "Retrieved $($ADGrouplist.count) contact accounts from the domain $OuDomain"
}

$cnt=0
foreach($ADObject in $ADGroupList) {	
	$cnt++
	
	$Contact = "" | Select displayname,targetaddress,givenname,mail,mailnickname,name,msexchrecipientdisplaytype, `
						sn,proxyaddresses,msexchaddressbookflags,whencreated,msexchmoderationflags,adspath, `
						cn,msexchumdtmfmap,whenchanged,msexchbypassaudit,title,internetencoding,showinaddressbook, `
						msexchmailboxauditenable,distinguishedname,msexchprovisioningflags,objectguid
						
	$Contact.displayname = Replace-SingleQuote-ToDbl $($ADObject.properties.displayname)
	$Contact.targetaddress = Replace-SingleQuote-ToDbl $($ADObject.properties.targetaddress)
	$Contact.givenname = Replace-SingleQuote-ToDbl $($ADObject.properties.givenname)
	$Contact.mail = Replace-SingleQuote-ToDbl $($ADObject.properties.mail)
	$Contact.mailnickname = Replace-SingleQuote-ToDbl $($ADObject.properties.mailnickname)
	$Contact.name = Replace-SingleQuote-ToDbl $($ADObject.properties.name)
	$Contact.msexchrecipientdisplaytype = Replace-SingleQuote-ToDbl $($ADObject.properties.msexchrecipientdisplaytype)
	$Contact.sn = Replace-SingleQuote-ToDbl $($ADObject.properties.sn)
	$Contact.proxyaddresses = Replace-SingleQuote-ToDbl $($ADObject.properties.proxyaddresses)
	$Contact.msexchaddressbookflags = Replace-SingleQuote-ToDbl $($ADObject.properties.msexchaddressbookflags)
	$Contact.whencreated = Replace-SingleQuote-ToDbl $($ADObject.properties.whencreated)
	$Contact.msexchmoderationflags = Replace-SingleQuote-ToDbl $($ADObject.properties.msexchmoderationflags)
	$Contact.adspath = Replace-SingleQuote-ToDbl $($ADObject.properties.adspath)
	$Contact.cn = Replace-SingleQuote-ToDbl $($ADObject.properties.cn)
	$Contact.msexchumdtmfmap = Replace-SingleQuote-ToDbl $($ADObject.properties.msexchumdtmfmap)
	$Contact.whenchanged = Replace-SingleQuote-ToDbl $($ADObject.properties.whencreated)
	$Contact.msexchbypassaudit = Replace-SingleQuote-ToDbl $($ADObject.properties.msexchbypassaudit)
	$Contact.title = Replace-SingleQuote-ToDbl $($ADObject.properties.title)
	$Contact.internetencoding = Replace-SingleQuote-ToDbl $($ADObject.properties.internetencoding)
	$Contact.showinaddressbook = Replace-SingleQuote-ToDbl $($ADObject.properties.showinaddressbook)
	$Contact.msexchmailboxauditenable = Replace-SingleQuote-ToDbl $($ADObject.properties.msexchmailboxauditenable)
	$Contact.distinguishedname = Replace-SingleQuote-ToDbl $($ADObject.properties.distinguishedname)
	$Contact.msexchprovisioningflags = Replace-SingleQuote-ToDbl $($ADObject.properties.msexchprovisioningflags)
	$Contact.objectguid = Replace-SingleQuote-ToDbl $($ADObject.properties.objectguid)
	
	$ObjectData = $Contact
	$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
	Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
	$Erase = $False	
}

Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================