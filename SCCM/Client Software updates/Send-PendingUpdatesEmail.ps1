# ---------------------------------------------------------
# Marcel Jussen
# ---------------------------------------------------------

$Global:SentToAddress 		= 'events@vdlnedcar.nl'
$Global:SendFromAddress		= 'helpdesk@vdlnedcar.nl'
$Global:SendFromAddressName	= 'VDL Nedcar IT Helpdesk'
$Global:SMTPRelayAddress	= 'mail.vdlnedcar.nl'
$Global:SendFrom = $(gc env:computername) + '@vdlnedcar.nl'

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
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
    param (
		[Parameter(Mandatory=$True)][String]$To,
		[Parameter(Mandatory=$True)][String]$ToDisName,
		[String]$CC,
		[String]$BCC,
		[Parameter(Mandatory=$True)][String]$From,
		[Parameter(Mandatory=$True)][String]$FromDisName,
		[Parameter(Mandatory=$True)][String]$Subject,
		[Parameter(Mandatory=$True)][String]$UCount,
		[Parameter(Mandatory=$True)][String]$Computername,
        [Parameter(Mandatory=$True)][String]$Deadline,
        [Parameter(Mandatory=$True)][String]$SCUpdates,
		[Parameter(Mandatory=$True)][String]$Relay,
		[Parameter(Mandatory=$True)][String]$XSLPath,
		[string]$FilePath = $null
	)
    
    try {
		
		# Create a MailMessage object 
        $Message = New-Object System.Net.Mail.MailMessage
		
		# Add file attachment if found
        try {
		    if(Test-Path($FilePath)) {
			    $Message.Attachments.Add($FilePath)
		    }
        }
        catch {
        }

        #
        # Verstuur email ook naar licensing mailbox voor controle
        #
        $BCC = 'licensing@vdlnedcar.nl'

		# add the screenshot attachment, and set it to inline.
        $ScreenPic = $SCUpdates
		$Attachment = New-Object Net.Mail.Attachment($ScreenPic)
		$Attachment.ContentDisposition.Inline = $True
		$Attachment.ContentDisposition.DispositionType = "Inline"
		$Attachment.ContentType.MediaType = "image/jpg"
		$Screenshot = "cid:scupdates" 
		
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
        $XSLArg.AddParam("UCount", $Null, $UCount)
		$XSLArg.AddParam("Computername", $Null, $Computername)
        $XSLArg.AddParam("Deadline", $Null, $Deadline)
        $XSLArg.AddParam("SCUpdates", $Null, $Screenshot)
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

        $imageToSend = new-object system.net.mail.linkedresource($ScreenPic,"image/jpg")
		$imageToSend.ContentID = "SCUpdates"
		$html.LinkedResources.Add($imageToSend)
		$message.AlternateViews.Add($html)

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

Clear-Host

Start-Transcript -Path 'C:\Logboek\SCCM_Send-PendingUpdatesEmail.log' -Force -ErrorAction SilentlyContinue

$ScriptPath = Split-Path -Parent $PSCommandPath
$XSLPath = $ScriptPath + '\message.xsl'
if((Test-Path -Path $XSLPath) -eq $false) { 
	Echo-Log "Error: cannot find $XSLPath"
	Echo-Log "Error: Email formatting is not possible. Aborting function."
	return 0 
}

$SCUpdates = $ScriptPath + '\scupdates.jpg'

# Create MSSQL connection to SECDUMP
$UDL_SECDUMP = Read-UDLConnectionString $glb_UDL
$SECDUMPconn = New-UDLSQLconnection $UDL_SECDUMP

# Create MSSQL connection to SCCM
$UDL_SCCM = '.\cm_vnb.udl'
$UDL_SCCMConnection = Read-UDLConnectionString $UDL_SCCM
$SCCMconn = New-UDLSQLconnection $UDL_SCCMConnection

# Read computers with pending updates
$query = "exec dbo._MJU_Clients_Updates"
$PendingComputerData = Query-SQL $query $SCCMconn

if ($PendingComputerData -ne $null) {
    $cntr = 0
    $ComputerCount = $PendingComputerData.Count
    ForEach ($rec in $PendingComputerData) {
        $cntr++
        [string]$ResourceID = $rec.ResourceID
        [string]$Computername = $rec.Computername
        [string]$Username = $rec.Username
        [string]$OS = $rec.OS
        [string]$DaysSinceLastLogon = $rec.DaysSinceLastLogon
        [string]$DaysSinceLastBoot = $rec.DaysSinceLastBoot
        [string]$Manufacturer = $rec.Manufacturer0
        [string]$Model = $rec.Model0

        $SamAccountName = $Username
        $query = "select Displayname, Email from [dbo].[vw_UsersAD] where SamAccountName = '$SamAccountName'"
        $UserEmailData = Query-SQL $query $SECDUMPconn
        if($UserEmailData -ne $null) {            
            ForEach ($erec in $UserEmailData) {
                [string]$EmailAddress = $erec.Email
                [string]$DisplayName = $erec.DisplayName
            }
            if($EmailAddress.Length -ne 0) {

# ####
# overrule sent to address for testing purposes
#                $EmailAddress = 'licensing@vdlnedcar.nl'
# ####

                write-host "[$cntr of $ComputerCount] $Computername ($ResourceID) : $Username $DisplayName ($EmailAddress)"
                
                $query = "exec [dbo].[_MJU_Updates_Pending] $ResourceID"
                $PendingUpdates = Query-SQL $query $SCCMconn
                if($PendingUpdates -ne $null) {
                    $UCount = $PendingUpdates.Count
                    if($UCount -eq $null) { 
                        $UCount = 1
                        $Subject = "Er moet nog $($UCount) software update voor $($Deadline) op uw computer geïnstalleerd worden."
                    } else {
                        $Subject = "Er moeten nog $($UCount) software updates voor $($Deadline) op uw computer geïnstalleerd worden."
                    }

                    Write-Host "  $($UCount) updates are pending on $($Computername)."
                    ForEach($URec in $PendingUpdates) {                         
                         [string]$Deadline = $URec.Deadline
                    }

                    # The subject of the email
                    if($UCount -eq 1) {                         
                        $Subject = "Er moet nog $($UCount) software update voor $($Deadline) op uw computer geïnstalleerd worden."
                    } else {
                        $Subject = "Er moeten nog $($UCount) software updates voor $($Deadline) op uw computer geïnstalleerd worden."
                    }			        
                    try {
				        $result = Send-HTMLFormattedEmail -To $EmailAddress -ToDisname $DisplayName `
				            -From $Global:SendFromAddress `
				            -FromDisName $Global:SendFromAddressName `
				            -Subject $Subject `
				            -UCount "$UCount" `
				            -Computername "$Computername" `
                            -Deadline "$Deadline" `
				            -Relay $Global:SMTPRelayAddress `
                            -SCUpdates $SCUpdates `
				            -XSLPath $XSLPath				            
                    }
                    catch {
				        # Signal transmission was a failure
				        Write-Host "[$cntr of $ComputerCount] ERROR: The email was not sent successfully to [$EmailAddress]."				        
			        }	
                } else {
                }

            } else {
                write-host "[$cntr of $ComputerCount] $Computername : $Username ERROR:Email address length is 0!"
            }
        } else {
            write-host "[$cntr of $ComputerCount] $Computername : $Username WARNING: No email address record found!"
        }        
    }
}

Stop-Transcript -ErrorAction SilentlyContinue