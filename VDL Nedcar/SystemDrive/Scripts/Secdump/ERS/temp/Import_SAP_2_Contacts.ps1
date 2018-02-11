﻿# ---------------------------------------------------------
# SAP_2_AD_Contacts
# Marcel Jussen
# 28-11-2012
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

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
			Echo-Log "Connect to object [$LDAP]"
			$Global:Changes_Proposed += 1
			
			# Connect via ADSI to LDAP object
			$LDAPObj=[ADSI]$LDAP
			
			# check if the returned object is of type contact, if not exit with value false
			if ( ($LDAPObj | Get-Member | Select-Object –ExpandProperty Name) –contains "objectClass" ) {
				$class = $LDAPObj.objectClass
				$classtype = $class[3]
				if ($classtype -ne "contact") { return $false } 
			} else { 
				return $false
			}
			
			# Check if this property exist within the ADSI person object
			if ( ($LDAPObj | Get-Member | Select-Object –ExpandProperty Name) –contains $Parameter ) {
				$curval = $LDAPObj.Get($Parameter)
			} else {
				# if the property does not exist, save current value to empty value
				$curval = ""
			} 
			
			if($string.Length -ne 0) {								
				# Check if current value and changed value have differences
				if(ChkStringDiff -Astring $curval -BString $String) {
					Echo-Log "* Actual field [$Parameter] value: [$curval]"
					Echo-Log "* Change field [$Parameter] to   : [$String]"
					
					# Commit new value to parameter.										
					$LDAPObj.Put($Parameter, $string)
					$LDAPObj.SetInfo()
					$Global:Changes_Committed += 1
				} else {					
					Echo-Log "No change to field [$Parameter] is needed. Value: [$curval / $String]"
				}
			} else {
				if ($curval.Length -ne 0) { 					
					# If new value is empty, delete the value in AD
					Echo-Log "* Delete field [$Parameter] which was $curval"
					# $LDAPObj.PutEx(1, $Parameter, 0)
    				# $LDAPObj.SetInfo()
					$Global:Changes_Committed += 1
				} else {
					Echo-Log "No change to field [$Parameter] is needed. Value is already empty."
				}
			}	
			
		} else { return $false } 
	} else { return $false } 
	return $true
}

Function Create-MailBody {
	param (
		[string]$LogFileToSend,
		[string]$HeadlineText
	)
	
$mailcontent = @'
<body>	
	<div id="wrap">		
		<div style="float:left; width: 95%">
		<!-- 
			<div id="content" width: 95%;">
				<img src="cid:logo" "alt=logo"/>				
			</div>						
		 -->
			<div id="headline">
				<p>
'@				
$mailcontent += $HeadlineText
$mailcontent += @'				
				</p>		
			</div>
			<div id="content" >
				<table id="box-table-a" summary="table-list">
					<thead>
						<tr>
							<th scope="col">
'@											
$mailcontent += "Contents of the log:"
$mailcontent += @'				
							</th>
						</tr>
					</thead>
					<tbody>
'@			
(Get-Content $LogFileToSend) | Foreach-object { $mailcontent += "<TR><TD>$_</TD></TR>" }
$mailcontent += @'		
					</tbody>
				</table>
			</div>			
			<div id="content" >								
				<p>This email was automatically generated. Please do not reply to this email.</p>			
			</div>
		</div>
		<div style="clear:both"></div>
		<div id="footer">
	  		<div class="right">
  			<p>Netherlands Car b.v.</p>
		  </div>	  
		</div>
	</div>	
</body>
</html>
'@

	return $mailcontent
}

Function SendEmail_Log {
	param (
		[string]$FromAddress,
		[string]$ToAddress,
		[string]$SMTPServer,
		[string]$Subject,
		[string]$Headline,
		[string]$Logfile
	)
	
	$mail = new-object System.Net.Mail.MailMessage
	
#	$Attachment = New-Object System.Net.Mail.Attachment( "logo-vdl-nl-small.jpg" )
#	$Attachment.ContentDisposition.Inline = $true
#	$Attachment.ContentDisposition.DispositionType = "Inline"
#	$Attachment.ContentType.MediaType = "image/jpg"
#	$Attachment.ContentId = "logo"

	$CSS = "css_styles.html"
	$CSS_Styles = $null
	if (Test-Path $CSS) { $CSS_Styles = Get-Content $CSS } 

$mailcontent = @'
<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:v="urn:schemas-microsoft-com:vml">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="pragma" content="no-cache">
'@	
$mailcontent += $CSS_Styles

$mailcontent += Create-MailBody $Logfile $Headline

$mailcontent += @'
</head>
'@ 

	$messageParameters = @{
		From       = $FromAddress
		To         = $ToAddress
		SmtpServer = $SMTPServer
		Subject    = $Subject
		Body       = $mailcontent
	}

	$mail.To.Add( $messageParameters.To )
	$mail.To.Add( "mjussen@vdlnedcar.nl" )
	$mail.From       = $messageParameters.From
	$mail.Subject    = $messageParameters.Subject
	$mail.Body       = $messageParameters.Body
	$mail.IsBodyHtml = $true
# 	$mail.Attachments.Add( $attachment )
	$mail.Attachments.Add( $Logfile )

##
## now send the email
##
	$smtpClient = new-object system.net.mail.smtpclient( $messageParameters.SmtpServer )
	$smtpClient.Send( $mail )

	$smtpClient = $null
	$attachment = $null
	$mail       = $null
	$log		= $null
}

