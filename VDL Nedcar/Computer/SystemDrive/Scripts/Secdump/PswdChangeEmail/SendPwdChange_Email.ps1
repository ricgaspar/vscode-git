# ---------------------------------------------------------
#
# Marcel Jussen
# 09-01-2016
# ---------------------------------------------------------

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$Global:Chg_Email_Proposed = 0
$Global:Chg_Email_Comitted = 0

############################
$Global:DEBUG = $false
############################

$Global:SentToAddress 		= 'events@vdlnedcar.nl'
$Global:SendFromAddress		= 'helpdesk@vdlnedcar.nl'
$Global:SendFromAdressName	= 'VDL Nedcar IT Helpdesk'
$Global:SMTPRelayAddress	= 'mail.vdlnedcar.nl'
$Global:SendFrom = $(gc env:computername) + '@vdlnedcar.nl'

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
	if($VarType.Fullname -eq 'System.DBNull') { $Parm = "" }
	if($Parm -ne $null) { 
		$VarType = $Parm.GetType()
		if($VarType -eq 'System.String') { $Parm = $Parm.trim() }
	}
	Return $Parm
} 

function Send-HTMLFormattedEmail {
	<# 
	.Synopsis
    	Used to send an HTML Formatted Email.
    .Description
    	Used to send an HTML Formatted Email that is based on an XSLT template.
	.Parameter To
		Email address or addresses for whom the message is being sent to.
		Addresses should be seperated using ;.
	.Parameter ToDisName
		Display name for whom the message is being sent to.
	.Parameter CC
		Email address if you want CC a recipient.
		Addresses should be seperated using ;.
	.Parameter BCC
		Email address if you want BCC a recipient.
		Addresses should be seperated using ;.
	.Parameter From
		Email address for whom the message comes from.
	.Parameter FromDisName
		Display name for whom the message comes from.
	.Parameter Subject
		The subject of the email address.
	.Parameter Content
		The content of the message (to be inserted into the XSL Template).
	.Parameter Relay
		FQDN or IP of the SMTP relay to send the message to.
	.XSLPath
		The full path to the XSL template that is to be used.
	#>
    param (
		[Parameter(Mandatory=$True)][String]$To,
		[Parameter(Mandatory=$True)][String]$ToDisName,
		[String]$CC,
		[String]$BCC,
		[Parameter(Mandatory=$True)][String]$From,
		[Parameter(Mandatory=$True)][String]$FromDisName,
		[Parameter(Mandatory=$True)][String]$Subject,
		[Parameter(Mandatory=$True)][String]$Content,
		[Parameter(Mandatory=$True)][String]$UID,
		[Parameter(Mandatory=$True)][String]$Relay,
		[Parameter(Mandatory=$True)][String]$XSLPath,
		[string]$FilePath
	)
    
    try {
		
		# Create a MailMessage object 
        $Message = New-Object System.Net.Mail.MailMessage
		
		# Add file attachment if found
		if(Test-Path($FilePath)) {
			$Message.Attachments.Add($FilePath)
		}
		
		# The logo used in signature
		$Logopic = $glb_LogoPath
		# add the logo attachment, and set it to inline.
		$Attachment = New-Object Net.Mail.Attachment($Logopic)
		$Attachment.ContentDisposition.Inline = $True
		$Attachment.ContentDisposition.DispositionType = "Inline"
		$Attachment.ContentType.MediaType = "image/jpg"
		$Logo = "cid:logo" 
				
        # Load XSL Argument List
        $XSLArg = New-Object System.Xml.Xsl.XsltArgumentList
        $XSLArg.Clear() 
        $XSLArg.AddParam("To", $Null, $ToDisName)
        $XSLArg.AddParam("Content", $Null, $Content)
		$XSLArg.AddParam("UID", $Null, $UID)
		$XSLArg.AddParam("Logo", $Null, $Logo)
		
        # Load Documents
        $BaseXMLDoc = New-Object System.Xml.XmlDocument
        $BaseXMLDoc.LoadXml("<root/>")

        $XSLTrans = New-Object System.Xml.Xsl.XslCompiledTransform
        $XSLTrans.Load($XSLPath)

        #Perform XSL Transform
        $FinalXMLDoc = New-Object System.Xml.XmlDocument
        $MemStream = New-Object System.IO.MemoryStream
     
        $XMLWriter = [System.Xml.XmlWriter]::Create($MemStream)
        $XSLTrans.Transform($BaseXMLDoc, $XSLArg, $XMLWriter)

        $XMLWriter.Flush()
        $MemStream.Position = 0
     
        # Load the results
        $FinalXMLDoc.Load($MemStream) 
        $Body = $FinalXMLDoc.Get_OuterXML()		
		
		# Populate the Message.
		$html = [System.Net.Mail.AlternateView]::CreateAlternateViewFromString($body, $null, "text/html")
		$imageToSend = new-object system.net.mail.linkedresource($Logopic,"image/jpg")
		$imageToSend.ContentID = "logo"
		$html.LinkedResources.Add($imageToSend)
		$message.AlternateViews.Add($html)
		
        $Message.Subject = $Subject
        $Message.IsBodyHTML = $True		
		
		# Add From
        $MessFrom = New-Object System.Net.Mail.MailAddress $From, $FromDisName
		$Message.From = $MessFrom

		# Add To
		$To = $To.Split(";") # Make an array of addresses.
		$To | foreach {$Message.To.Add((New-Object System.Net.Mail.Mailaddress $_.Trim()))} # Add them to the message object.
		
		# Add CC
		if ($CC){
			$CC = $CC.Split(";") # Make an array of addresses.
			$CC | foreach {$Message.CC.Add((New-Object System.Net.Mail.Mailaddress $_.Trim()))} # Add them to the message object.
		}

		# Add BCC
		if ($BCC){
			$BCC = $BCC.Split(";") # Make an array of addresses.
			$BCC | foreach {$Message.BCC.Add((New-Object System.Net.Mail.Mailaddress $_.Trim()))} # Add them to the message object.
		}
     
        # Create SMTP Client
        $Client = New-Object System.Net.Mail.SmtpClient $Relay

        # Send The Message
		$Client.Send($Message)
	}
	catch {
		throw $_
    }   
	$attachment.Dispose() #dispose or it'll lock the file
	
}

