# ---------------------------------------------------------
# Repair_Users_Home
#
# Marcel Jussen
# 29-8-2013
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $false

Function Repair_CtxAD {
	param (
		$Username
	)
	
	# Convert to uppercase
	$Username = $Username.ToUpper()	
	$Result = Search-AD-User $Username
	if ($Result -ne $null) {
		$CtxProfPathSol = ("%UserProfileCitrix%\" + $Username)
		$CtxProfPathSolT = $CtxProfPathSol.ToUpper()
		
		$objOU=[ADSI]($Result)		
		$CtxProfPathIst = $objOU.psbase.Invokeget("terminalservicesprofilepath")
		$CtxProfPathIst = $CtxProfPathIst.ToUpper()
		
		$d = $CtxProfPathIst.CompareTo($CtxProfPathSolT)
		if($d -ne 0) {
			$CtxProfPathIst = $objOU.psbase.Invokeset("terminalservicesprofilepath",$CtxProfPathSol)
			$objOU.SetInfo()
		} 
		
	} else {
			Echo-Log "ERROR: The user $Username was not found in AD."
	}
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Repair_CtxAD-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"
Echo-Log ("-"*60)

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

Echo-Log "Inventory users accounts in the domain."
$userCol = collectAD_Users_SAM

Echo-Log "Checking user accounts."
foreach($User in $userCol) {
	$path = $User.Path
	if($path -ne $null) {
		$path = $path.ToUpper()
		if($path.Contains("OU=NEDCAR,DC=NEDCAR,DC=NL")) {			
			$obj = [ADSI]$path
			$SamAccountName = $obj.sAMAccountName.value
			Repair_CtxAD $SamAccountName
		}
	}
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if ($Global:Changes_Committed -ne 0) {
	$Title = "Repair User home directories. $cdtime ($Global:Changes_Committed changes committed)" 	
} else {
	$Title = "Repair User home directories. $cdtime (No changes committed)" 
}

if($Global:DEBUG) {
	Echo-Log "** Debug: Sending resulting log as a mail message."
} 

$SendTo = "nedcar-events@kpn.com"
$dnsdomain = Get-DnsDomain
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

# Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
