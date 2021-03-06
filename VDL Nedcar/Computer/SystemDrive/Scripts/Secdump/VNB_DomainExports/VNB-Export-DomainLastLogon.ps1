# =========================================================
# Export Active Directory LastLogon information to
# SQL database secdump.
#
# Marcel Jussen
# 20-01-2016
#
# =========================================================
Import-Module VNB_PSLib -Force -ErrorAction Stop

Add-PSSnapin Quest.ActiveRoles.ADManagement
# ---------------------------------------------------------
cls

# ------------------------------------------------------------------------------
$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-VNB-Export-LastLogon.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"

$Global:UDLConnection = Read-UDLConnectionString $glb_UDL
$Computername = $Env:COMPUTERNAME
$UsErase = $True
$SysErase = $True

$DCs = Get-QADComputer -ComputerRole DomainController 
$DCs | Foreach-Object {
	$dc = $_.Name
	Echo-Log "Exporting user data from $dc"

	$ADObjects = Get-QADUser -Service $dc -IncludedProperties LastLogon -SizeLimit 0
	$ObjectName = 'VNB_DOMAIN_USERS_LASTLOGON'
	Foreach ($ADO in $ADObjects) {
		$Account = "" | Select SamAccountName,domaincontroller,lastlogon,lastlogonDT
		$Account.SamAccountName = $($ADO.SamAccountName)
		$Account.domaincontroller = $dc
		if([string]::IsNullOrEmpty( $ADO.LastLogon )) {
			$Account.lastlogon = [datetime]'01-01-1900 00:00:00'
			$Account.lastlogondt = [datetime]'01-01-1900 00:00:00'
		} else {
			$Account.lastlogon = [datetime]$($ADO.LastLogon)
			$Account.lastlogondt = [datetime]$($ADO.LastLogon)
		}		
				
		$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $Account
		Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $Account -Computername $Computername -Erase $UsErase
		$UsErase = $False	
	} 
	
	Echo-Log "Exporting computer data from $dc"
	$ADObjects = Get-QADComputer -Service $dc -IncludedProperties LastLogon -SizeLimit 0
	$ObjectName = 'VNB_DOMAIN_COMPUTERS_LASTLOGON'
	Foreach ($ADO in $ADObjects) {
		$Account = "" | Select SamAccountName,domaincontroller,lastlogon,lastlogonDT
		$Account.SamAccountname = $($ADO.Name)
		$Account.domaincontroller = $dc
		if([string]::IsNullOrEmpty( $ADO.LastLogon )) {
			$Account.lastlogon = [datetime]'01-01-1900 00:00:00'
			$Account.lastlogondt = [datetime]'01-01-1900 00:00:00'
		} else {
			$Account.lastlogon = [datetime]$($ADO.LastLogon)
			$Account.lastlogondt = [datetime]$($ADO.LastLogon)
		}
			
		$new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $Account
		Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $Account -Computername $Computername -Erase $SysErase
		$SysErase = $False	
	} 
}

Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================