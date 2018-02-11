# ---------------------------------------------------------
#
# Logging Functions
# Marcel Jussen
# 2-9-2014
#
# ---------------------------------------------------------

$Global:glb_EVENTLOG  = $null
$Global:glb_EVENTLOGFile = $null
$Global:glb_EVENTLOGScriptName = $null

# Logo to add to emails
$Global:glb_LogoPath = "C:\Scripts\Secdump\PS\logo-vdl-nl-small.jpg"
# LogoAdd will change to true if the logo file is found.
$Global:glb_LogoAdd = $false

# CSS Styles for emails
$Global:glb_CSSPath = "C:\Scripts\Secdump\PS\css_styles.html"

function Init-Log {
# ---------------------------------------------------------
# Initialize the file log.
# ---------------------------------------------------------
	Param ( 
		[string] $LogFileName = "$$UNDEFINED_LOG_NAME",
		[bool] $append = $false,
		[bool] $alternate_location = $false
	)	
	if([string]::IsNullOrEmpty($Global:glb_EVENTLOGFile)) {
		if($alternate_location -eq $false) {
			$Global:glb_EVENTLOGFile = "C:\Logboek\" + $LogFileName + ".log"
		} else {
			$Global:glb_EVENTLOGFile = $LogFileName
		}
	}
	if(($append -eq $false) -and (test-path $Global:glb_EVENTLOGFile))
	{
		Remove-Item $Global:glb_EVENTLOGFile -Force -ErrorAction SilentlyContinue
	}
	
	if([string]::IsNullOrEmpty($Global:glb_EVENTLOGScriptName)) {	
		$Global:glb_EVENTLOGScriptName = $LogFileName
	}
	
	return $Global:glb_EVENTLOGFile
}

function Getglb_EVENTLOG {	
# ---------------------------------------------------------
# Get the event log object used for logging.
# ---------------------------------------------------------
	if([string]::IsNullOrEmpty($Global:glb_EVENTLOG)) {	
		$Global:glb_EVENTLOG = new-object System.Diagnostics.EventLog("Application")
		$Global:glb_EVENTLOG.Source = $Global:glb_EVENTLOGScriptName
	}
	return $Global:glb_EVENTLOG
}


function Log-Time { 
# ---------------------------------------------------------
# Create text with current time and date.
# ---------------------------------------------------------
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	return $logTime 
}

function Format-Message { 
# ---------------------------------------------------------
# Default format for each line of text in the log
# ---------------------------------------------------------
	param ( 
		[string] $logText = "no message." 
	)
	$logTime = Log-Time
	return ( "[" + $logTime + "]: " + $logText )
}

function File-Log {
# ---------------------------------------------------------
# log text to file
# ---------------------------------------------------------
	Param ( 
		[string] $LogPath, 
		[string] $logText
	)	
	if([string]::IsNullOrEmpty($LogPath)) { return -1 }
	$logText | Out-File -FilePath $LogPath -Append
}

function Echo-Log {
# ---------------------------------------------------------
# Write normal text to console and log file.
# ---------------------------------------------------------
		Param (    	        				
        [string]$logText
    )		
	$Message = Format-Message $logText
	Write-Host $Message
		
	$glb_EVENTLOG = Getglb_EVENTLOG
	$EventType = [System.Diagnostics.EventLogEntryType]::Information
	# $glb_EVENTLOG.WriteEntry( $logText, $EventType, 1000 )
		
	[void](File-Log $Global:glb_EVENTLOGFile $Message)
}

function Warning-Log {
# ---------------------------------------------------------
# Write warning text to console and log file.
# ---------------------------------------------------------
		Param (    	        
        [string]$logText
    )
    $Message = Format-Message $logText
    Write-Warning $Message
    
    $glb_EVENTLOG = Getglb_EVENTLOG
	$EventType = [System.Diagnostics.EventLogEntryType]::Warning
	# $glb_EVENTLOG.WriteEntry( $logText,$EventType, 1001 )
	
	[void](File-Log $Global:glb_EVENTLOGFile $Message)
}

function Error-Log {
# ---------------------------------------------------------
# Write error text to console and log file.
# ---------------------------------------------------------
		Param (    	        
        [string]$logText
    )
    $Message = Format-Message $logText
    Write-Error $Message
    
    $glb_EVENTLOG = Getglb_EVENTLOG
	$EventType = [System.Diagnostics.EventLogEntryType]::Error
	# $glb_EVENTLOG.WriteEntry( $Message,$EventType, 1100 )
	
	[void](File-Log $Global:glb_EVENTLOGFile $Message)
}

Function Create-Mail-HTMLBody {
	param (
		[string]$LogFileToSend,
		[string]$HeadlineText
	)
	
	if([string]::IsNullOrEmpty($LogFileToSend)) { return $null }
	
$mailcontent = @'
<body>	
	<div id="wrap">		
		<div style="float:left; width: 95%">
'@		
# Insert logo if the logo file was found
if($Global:glb_LogoAdd) { 
$mailcontent += @'						
			<div id="content" width: 95%;">
				<img src="cid:logo" "alt=logo"/>				
			</div>								
'@		
}
$mailcontent += @'						
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
  			<p>VDL Nedcar</p>
		  </div>	  
		</div>
	</div>	
</body>
</html>
'@

	return $mailcontent
}

Function Send-HTMLEmail-LogFile {
	param (
		[string]$FromAddress,
		[string]$ToAddress,
		[string]$SMTPServer,
		[string]$Subject,
		[string]$Headline,
		[string]$Logfile
	)
	
	$mail = new-object System.Net.Mail.MailMessage	
	
	if([IO.File]::Exists($Global:glb_Logopath)) {
		$Global:glb_LogoAdd = $true
		$Attachment = New-Object System.Net.Mail.Attachment($Global:glb_Logopath)
		$Attachment.ContentDisposition.Inline = $true
		$Attachment.ContentDisposition.DispositionType = "Inline"
		$Attachment.ContentType.MediaType = "image/jpg"
		$Attachment.ContentId = "logo"
	}

	$CSS = $Global:glb_CSSPath
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

$mailcontent += Create-Mail-HTMLBody $Logfile $Headline

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
# 	$mail.To.Add( "m.jussen@vdlnedcar.nl" )
	$mail.From       = $messageParameters.From
	$mail.Subject    = $messageParameters.Subject
	$mail.Body       = $messageParameters.Body
	$mail.IsBodyHtml = $true
	$mail.Attachments.Add( $Logfile )
	
	# Add logo file as an attachment if the logo file was found
	if($Global:glb_LogoAdd) { $mail.Attachments.Add( $attachment ) }	

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

