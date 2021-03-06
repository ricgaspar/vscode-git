# =========================================================
# Export Active Directory users to
# SQL database secdump.
#
# Marcel Jussen
# 20-01-2016
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

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-VNB-Export-DomainComputers.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

$Global:UDLConnection = Read-UDLConnectionString $glb_UDL
$ObjectName = 'VNB_DOMAIN_COMPUTERS'
$Computername = $Env:COMPUTERNAME
$Erase = $True

if (Test-Path "hosts.ini") { Remove-Item "hosts.ini" -Force -ErrorAction SilentlyContinue }
$file = New-Item -type file "hosts.ini"

$ADSearchFilter = "(&(objectCategory=Computer))"
$colProplist = "*"
$ADGroupList = Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist

if($ADGroupList) {
	Echo-Log "Retrieved $($ADGrouplist.count) computer accounts from the domain $OuDomain"
}

foreach($ADObject in $ADGroupList) {
	$Computer= "" | Select DN,CN,description,displayname,useraccountcontrol,codepage,countrycode,lastlogon,location,operatingsystem,operatingsystemversion,operatingsystemservicepack,dnshostname,servicePrincipalName,whencreated,whenchanged
	$Computer.DN = [string]$($ADObject.properties.adspath)		
	$Computer.CN = [string]$($ADObject.properties.cn)
	$Computer.description = [string]$($ADObject.properties.description)	
	$Computer.displayname = [string]$($ADObject.properties.displayname)	
	$Computer.useraccountcontrol = [string]$($ADObject.properties.useraccountcontrol)
	$Computer.codepage = [string]$($ADObject.properties.codepage)
	$Computer.countrycode = [string]$($ADObject.properties.countrycode)
	$Computer.lastlogon = [datetime]::FromFileTime($($ADObject.properties.lastlogon))
	$Computer.operatingsystem = [string]$($ADObject.properties.operatingsystem)
	$Computer.operatingsystemversion = [string]$($ADObject.properties.operatingsystemversion)
	$Computer.operatingsystemservicepack = [string]$($ADObject.properties.operatingsystemservicepack)
	$Computer.dnshostname = [string]$($ADObject.properties.dnshostname)
	$Computer.servicePrincipalName = [string]$($ADObject.properties.servicePrincipalName)	
	$Computer.whencreated = [string]$($ADObject.properties.whencreated)
	$Computer.whenchanged = [string]$($ADObject.properties.whenchanged)	
	
	$ObjectData = $Computer
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