Function Change-ADUsersProps {

	# ------------------------------------------------------------------------------
	# Connect to SQL server

	Echo-Log "Opening SQL connection to $Global:SECDUMP_SQLServer"
	Echo-Log "Accessing database $Global:SECDUMP_SQLDB"
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	$SQLVersion = $SQLconn.ServerVersion
	if ($SQLconn.state -eq "Closed") { 
		Error-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	} else {
		Echo-Log $SQLconn.ConnectionString
		Echo-Log "Server version: $SQLVersion"		
		Echo-Log ("-"*60)
	}

	#Init return value
	$ErrorVal = 0
	$DefaultCompany = "NedCar"

	$query = "select * from VW_PD_CONTACTS order by ISP_USERID"
	Echo-Log "Parse query: $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		Echo-Log "Number of records returned: $reccount"
		Echo-Log ("-"*60)
		ForEach($rec in $data) {
	
			$DN = $rec.DN		
			$LDAP = "LDAP://" + $DN				
		
			# ---------- FIRSTNAME ---------- 
			$ISP_FIRST_NAME = $rec.ISP_FIRST_NAME.Trim()						
			$GivenName = $rec.Givenname			
			if (ChkStringDiff -AString $GivenName -BString $ISP_FIRST_NAME) {			
				[Void](Put_ADStringVal $LDAP "givenName" $ISP_FIRST_NAME)
			}					
		
			# ---------- SN (SURNAME) ---------- 		
			$ISP_LAST_NAME = $rec.ISP_LAST_NAME.Trim()
			if(($ISP_LAST_NAME -ne $null) -and ($ISP_LAST_NAME.Length -gt 0)) {
				$ISP_MIDDLE_NAME = $rec.ISP_MIDDLE_NAME.Trim()
				if(($ISP_MIDDLE_NAME -ne $null) -and ($ISP_MIDDLE_NAME.Length -gt 0)) {
					$ISP_LAST_NAME = $ISP_LAST_NAME + " " + $ISP_MIDDLE_NAME
					$ISP_LAST_NAME = $ISP_LAST_NAME.Trim()
				}
			}
		
			$sn = $rec.sn
			if (ChkStringDiff -AString $sn -BString $ISP_LAST_NAME) {				
				[Void](Put_ADStringVal $LDAP "sn" $ISP_LAST_NAME)
			}
		
			# ---------- DISPLAY NAME ---------- 					
			$ISP_MIDDLE_NAME = $rec.ISP_MIDDLE_NAME.Trim()
			$ISP_LAST_NAME = $rec.ISP_LAST_NAME.Trim()
			if(($ISP_MIDDLE_NAME -ne $null) -and ($ISP_MIDDLE_NAME.Length -gt 0)) {
				$ISP_MIDDLE_NAME = $ISP_MIDDLE_NAME.ToLower()
				$ISP_DISPLAYN = $ISP_LAST_NAME + " " + $ISP_MIDDLE_NAME			
			} else {
				$ISP_DISPLAYN = $ISP_LAST_NAME
			}
			$ISP_DISPLAYN = $ISP_DISPLAYN.Trim()
		
			if(($ISP_FIRST_NAME -ne $null) -and ($ISP_FIRST_NAME.Length -gt 0)) {
				$ISP_DISPLAYN += ", " + $ISP_FIRST_NAME
				$ISP_DISPLAYN = $ISP_DISPLAYN.Trim()
			}
		
			$displayname = $rec.displayname
			if (ChkStringDiff -AString $displayname -BString $ISP_DISPLAYN) {		
				[Void](Put_ADStringVal $LDAP "displayname" $ISP_DISPLAYN)
			}
		
			# ---------- DEPARTMENT ---------- 
			# ---------- DESCRIPTION ---------- 
			$ISP_DEPARTMENT_NAME = $rec.ISP_DEPARTMENT_NAME.Trim()
			$ISP_DEPARTMENT_NR = $rec.ISP_DEPARTMENT_NR.Trim()
			if ($ISP_DEPARTMENT_NR.length -gt 4) { 
				$ISP_DEPARTMENT_NR = $ISP_DEPARTMENT_NR.substring(3)
			}
			$DepString = "(" + $ISP_DEPARTMENT_NR + ") " + $ISP_DEPARTMENT_NAME
			$Department = $rec.department
			if (ChkStringDiff -AString $Department -BString $DepString) {				
				[void](Put_ADStringVal $LDAP "Department" $DepString)
				[void](Put_ADStringVal $LDAP "Description" $ISP_DEPARTMENT_NR)
			}
		
			# ---------- TELEPHONENUMBER ---------- 
			$ISP_EXTENSION = $rec.ISP_EXTENSION.Trim()	
			$telephoneNumber = $rec.telephoneNumber
			if (ChkStringDiff -AString $telephoneNumber -BString $ISP_EXTENSION) {				
				[Void](Put_ADStringVal $LDAP "telephoneNumber" $ISP_EXTENSION)
			}		
		
			# ---------- FAX ---------- 			
			$ISP_FAX = $rec.ISP_FAX.trim()
			$fax = $rec.fax
			if (ChkStringDiff -AString $Fax -BString $ISP_FAX) {				
				[void](Put_ADStringVal $LDAP "facsimileTelephoneNumber" $ISP_FAX)
			}			
		
			# ---------- GSM ---------- 
			$ISP_GSM = $rec.ISP_GSM
			$VarType = $ISP_GSM.GetType()
			if($VarType.Fullname -eq "System.DBNull") { $ISP_GSM="" }
			if($ISP_GSM -ne $null) { $ISP_GSM = $ISP_GSM.Trim() }
			$Mobile = $rec.MobilePhone
			if (ChkStringDiff -AString $Mobile -BString $ISP_GSM) {				
				[void](Put_ADStringVal $LDAP "mobile" $ISP_GSM)
			}
		
			# ---------- Title ---------- 
			$ISP_FUNCTION = $rec.ISP_FUNCTION.Trim() 
			$Title = $rec.Title
			if (ChkStringDiff -AString $Title -BString $ISP_FUNCTION) {				
				[void](Put_ADStringVal $LDAP "title" $ISP_FUNCTION)
			}
		
			# ---------- Company ---------- 
			$ISP_REG_NR = $rec.ISP_REG_NR.Trim() 
			$Company = $rec.Company
			$lead = $ISP_REG_NR.SubString(0,3)
			$ld = $lead.CompareTo("000")
			if( $ld -eq 0) {
				if (ChkStringDiff -AString $Company -BString $DefaultCompany) {				
					[Void](Put_ADStringVal $LDAP "Company" $DefaultCompany)
				}
			} else {
				if (ChkStringDiff -AString $Company -BString "External") {				
					[void](Put_ADStringVal $LDAP "Company" "External")
				}
			}			
		
		}			
	} else {
		Echo-Log "No records found."
	}	

	# ------------------------------------------------------------------------------
	Echo-Log ("-"*60)
	Echo-Log "Differences found in SQL table          : $Global:Changes_Proposed"
	Echo-Log "Changes committed to Active Directory   : $Global:Changes_Committed"
	
	return $ErrorVal
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-SAP_2_Contacts-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

Change-ADUsersProps

Echo-Log ("-"*60)
Echo-Log "Closing SQL connection."
Remove-SQLconnection $SQLconn
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

$dt = Get-Date
$Title = "SAP to Active Directory Contacts import. " + $dt
if ($Global:Changes_Committed -ne 0) {
	SendEmail_Log -FromAddress "mjussen@vdlnedcar.nl" -SMTPServer "smtp.nedcar.nl" -ToAddress "mjussen@vdlnedcar.nl" -Subject $title -LogFile $GlobLog -Headline $Title
} else {
	$TempLog = $env:TEMP + "\templog.txt"
	if($Global:Changes_Proposed -ne 0) {
		$LogText = "Changes were proposed from SAP but none had to be committed to Active Directory." 
	} else {
		$LogText = "No changes had to be made from SAP to Active Directory."		
	}
	$logText | Out-File -FilePath $TempLog
	SendEmail_Log -FromAddress "mjussen@vdlnedcar.nl" -SMTPServer "smtp.nedcar.nl" -ToAddress "mjussen@vdlnedcar.nl" -Subject $title -LogFile $TempLog -Headline $Title
	Remove-Item -Path $TempLog -ErrorAction SilentlyContinue
}

