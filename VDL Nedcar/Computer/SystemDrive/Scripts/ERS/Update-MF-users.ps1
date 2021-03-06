# ---------------------------------------------------------
# Change MF (multi-functional) user account information 
# from ERS to Active Directory
#
# Marcel Jussen
# 21-7-2015
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
$Global:SQLChanges_Proposed = 0

$Global:DEBUG = $false
$Global:CurDN = $null

Function ChkStringDiff {
# Compare two strings with case sensitivity and return true when they are different
	Param (
		[string]$AString,
		[string]$BString
	)
	$retval = $false
	if ($AString.Length -gt 0) {
		$AString = $AString.Trim()
		if ($BString.Length -gt 0) {			
			$BString = $BString.Trim()
			$d = [string]::Compare($AString, $BString, $False)
			$retval = ($d -ne 0) 							
		} else {
			$retval = $true
		}
	} else {
		if ($BString.Length -gt 0) { $retval = $true }
	}
	return $retval
}

Function Put_ADStringVal {
	param (
		[string]$LDAP,
		[string]$Parameter,
		[string]$String		
	)	
	
	if($LDAP -ne $null) {
		if($LDAP.Length -gt 0) {			
			$Global:Changes_Proposed += 1	
			
			# Connect via ADSI to LDAP object
			$LDAPObj=[ADSI]$LDAP
			
			# Show which object in AD we are changing only once per object
			if($Global:CurDN -ne $LDAP) {				
				$Global:CurDN = $LDAP
			}
			
			# check if the returned object is of type organizationalPerson, if not exit with value false
			if ( ($LDAPObj | Get-Member | Select-Object –ExpandProperty Name) –contains "objectClass" ) {
				$class = $LDAPObj.objectClass
				$classtype = $class[2]
				if ($classtype -ne "organizationalPerson") { return $false } 
			} else { 
				Error-Log "ERROR: Object is not of type organizationalPerson or does not exist."
				return $false
			}
			
			# Check if this property exist within the ADSI person object
			if ( ($LDAPObj | Get-Member | Select-Object –ExpandProperty Name) –contains $Parameter ) {
				$curval = $LDAPObj.Get($Parameter)
			} else {
				# if the property does not exist, save current value as an empty value
				$curval = ""
			} 						
			
			if($string.Length -ne 0) {								
				# Check if current value and changed value have differences
				if(ChkStringDiff -Astring $curval -BString $String) {						
					Echo-Log "[$LDAP]: Change [$Parameter]: [$curval] to [$String]"					
					# Commit new value to parameter.
					if($Global:DEBUG -eq $false) {
						$LDAPObj.Put($Parameter, $string)
						$LDAPObj.SetInfo()
						$Global:Changes_Committed += 1
					} else {
						Echo-Log "** DEBUG mode : changes are not committed."
					}
				} else {					
					Echo-Log "[$LDAP]: Change [$Parameter] is not needed."
				}
			} else {
				if ($curval.Length -ne 0) { 					
					# If new value is empty, delete the value in AD
					Echo-Log "[$LDAP]: Delete field [$Parameter] which was $curval"
					if($Global:DEBUG -eq $false) {
						$LDAPObj.PutEx(1, $Parameter, 0)
    					$LDAPObj.SetInfo()
						$Global:Changes_Committed += 1
					} else {
						Echo-Log "[$LDAP]: DEBUG mode : changes are not committed."
					}
				} else {
					Echo-Log "[$LDAP]: No change [$Parameter] is needed. Value is already empty."
				}
			}				
		} else { return $false } 
	} else { return $false } 
	return $true
}

#----
# Check type of variable returned by SQL
# If type DBNull then replace with empty string
#----
Function Reval_Parm { 
	Param (
		$Parm
	)
	if(($Parm -eq $null) -or ($Parm.Length -eq 0)) { $Parm = "" }
	$VarType = $Parm.GetType()	
	if($VarType.Fullname -eq "System.DBNull") { $Parm = "" }
	if($Parm -ne $null) { $Parm = $Parm.trim() }
	Return $Parm
} 

Function MF_Update {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_DHCP_MF_Useraccounts"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAPObj = "LDAP://" + $DN	
			
			# Firstname must be empty
			$SecdumpValue = ''
			$ParameterName = 'firstname'
			[void](Put_ADStringVal $LDAPObj $Parametername $SecdumpValue)

			# Lastname must be equal to 'Canon'
			$SecdumpValue = 'Canon'
			$ParameterName = 'sn'
			[void](Put_ADStringVal $LDAPObj $Parametername $SecdumpValue)

			# Displayname must be equal to 'Multifunctional PSxxx
			$PSName = (Reval_Parm $rec.PSName)
			$GuessedName = (Reval_Parm $rec.GuessedName)
			if($PSName) { 
				if($PSName.Length -gt 0) { 
					$Printername = ' ' + $PSName
				} else {
					$Printername = ' ' + $GuessedName
				}
			} else {
				$Printername = ' ' + $GuessedName
			}
			
			$SecdumpValue = 'Multifunctional' + $PrinterName
			$ParameterName = 'displayname'
			[void](Put_ADStringVal $LDAPObj $Parametername $SecdumpValue)			
			
			# Description must equal the IP_Address
			$SecdumpValue = Reval_Parm $rec.IP_Address
			$ParameterName = 'description'
			[void](Put_ADStringVal $LDAPObj $Parametername $SecdumpValue)
						
			$SecdumpValue = ''
			$ParameterName = ''			
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	rv SQLconn
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-MF-Users-update-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode : Changes are not committed." }

MF_Update

Echo-Log ("-"*60)
Echo-Log "SQL queries total proposed changes      : $Global:SQLChanges_Proposed"
Echo-Log "Actual differences proposed             : $Global:Changes_Proposed"
Echo-Log "Changes committed to Active Directory   : $Global:Changes_Committed"
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if($Global:DEBUG) { 
	Echo-Log "** DEBUG mode: changes are not committed." 
	return	
}

$SendTo = "events@vdlnedcar.nl"
$dnsdomain = Get-DnsDomain
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

if ($Global:Changes_Committed -ne 0) {
	$Title = "Multifunctional user accounts update. $cdtime ($Global:Changes_Committed changes committed to AD)"
	Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
} else {
	$Title = "ERS to Active Directory import. $cdtime (No changes commited to AD)"
	$TempLog = $env:TEMP + "\templog.txt"
	$LogText = $Title
	$logText | Out-File -FilePath $TempLog
	Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
	Remove-Item -Path $TempLog -ErrorAction SilentlyContinue
}
