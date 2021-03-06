# ---------------------------------------------------------
# Change user account information from ERS to Active Directory
#
# Marcel Jussen
# 8-9-2016
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0
$Global:SQLChanges_Proposed = 0

$Global:DEBUG = $false
$Global:CurDN = $null

$Global:SMTPRelayAddress = "mail.vdlnedcar.nl"

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

Function SAP2AD_Firstname {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_FIRSTNAME"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count	
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			# ---------- FIRSTNAME ---------- 
			$ISP_FIRST_NAME = Reval_Parm $rec.ISP_FIRST_NAME
			$GivenName = Reval_Parm $rec.Givenname			
			if (ChkStringDiff -AString $GivenName -BString $ISP_FIRST_NAME) {			
				[Void](Put_ADStringVal $LDAP "givenName" $ISP_FIRST_NAME)
			}
			$ISP_FIRST_NAME = ""
			$GivenName = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_Lastname {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_LASTNAME"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN		
			
			# ---------- LASTNAME en SN (SURNAME) ---------- 		
			$LASTN = Reval_Parm $rec.LASTN			
			$sn = Reval_Parm $rec.sn
			if (ChkStringDiff -AString $sn -BString $LASTN) {				
				[Void](Put_ADStringVal $LDAP "sn" $LASTN)
			}
			$LASTN = ""
			$sn = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_Displayname {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_DISPLAYNAME"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count	
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- DISPLAY NAME ----------
			# Logic which creates the display name is located in the SQL query (5-2-2013)
			
			$ISP_DISPLAYN = Reval_Parm $rec.DISPLAYN								
			$displayname = Reval_Parm $rec.displayname
			if (ChkStringDiff -AString $displayname -BString $ISP_DISPLAYN) {		
				[Void](Put_ADStringVal $LDAP "displayname" $ISP_DISPLAYN)
			} else {
				Echo-Log "** Invalid    : $displayname, $ISP_DISPLAYN "
			}
			$ISP_DISPLAYN = ""
			$displayname = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_Title {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_TITLE"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- Title ---------- 
			$ISP_FUNCTION = Reval_Parm $rec.ISP_FUNCTION 
			$Title = Reval_Parm $rec.Title
			if (ChkStringDiff -AString $Title -BString $ISP_FUNCTION) {				
				[void](Put_ADStringVal $LDAP "title" $ISP_FUNCTION)
			}
			$ISP_FUNCTION = ""
			$Title = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_Department {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_DEPARTMENT"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- DEPARTMENT ---------- 			
			$ISP_DEPARTMENT_NAME = Reval_Parm $rec.ISP_DEPARTMENT_NAME
			$ISP_DEPARTMENT_NR = Reval_Parm $rec.ISP_DEPARTMENT_NR
			if ($ISP_DEPARTMENT_NR.length -gt 4) { 
				$ISP_DEPARTMENT_NR = $ISP_DEPARTMENT_NR.substring(3)
			}
			$DepString = "(" + $ISP_DEPARTMENT_NR + ") " + $ISP_DEPARTMENT_NAME
			$Department = Reval_Parm $rec.department
			if (ChkStringDiff -AString $Department -BString $DepString) {				
				[void](Put_ADStringVal $LDAP "Department" $DepString)				
			}
			$ISP_DEPARTMENT_NAME = ""
			$ISP_DEPARTMENT_NR = ""
			$Department = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_TelephoneNumber {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_TELEPHONENUMBER"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- TELEPHONENUMBER ---------- 
			$ISP_EXTENSION = Reval_Parm $rec.ISP_EXTENSION	
			$telephoneNumber = Reval_Parm $rec.telephoneNumber
			if (ChkStringDiff -AString $telephoneNumber -BString $ISP_EXTENSION) {				
				[Void](Put_ADStringVal $LDAP "telephoneNumber" $ISP_EXTENSION)
			}
			$ISP_EXTENSION = ""
			$telephoneNumber = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_TelephoneNumber_Other {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_TELEPHONENUMBER_OTHER"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- OTHERTELEPHONE ---------- 
			$otherTelephone = Reval_Parm $rec.otherTelephone
			$OTel = Reval_Parm $rec.OTel
			if (ChkStringDiff -AString $otherTelephone -BString $OTel) {				
				[Void](Put_ADStringVal $LDAP "otherTelephone" $OTel)
			}
			$otherTelephone = ""
			$OTel = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_Fax {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_FAX"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- FAX ---------- 
			$ISP_FAX = Reval_Parm $rec.ISP_FAX			
			$fax = Reval_Parm $rec.fax
			if (ChkStringDiff -AString $Fax -BString $ISP_FAX) {				
				[void](Put_ADStringVal $LDAP "facsimileTelephoneNumber" $ISP_FAX)
			}
			$ISP_FAX = ""
			$fax = ""
			
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_MobilePhone {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_MOBILEPHONE"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- MOBILEPHONE ---------- 
			$ISP_GSM = Reval_Parm $rec.ISP_GSM			
			$Mobile = Reval_Parm $rec.MobilePhone
			if (ChkStringDiff -AString $Mobile -BString $ISP_GSM) {				
				[void](Put_ADStringVal $LDAP "mobile" $ISP_GSM)
			}
			$ISP_GSM = ""
			$Mobile = ""
			
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_Company {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_COMPANY"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- Company ---------- 
			$ISP_REG_NR = Reval_Parm $rec.ISP_REG_NR 
			$Company = Reval_Parm $rec.Company
			$DefaultCompany = Reval_Parm $rec.ISP_COMPANY_NAME			
			$lead = $ISP_REG_NR.SubString(0,3)			
			
			if (ChkStringDiff -AString $Company -BString $DefaultCompany) {				
				[Void](Put_ADStringVal $LDAP "Company" $DefaultCompany)
			}
						
			$ISP_REG_NR = ""
			$Company = ""	
			$DefaultCompany = ""
			$lead = "" 
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

Function SAP2AD_Description {
	# Connect to SQL database
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB	
	if ($SQLconn.state -eq "Closed") {
		Error-Log "The SQL connection could not be made or is forcefully closed."	
	}
	
	#Query to execute
	Echo-Log ("-"*60)
	$query = "select * from vw_PND_CHANGE_DESCRIPTION"
	Echo-Log "Parse query   : $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if($reccount -eq $null) { $reccount = 1 }
		$Global:SQLChanges_Proposed += $reccount
		Echo-Log "Result        : $reccount records returned."		
		ForEach($rec in $data) {	
			$DN = Reval_Parm $rec.DN		
			$LDAP = "LDAP://" + $DN				
			
			# ---------- DEPARTMENT ---------- 						
			$ISP_DEPARTMENT_NR = Reval_Parm $rec.ISP_DEPARTMENT_NR			
			$Description = Reval_Parm $rec.Description
			$CorrectDesc = Reval_Parm $rec.CorrectDesc
			if (ChkStringDiff -AString $Description -BString $CorrectDesc) {				
				[void](Put_ADStringVal $LDAP "Description" $CorrectDesc)				
			}
			$ISP_DEPARTMENT_NR = ""
			$Description = ""
			$CorrectDesc = ""
		}
	} else {
		Echo-Log "Result        : No records returned."
	}
	Remove-SQLconnection $SQLconn	
	Remove-Variable SQLconn
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Update-Users-from-ERS-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode : Changes are not committed." }

SAP2AD_Firstname
SAP2AD_Lastname
SAP2AD_Displayname
SAP2AD_Title
SAP2AD_Department
SAP2AD_TelephoneNumber
SAP2AD_TelephoneNumber_Other
SAP2AD_Fax
SAP2AD_MobilePhone
SAP2AD_Company
SAP2AD_Description

Echo-Log ("-"*60)
Echo-Log "SQL queries total proposed changes      : $Global:SQLChanges_Proposed"
Echo-Log "Actual differences proposed             : $Global:Changes_Proposed"
Echo-Log "Changes committed to Active Directory   : $Global:Changes_Committed"
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
$query = "INSERT INTO [dbo].[VNB_PND_HISTORY_MAINTAIN_USERS] ([Systemname],[Domainname],[Poldatetime],[SQLChanges_Proposed],[Changes_Proposed],[Changes_Committed])" + `
			"VALUES ('" + $ENV:COMPUTERNAME + "','" + $ENV:USERDOMAIN + "'," + `
			"Getdate(),$($Global:SQLChanges_Proposed),$($Global:Changes_Proposed),$($Global:Changes_Committed))"
$data = Query-SQL $query $SQLconn

if($Global:DEBUG) { 
	Echo-Log "** DEBUG mode: changes are not committed." 
	return	
}

Close-LogSystem


$computername = $Env:computername
$SendFrom = "ERS PS Scripts Active Directory <$computername@vdlnedcar.nl>"

$MainTitle = 'ERS: Update Active Directory user accounts.'
if ($Global:Changes_Committed -ne 0) {
	$Title = "$MainTitle [$Global:Changes_Committed changes committed to AD]"
	
	$SendTo = "events@vdlnedcar.nl"
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
	$SendTo = "helpdesk@vdlnedcar.nl"
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
	
} else {

	$Title = "$MainTitle [No changes commited to AD]"
	$TempLog = $env:TEMP + "\templog.txt"
	$LogText = $Title
	$logText | Out-File -FilePath $TempLog
	
	$SendTo = "events@vdlnedcar.nl"
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
	$SendTo = "helpdesk@vdlnedcar.nl"
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
	
	Remove-Item -Path $TempLog -ErrorAction SilentlyContinue
}