Function Send_PwdChng_Email { 
	param (
		[Parameter(Mandatory=$True)][String]$Mode
	)
		
	$ScriptPath = Split-Path -Path $myInvocation.PSCommandPath	
	$XSLPath = $ScriptPath + '\message-complexpwd.xsl'
	if((Test-Path -Path $XSLPath) -eq $false) { 
		Echo-Log "Error: cannot find $XSLPath"
		Echo-Log "Error: Email formatting is not possible. Aborting function."
		return 0 
	} 
	
	$XSLPath = $ScriptPath + '\message.xsl'
	if((Test-Path -Path $XSLPath) -eq $false) { 
		Echo-Log "Error: cannot find $XSLPath"
		Echo-Log "Error: Email formatting is not possible. Aborting function."
		return 0 
	} 
	
	$UDLFile = $glb_UDL
	$connection = $Null
	if((Test-Path $UDLFile)) {
		$UDLConnection = Read-UDLConnectionString $UDLFile
		$connection = New-UDLSQLconnection $UDLConnection
	}
		
	# The mode parameter is added to the name of the T-SQL procedure to aquire to correct results
	Echo-Log "Querying database for mode: [$Mode]"	
	$query = "exec dbo.prc_VNB_PWDCHANGE_EMAIL_$mode"
	Echo-Log $query
		
	$data = Invoke-SQLQuery -query $query -conn $connection	
	if($data) { 
		$reccount = $data.Count	
		ForEach($rec in $data) {		
			$SAMAccountname = Reval_Parm $rec.SAMAccountname
			$PasswordComplexity = Reval_Parm $rec.PasswordComplexity
			$FirstName = Reval_Parm $rec.FirstName
			$LastName = Reval_Parm $rec.LastName
			$DisplayName = Reval_Parm $rec.Displayname
			$EmailAddress = Reval_Parm $rec.Email
			$PasswordExpires = Reval_Parm $rec.PasswordExpires
			$LastLogonTimeStamp = Reval_Parm $rec.LastLogonTimeStamp
			$PwdChgDays = Reval_Parm $rec.PwdChgDays
			$PDF = 'C:\Scripts\Secdump\PswdChangeEmail\Change Windows password in Citrix.pdf'
			
			$WarningSent = Reval_Parm $rec.WarningSent
			$CriticalSent = Reval_Parm $rec.CriticalSent
			
			if($PasswordComplexity -eq 'COMPLEXPWD') { 
				$XSLPath = $ScriptPath + '\message-complexpwd.xsl'
			} else {
				$XSLPath = $ScriptPath + '\message.xsl'
			}
			if($Global:DEBUG) {
				Echo-Log "Using XLS: $XSLPath"
			}
			
			# The subject of the email
			$Subject = "Your Windows password is due to expire in $PwdChgDays days"
			# Add text to the subject if this is the 7 reminder.
			if(($Mode -eq 'REMINDER') -and ($WarningSent.Length -gt 0)) { 
				$Subject = "REMINDER: " + $subject
			}				
			
#####################			
			if($Global:DEBUG) {
				# Override sent to email adres in debug mode
				$EmailAddress = 'm.jussen@vdlnedcar.nl'
			}
#####################
							
			Echo-Log "Sending email to [$DisplayName] [Last logon: $LastLogonTimeStamp]"
			
			try {
				$Global:Chg_Email_Proposed++				
				$result = Send-HTMLFormattedEmail -To $EmailAddress -ToDisname $DisplayName `
				-From $Global:SendFromAddress `
				-FromDisName $Global:SendFromAdressName `
				-Subject $Subject `
				-Content "$PwdChgDays" `
				-UID "$SAMAccountname" `
				-Relay $Global:SMTPRelayAddress `
				-XSLPath $XSLPath `
				-FilePath $PDF
				
				# Signal transmission was succesfull

				Echo-Log "The email was sent successfully to [$EmailAddress]."
				$Global:Chg_Email_Comitted++
			
				if(!$Global:DEBUG) {
					# Update email transmitted table with user and send date information
					Echo-Log "Updating transmission log table [$Mode] for [$SAMAccountname]"
					$query = "exec dbo.prc_VNB_PWDCHANGE_UPDATE_$Mode @SamAccountName=$SAMAccountname"
					$data = Invoke-SQLQuery -query $query -conn $connection
				}
			}
			catch {
				# Signal transmission was a failure
				Echo-Log "ERROR: The email was not sent successfully [$EmailAddress]."
				Echo-Log "The transmission log was not updated because no email was sent."				
			}			
		}
	} 	
	
	Echo-Log "Closing SQL connection."
	Remove-SQLconnection $connection
}

