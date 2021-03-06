<#
.SYNOPSIS
    VNB Library - Logging

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	4-06-2017
 
.DESCRIPTION
    General purpose log functions.
#>
#Requires -version 3.0

# ---------------------------------------------------------
#

# Global Text values
$Global:cSpacer = "  "
$Global:cReq    = "->"
$Global:cWarn   = "@@"
$Global:cErr    = "**"

# Global variables 
#
Remove-Variable glb_* -Force

$Global:glb_EVENTLOG  = $null
$Global:glb_EVENTLOGFile = $null
$Global:glb_EVENTLOGScriptName = $null

$Global:glb_EVENTLOG_Stream = $null
$Global:glb_EVENTLOG_WriteCntr = 0

$Global:glb_EVENTLOG_FolderPath = "$Env:SystemDrive\Logboek"

# Logo to add to emails. Use old location as preset.
$Global:glb_VNBLibDataPath = "$Env:ALLUSERSPROFILE\VDL Nedcar\VNB_PSLib"
$Global:glb_LogoPath = "$Global:glb_VNBLibDataPath\logo-vdl-nedcar-small.jpg"
# LogoAdd will change to true if the logo file is found.
$Global:glb_LogoAdd = $false

# CSS Styles for emails
$Global:glb_CSSPath = "$Global:glb_VNBLibDataPath\css_styles.html"
# ---------------------------------------------------------

function Initialize-LogSystem {
# ---------------------------------------------------------
# Initializes Global variables used for logging system
# ---------------------------------------------------------	
    # Close stream if needed.
    if($Global:glb_EVENTLOG_Stream -ne $null) { Close-LogSystem }
		
	# Wipe value if files could not be found.
	if(!(Test-Path $Global:glb_LogoPath)) { Remove-Variable -Scope Global -Name glb_LogoPath -Force }
	$Global:glb_LogoAdd = (Test-Path $Global:glb_LogoPath)
	
	if(!(Test-Path $Global:glb_CSSPath)) { Remove-Variable -Scope Global -Name glb_CSSPath -Force }
}

function Close-LogSystem {
# ---------------------------------------------------------
# Flushes the current Streamwriter cache and closes the stream.
# ---------------------------------------------------------
    
    # Close stream if needed.
    if($Global:glb_EVENTLOG_Stream -ne $null) {    
		$Global:glb_EVENTLOG_Stream.Flush()
        $Global:glb_EVENTLOG_Stream.Close() 
		$Global:glb_EVENTLOG_WriteCntr = 0
		$Global:glb_EVENTLOG_Stream = $null
    }	
}

function New-Logfile {
# ---------------------------------------------------------
# Initialize the file log.
# ---------------------------------------------------------
	[cmdletbinding()]
	Param ( 
		[parameter(Mandatory=$True)]
		[string]
		$LogFileName,
		
		[parameter(Mandatory=$False)]
		[bool]
		$append = $false,
		
		[parameter(Mandatory=$False)]
		[bool]
		$alternate_location = $false
	)
	
	process {		
		if([string]::IsNullOrEmpty($Global:glb_EVENTLOGFile)) {
			if($alternate_location -eq $false) {
				$Global:glb_EVENTLOGFile = "$Global:glb_EVENTLOG_FolderPath\$LogFileName" + ".log"
			} else {
				$Global:glb_EVENTLOGFile = $LogFileName
			}
		}        

        # close previously opened Stream 
        if($Global:glb_EVENTLOG_Stream) {            
           	Close-LogSystem            
        }        
        
        if(!(test-path($Global:glb_EVENTLOGFile))) {
            # Create folder path to file if it does not exist
		    $Folder = Split-Path $Global:glb_EVENTLOGFile -Parent
		    if(!(Test-Path($Folder))) { New-FolderStructure $Folder }            
        } else {
            # Append or not
		    if($append -eq $false) {                
			    Remove-Item $Global:glb_EVENTLOGFile -Force -ErrorAction SilentlyContinue
            }
        }        
        
        try {
            # open stream to write to with append. If file does not exist it will create a new one.     
            $Global:glb_EVENTLOG_Stream = new-object System.IO.StreamWriter($Global:glb_EVENTLOGFile, 'true')
		    Write-ToLogFile "Initialised logfile $Global:glb_EVENTLOGFile"
        }
        catch {
            Write-Host "ERROR: Could not initialise logfile $Global:glb_EVENTLOGFile"
            $Global:glb_EVENTLOG_Stream = $null
        }
	
        # Why the f*ck do I do this?
		if([string]::IsNullOrEmpty($Global:glb_EVENTLOGScriptName)) {	
			$Global:glb_EVENTLOGScriptName = $LogFileName
		}
	
		return $Global:glb_EVENTLOGFile
	}
}
Set-Alias Init-Log New-LogFile

Function Clear-LogCache {
# ---------------------------------------------------------
# Flush the event log to file and reset counter
# ---------------------------------------------------------
	if($Global:glb_EVENTLOG_Stream -ne $null) {
		# Flush the cache and reset counter
		$Global:glb_EVENTLOG_Stream.Flush()
		$Global:glb_EVENTLOG_WriteCntr = 0
	}
}

