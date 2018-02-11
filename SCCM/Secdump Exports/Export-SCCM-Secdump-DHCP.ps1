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
$logfile = "Secdump-SCCM-DHCP-Export"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$SCCMSiteCode = 'VNB'
$SCCMSiteServer = 's007.nedcar.nl'

$QuerySCCM = "
select DISTINCT 
	G.Name0,
	G.Domain0,	
    A.Manufacturer0, 
    A.Model0,
	B.SerialNumber0,
	H.Caption0,
	I.LastHWScan,
	F.MACAddress0,    
    replace(F.MACAddress0,':','') as MACAddress,
	F.DHCPEnabled0,
	F.DHCPServer0,
	F.IPAddress0,
	ND.DriverDate0, 
	ND.DriverDesc0,
	ND.DriverVersion0,
	ND.MediaType0,
	ND.ProviderName0
FROM v_GS_SYSTEM G
INNER JOIN v_FullCollectionMembership FCM 
	ON G.ResourceID = FCM.ResourceID
INNER JOIN dbo.v_GS_COMPUTER_SYSTEM A on G.ResourceID = A.ResourceID
INNER JOIN dbo.v_GS_PC_BIOS B on G.ResourceID = B.ResourceID 
INNER JOIN v_GS_NETWORK_DRIVERS ND ON g.ResourceID = ND.ResourceID
INNER JOIN dbo.v_GS_NETWORK_ADAPTER_CONFIGUR F 
	on G.ResourceID = F.ResourceID
	AND F.Index0 = ND.Index0
INNER JOIN dbo.v_GS_OPERATING_SYSTEM H  on G.ResourceID = H.ResourceID 
INNER JOIN dbo.v_GS_WORKSTATION_STATUS I  on G.ResourceID = I.ResourceID 
where FCM.CollectionID = 'SMS00001'
	AND FCM.IsObsolete=0
	-- AND NOT(F.IPAddress0 is NULL)
	AND F.DHCPEnabled0 = '1'
order by G.Name0"

Echo-Log "Query SCCM database."
$SCCMDB = New-SQLconnection -server $SCCMSiteServer -database "CM_$SCCMSiteCode"
$DHCPClients = Invoke-SQLQuery -conn $SCCMDB -query $QuerySCCM
Remove-SQLconnection -connection $SCCMDB

$UDLConnection = Read-UDLConnectionString $glb_UDL
$Erase = $true
$Computername = $env:COMPUTERNAME
$ObjectName = 'VNB_SMS_DHCP_CLIENTS'
Echo-Log "Updating secdump database table $($ObjectName)"

$ObjectData = $DHCPClients
$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase

Echo-Log "Done exporting SCCM client data."

# We are done.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

Close-LogSystem