Function Cleanup_EmailRecords { 	
	$UDLFile = $glb_UDL
	$connection = $Null
	if((Test-Path $UDLFile)) {
		$UDLConnection = Read-UDLConnectionString $UDLFile
		$connection = New-UDLSQLconnection $UDLConnection
	}
	
	Echo-Log "Cleanup email records."
	$query = "exec dbo.prc_VNB_PWDCHANGE_CLEANUP"
	Echo-Log $query
	$data = Invoke-SQLQuery -query $query -conn $connection	
	
	Echo-Log "Closing SQL connection."
	Remove-SQLconnection $connection
}

# ------------------------------------------------------------------------------
# Start script
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-ERS-SendPwdChange_Email-$cdtime"
$GlobLog = New-LogFile -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

# ------------------------------------------------------------------------------
# Cleanup old email records
Cleanup_EmailRecords 

# ------------------------------------------------------------------------------
# Send warning mails 14 days ahead of the password expiration
Send_PwdChng_Email -mode 'WARNING'

# Send reminder mails 7 days ahead of the password expiration
Send_PwdChng_Email -mode 'REMINDER'
# ------------------------------------------------------------------------------

Echo-Log ("-"*60)	
Echo-Log "Proposed password expiration emails       : $Global:Chg_Email_Proposed"
Echo-Log "Committed password expiration emails sent : $Global:Chg_Email_Comitted"
Echo-Log ("-"*60)	
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)
Close-LogSystem

$Title = "ERS: $Chg_Email_Comitted password expiration reminder emails have been sent." 	
if ($Chg_Email_Comitted -gt 0) {		
	Send-HTMLEmailLogFile -FromAddress $Global:SendFromAddress -SMTPServer $Global:SMTPRelayAddress -ToAddress $Global:SendFromAddress -Subject $title -LogFile $GlobLog -Headline $Title
	Send-HTMLEmailLogFile -FromAddress $Global:SendFromAddress -SMTPServer $Global:SMTPRelayAddress -ToAddress $Global:SentToAddress -Subject $title -LogFile $GlobLog -Headline $Title	
}