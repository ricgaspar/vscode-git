#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

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
    param(
		[Parameter(Mandatory=$True)][String]$To,
		[Parameter(Mandatory=$True)][String]$ToDisName,
		[String]$CC,
		[String]$BCC,
		[Parameter(Mandatory=$True)][String]$From,
		[Parameter(Mandatory=$True)][String]$FromDisName,
		[Parameter(Mandatory=$True)][String]$Subject,
		[Parameter(Mandatory=$True)][String]$Content,		
		[Parameter(Mandatory=$True)][String]$Relay,
		[Parameter(Mandatory=$True)][String]$XSLPath
		
        )
    
    try {
		
		#logo used in signature
		$Logopic = $glb_LogoPath
		
        $Message = New-Object System.Net.Mail.MailMessage
		
		# add the attachment, and set it to inline.
		$Attachment = New-Object Net.Mail.Attachment($Logopic)
		$Attachment.ContentDisposition.Inline = $True
		$Attachment.ContentDisposition.DispositionType = "Inline"
		$Attachment.ContentType.MediaType = "image/jpg"
		$Logo = "cid:logo" 
				
        # Load XSL Argument List
        $XSLArg = New-Object System.Xml.Xsl.XsltArgumentList
        $XSLArg.Clear() 
        $XSLArg.AddParam("To", $Null, $ToDisName)        		
		$XSLArg.AddParam("Logo", $Null, $Logo)
        $XSLArg.AddParam("Content", $Null, $Content)
		
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

cls

$ToEmail = 'm.jussen@vdlnedcar.nl'
$ToDisplayname = 'Marcel Jussen'
$FromEmail = 'licensing@vdlnedcar.nl'
$FromDisplayname = 'VDL Nedcar IM-Licensing'
$RelayAddress = 'smtp.nedcar.nl'
$XSLMessage = 'message.xsl'

$Subject = 'Applicaties zonder licentie aangetroffen op uw werkplek.'
$Content = '<table></table>'
Send-HTMLFormattedEmail -To $ToEmail -ToDisname $ToDisplayname -From $FromEmail -FromDisName $FromDisplayname -Subject $Subject -Content $Content -Relay $RelayAddress -XSLPath $XSLMessage
