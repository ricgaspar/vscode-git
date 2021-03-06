# =========================================================
# Export Active Directory domain groups to
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

Function Export-DomainGroups {
	Echo-Log "Retrieve domain groups from Active Directory"
	
	# Get all domain groups
	$ADSearchFilter = "(&(objectCategory=group))"
	$Proplist = "name","description","objectsid","info","cn","grouptype"
	$ADGroupList = Search-AD -ADSearchFilter $ADSearchFilter -colProplist $Proplist
		
	Echo-Log "$($ADGroupList.count) domain groups retrieved from Active Directory"

	# Create MSSQL connection
	$Global:UDLConnection = Read-UDLConnectionString $glb_UDL
	$Erase = $True
	$ObjectName = 'VNB_DOMAIN_GROUPS'
	$Computername = $Env:COMPUTERNAME
		
	foreach($Group in $ADGroupList) {
		$GrpObj = "" | Select groupname,DomainIdentity,description,DN,info,cn,grouptype
		$GrpObj.groupname = [string]$($Group.properties.name)
		$GrpObj.DomainIdentity = $env:USERDOMAIN + '\' + [string]$($Group.properties.name)
		$GrpObj.description = [string]$($Group.properties.description)
		$GrpObj.DN = [string]$($Group.properties.adspath)
		$GrpObj.info = [string]$($Group.properties.info)
		$GrpObj.cn = [string]$($Group.properties.cn)
		$GrpObj.grouptype = [string]$($Group.properties.grouptype)
		$ObjectData = $GrpObj
	
		$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
		$Erase = $False
	}
}

Function Export-DomainGroupMembers {
	Echo-Log "Retrieve domain group members from Active Directory"
	
	# Get all domain groups
	$ADSearchFilter = "(&(objectCategory=group))"
	$Proplist = "name"
	$ADGroupList = Search-AD -ADSearchFilter $ADSearchFilter -colProplist $Proplist
	
	Echo-Log "$($ADGroupList.count) domain groups retrieved from Active Directory"

	# Create MSSQL connection
	$Global:UDLConnection = Read-UDLConnectionString $glb_UDL
	$Erase = $True
	$ObjectName = 'VNB_DOMAIN_GROUPMEMBERS'
	$Computername = $Env:COMPUTERNAME	

	foreach($Group in $ADGroupList) {
		Echo-Log "  $($Group.properties.name)"
		$ADSIGroup = [adsi]$($Group.properties.adspath)
		$result = $ADSIGroup.member
		foreach($member in $result) {
			$names = $member -split ','
			$membername = $names[0]
			$membername = $membername -replace 'CN=',''
			$GroupMember = "" | Select groupname,DomainIdentity,member,DomainMemberIdentity
			$GroupMember.groupname = [string]$($Group.properties.name)
			$GroupMember.DomainIdentity = $env:USERDOMAIN + '\' + [string]$($Group.properties.name)		
			$GroupMember.member = $membername
			$GroupMember.DomainMemberIdentity = $env:USERDOMAIN + '\' + $membername
			$ObjectData = $Groupmember

			$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
			$Erase = $False
		}
	}
}

# ---------------------------------------------------------
clear

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-VNB-Export-DomainGroups.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

Export-DomainGroups

Export-DomainGroupMembers


Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================