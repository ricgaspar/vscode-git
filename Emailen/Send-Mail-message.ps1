
Function SendEmail_Log {
	param (
		[string]$FromAddress,
		[string]$ToAddress,
		[string]$SMTPServer,
		[string]$Subject,
		[string]$logfile
	)
	
	$mail = new-object System.Net.Mail.MailMessage
	$Attachment = New-Object System.Net.Mail.Attachment( "C:\Scripts\Powershell\logo-vdl-nl-small.jpg" )
	$Attachment.ContentDisposition.Inline = $true
	$Attachment.ContentDisposition.DispositionType = "Inline"
	$Attachment.ContentType.MediaType = "image/jpg"
	$Attachment.ContentId = "logo"

$body = @'
    <html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:v="urn:schemas-microsoft-com:vml">
    <head>
		<style type="text/css">
			body { font-family: Verdana,Arial,Tahoma,"Trebuchet MS",sans-serif; font-size:12px; line-height:1.0em;	text-align:left; margin-top: 0;	margin-bottom: 0; background-color: #FFFFFF; }
        	BottomRight { position: absolute; bottom: 2px; right: 4px; }			
      	</style>
    </head>
    <body>
        <p>See attached log please.</p>        
        <div id="BottomRight">
             <img src="cid:logo" "alt=logo"/>
        </div>
		<p>
'@

	$log = Get-Content $logfile
	foreach($line in $log) {
		$body = $body + "$line<br>"
	}

$body = $body + @'
		</p>
    </body>
  </html>
'@

	$messageParameters = @{
		From       = "mjussen@gmail.com"
		To         = "marcel.jussen@kpn.com"
		SmtpServer = "smtp.nedcar.nl"
		Subject    = "Yet another test email"
		Body       = $body
	}

	$mail.To.Add( $messageParameters.To )
	$mail.From       = $messageParameters.From
	$mail.Subject    = $messageParameters.Subject
	$mail.Body       = $messageParameters.Body
	$mail.IsBodyHtml = $true
	$mail.Attachments.Add( $attachment )
	$mail.Attachments.Add( $file )

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

$file = "C:\Logboek\Secdump-SAP_2_AD.log"
SendEmail_Log -FromAddress "nedcar-events@kpn.com" -ToAdress "marcel.jussen@kpn.com" -SMPTServer "smpt.nedcar.nl" -Subject "Happy mail!" -LogFile $file




