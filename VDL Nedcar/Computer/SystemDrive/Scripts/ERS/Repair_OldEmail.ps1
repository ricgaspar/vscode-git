﻿# ---------------------------------------------------------
# Repair_Users_CtxProf
#
# Marcel Jussen
# 29-8-2013
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $false

Function Repair_User_OldEmail {
	param (
		$Username
	)
	
	# Convert to uppercase
	$Username = $Username.ToUpper()	
	$Result = Search-AD-User $Username
	if ($Result -ne $null) {								
		$objOU = [ADSI]$Result
		
		$CurEmail = $objOU.mail.value		
		if($CurEmail -ne $null) {
			$CurEmailTemp = $CurEmail.ToUpper()
			if($CurEmailTemp.Contains("@NEDCAR.NL")) {
				Echo-Log "User $Username has an old @nedcar.nl primary email address [$CurEmail]."
				$objOU.PutEx(1, "mail", 0)
    			$objOU.SetInfo()
				$Global:Changes_Committed++
			}
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
$logfile = "Secdump-Repair_Users_OldEmail-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"
Echo-Log ("-"*60)

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

Echo-Log "Inventory users accounts in the domain."
$userCol = Get-ADUsersSAM

Echo-Log "Checking user accounts for old email address."
foreach($User in $userCol) {
	$path = $User.Path
	if($path -ne $null) {
		$path = $path.ToUpper()
		if($path.Contains("OU=NEDCAR,DC=NEDCAR,DC=NL")) {			
			$obj = [ADSI]$path
			$SamAccountName = $obj.sAMAccountName.value
			Repair_User_OldEmail $SamAccountName
		}
	}
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if ($Global:Changes_Committed -ne 0) {
	$Title = "Repair User old email. $cdtime ($Global:Changes_Committed changes committed)" 	
} else {
	$Title = "Repair User old email. $cdtime (No changes committed)" 
}

if($Global:DEBUG) {
	Echo-Log "** Debug: Sending resulting log as a mail message."
} 

$SendTo = "nedcar-events@kpn.com"
$dnsdomain = Get-DnsDomain
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

# Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title