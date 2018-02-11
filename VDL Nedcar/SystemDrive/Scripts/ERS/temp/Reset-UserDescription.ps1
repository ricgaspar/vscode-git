# ---------------------------------------------------------
# Reset User Notes
#
# Marcel Jussen
# 13-5-2013
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

$Global:DEBUG = $false

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
  			<p>VLD Nedcar</p>
		  </div>	  
		</div>
	</div>	
</body>
</html>
'@

	return $mailcontent
}

#----
# Create an HTM email body to send as email to SMPT server
# Contents of the email are taken from logfile $LogFile
#----
Function SendEmail_Log {
	param (
		[string]$FromAddress,
		[string]$ToAddress,
		[string]$SMTPServer = "smtp.nedcar.nl",
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

	$CSS = "C:\Scripts\Powershell\SAP\css_styles.html"
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

Function Reset_UserNotes_ADObject {
	Param (
		[string]$DN		
	)	
	if($DN -eq $null) { return -1 }
	if($DN.Length -eq 0) { return -1 } 		
	
	$OrigDN = "LDAP://" + $DN
	
	# NULL will erase the value of the info field.
	$Description = $null
	
	Echo-Log "Resetting notes on $OrigDN"
	if(!$Global:DEBUG) { 
		$t = Set-ADObj-Info $OrigDN $Description 
		$Global:Changes_Committed++
	}
}

#
# Query SEDCUMP for list of external users that must be moved to their appropriate OU.
#
Function ResetNotes_AD_Accounts {
	# ------------------------------------------------------------------------------
	# Connect to SQL server

	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Error-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

	#Init return value
	$ErrorVal = 0	
	
	$query = "select * from VW_PND_ACCOUNTS_INVALID_NOTES"
	Echo-Log "Parse query: $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 } 
		Echo-Log "Number of records returned: $reccount"
		$Global:Changes_Proposed = $reccount
		Echo-Log ("-"*60)
		ForEach($rec in $data) {			
		
			# Retrieve data from SQL record			
			$PND_DN = Reval_Parm $rec.DN					
			Reset_UserNotes_ADObject  $PND_DN 						
		}			
	} else {
		Echo-Log "No records found."
	}	
	
	# ------------------------------------------------------------------------------
	Echo-Log ("-"*60)	
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log "Proposed changes found in SQL result    : $Global:Changes_Proposed"
	Echo-Log "Changes committed to Active Directory   : $Global:Changes_Committed"
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log ("-"*60)	
	Echo-Log "Closing SQL connection."
	Remove-SQLconnection $SQLconn
	return $ErrorVal
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Reset_Info_field_Users_From_PND-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

[void](ResetNotes_AD_Accounts)

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

$SendTo = "mjussen@vdlnedcar.nl"
if ($Global:Changes_Committed -ne 0) {
	$Title = "Reset info field on user accounts in AD. $cdtime ($Global:Changes_Committed changes committed to AD)" 	
	if($Global:DEBUG) {
		Echo-Log "** Debug: Sending resulting log as a mail message."
	} else {
		SendEmail_Log -FromAddress "mjussen@vdlnedcar.nl" -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
	}
}

