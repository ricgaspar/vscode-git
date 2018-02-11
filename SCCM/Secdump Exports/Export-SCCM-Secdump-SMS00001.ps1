# =========================================================
# Export SCCM info to SQL database secdump.
#
# Marcel Jussen
# 17-02-2016
#
# =========================================================
#Requires -version 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

cls
$ScriptName = $myInvocation.MyCommand.name
$logfile = "Secdump-SCCM-SMS00001-Export"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$SCCMSiteCode = 'VNB'
$SCCMSiteServer = 's007.nedcar.nl'
$Computername = $Env:COMPUTERNAME

$CollectionName = 'SMS_CM_RES_COLL_SMS00001'
Echo-Log "Query SCCM collection $($CollectionName) thru WMI."
$strQuery = "SELECT * FROM $CollectionName"
$Computers = Get-WmiObject -Namespace "Root\SMS\Site_$SCCMSiteCode" -ComputerName $SCCMSiteServer -Query $strQuery -ErrorAction STOP

if($Computers -ne $null) {
	$Erase = $true
	$ObjectName = 'VNB_' + $CollectionName
	$ObjectData = $Computers

	$UDLConnection = Read-UDLConnectionString $glb_UDL
	Echo-Log "Updating secdump database table $($ObjectName)"
	foreach($Object in $Computers) {
		Echo-Log "ResourceID: $($Object.ResourceID) [$($Object.Name)]"
		$Computer= "" | Select Name,ADSitename,ClientActiveStatus,ClientType,ClientVersion,DeviceOS,Domain,IsObsolete,IsActive,LastMPServerName,ResourceID,ResourceType,SiteCode,UserDomainName,Username
		$Computer.Name = [string]$($Object.Name)
		$Computer.ADSitename = [string]$($Object.ADSitename)
		$Computer.ClientActiveStatus = [string]$($Object.ClientActiveStatus)
		$Computer.ClientType = [string]$($Object.ClientType)
		$Computer.ClientVersion = [string]$($Object.ClientVersion)
		$Computer.DeviceOS = [string]$($Object.DeviceOS)
		$Computer.Domain = [string]$($Object.Domain)
		$Computer.IsObsolete = [string]$($Object.IsObsolete)
		$Computer.IsActive = [string]$($Object.IsActive)
		$Computer.LastMPServerName = [string]$($Object.LastMPServerName)
		$Computer.ResourceID = [string]$($Object.ResourceID)
		$Computer.ResourceType = [string]$($Object.ResourceType)
		$Computer.SiteCode = [string]$($Object.SiteCode)
		$Computer.UserDomainName= [string]$($Object.UserDomainName)
		$Computer.UserName = [string]$($Object.UserName)
	
		$ObjectData = $Computer
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
		$Erase = $False
	}
} else {
	Echo-Log "Error: no results were retrieved from WMI"
}

Echo-Log "Done parsing SCCM client data."

# We are done.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

Close-LogSystem