function Getglb_EVENTLOG {	
# ---------------------------------------------------------
# Get the event log object used for logging.
# ---------------------------------------------------------
	process {
		if([string]::IsNullOrEmpty($Global:glb_EVENTLOG)) {	
			$Global:glb_EVENTLOG = new-object System.Diagnostics.EventLog("Application")
			$Global:glb_EVENTLOG.Source = $Global:glb_EVENTLOGScriptName
		}
		return $Global:glb_EVENTLOG
	}
}
Set-Alias Get-GlobalEventLog GetGlb_EVENTLOG

function New-LogTime { 
# ---------------------------------------------------------
# Create text with current time and date.
# ---------------------------------------------------------
	process {
		$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
		return $logTime 
	}
}

function Format-Message { 
# ---------------------------------------------------------
# Default format for each line of text in the log
# ---------------------------------------------------------
	[cmdletbinding()]
	param ( 
		[Parameter(Position=0,ValuefromPipeline=$true)]
		[string] 
		$logText = '' 
	)
	begin {
		$logTime = New-LogTime
	}
	process {
		return ( "[" + $logTime + "]: " + $logText )
	}
}

function Out-ToLog {
# ---------------------------------------------------------
# Log text to file with Streamwriter. 
# Flush the cache on regular basis.
# ---------------------------------------------------------
	[cmdletbinding()]
	Param ( 				
		[parameter(Mandatory=$True)]
		[string]
		$logText
	)	
	process {		
		# Define the maximum number of cached writes before the cache is flushed
		$MaxCacheWrites = 1000

        if($Global:glb_EVENTLOG_Stream -ne $null) {				
   		    # Write to current stream 
		    $Global:glb_EVENTLOG_Stream.WriteLine($logText)
		    $Global:glb_EVENTLOG_WriteCntr++

		    # How many writes are stored in the cache?		
		    if($Global:glb_EVENTLOG_WriteCntr -gt $MaxCacheWrites) {
			    # Flush the cache and reset counter
			    Flush-LogCache
		    }		
        }
	}
}

function Write-ToLogFile {
# ---------------------------------------------------------
# Write normal text to console and log file.
# ---------------------------------------------------------
	[cmdletbinding()]
	Param (
		[Parameter(Position=0,ValuefromPipeline=$true)]
        [string]
		$logText = ''
    )	
	
	Process {
		$Message = Format-Message $logText
		Write-Host $Message				
		try { 
            [void](Out-ToLog -logtext $Message)
		}
		catch {
			Write-Host "An error occured while calling Out-ToLog."
		}
	}
}
Set-Alias Echo-Log Write-ToLogFile
Set-Alias Write-Log Write-ToLogFile

function Write-WarningToLogFile {
# ---------------------------------------------------------
# Write warning text to console and log file.
# ---------------------------------------------------------
	[cmdletbinding()]
	Param (
		[parameter(Mandatory=$True)]
        [string]
		$logText
    )
	Begin {
        $Message = "WARNING: $message"
		$Message = Format-Message $logText
    	Write-Warning $Message
	}
	Process {    	        	
		[void](Out-ToLog $Message)
		#$glb_EVENTLOG = Getglb_EVENTLOG
		#$EventType = [System.Diagnostics.EventLogEntryType]::Warning
		#$glb_EVENTLOG.WriteEntry( $logText,$EventType, 1001 )	
	}
}
set-alias Warning-Log Write-WarningToLogFile

function Write-ErrorToLogFile {
# ---------------------------------------------------------
# Write error text to console and log file.
# ---------------------------------------------------------
	[cmdletbinding()]
	Param (    	        
		[parameter(Mandatory=$True)]
        [string]
		$logText
    )
	
	Begin {
        $Message = "ERROR: $message"
    	$Message = Format-Message $logText 
        Write-Host $Message   	
	}
    
	Process {		
		[void](Out-ToLog $Message)		
    	#$glb_EVENTLOG = Getglb_EVENTLOG
		#$EventType = [System.Diagnostics.EventLogEntryType]::Error
		#$glb_EVENTLOG.WriteEntry( $Message,$EventType, 1100 )
	}	
}
set-alias Error-Log Write-ErrorToLogFile

Function New-MailHTMLBody {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	param (
		[parameter(Mandatory=$True)]
		[string]
		$LogFileToSend,
		
		[parameter(Mandatory=$True)]
		[string]
		$HeadlineText
	)
	
	Process {
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
}
Set-Alias Create-MailHTMLBody New-MailHTMLBody

Function Send-HTMLEmailLogFile {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	[cmdletbinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$FromAddress,
		
		[parameter(Mandatory=$True)]
		[string]		
		$ToAddress,
		
		[parameter(Mandatory=$True)]
		[string]
		$SMTPServer,
		
		[parameter(Mandatory=$True)]
		[string]
		$Subject,
		
		[parameter(Mandatory=$True)]
		[string]
		$Headline,
		
		[parameter(Mandatory=$True)]
		[string]
		$Logfile
	)
	
	Begin {
		$mail = new-object System.Net.Mail.MailMessage	
	}
	
	Process {
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

$mailcontent += Create-MailHTMLBody $Logfile $Headline

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
# 		$mail.To.Add( "m.jussen@vdlnedcar.nl" )
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
	}
	
	End {
		$smtpClient = $null
		$attachment = $null
		$mail       = $null
		$log		= $null
	}
}
Set-Alias -Name 'Send-HTMLEmail-LogFile' -Value 'Send-HTMLEmailLogFile'

# --------------------------------------------------------- 
Initialize-LogSystem
# --------------------------------------------------------- 

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *