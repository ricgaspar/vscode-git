
# ---------------------------------------------------------
# Chart_Exchange_Mailbox_Distribution
#
# Marcel Jussen
# 6-5-2014
# ---------------------------------------------------------
#requires -Version 2
cls
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $true

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
		[Parameter(Mandatory=$True)][String]$ImagePath,
		[Parameter(Mandatory=$True)][String]$Relay,
		[Parameter(Mandatory=$True)][String]$XSLPath
    )
    
    try {
		#Picture used 
		$Logopic = $ImagePath
		
        $Message = New-Object System.Net.Mail.MailMessage
		
		# add the attachment, and set it to inline.
		$Attachment = New-Object Net.Mail.Attachment($Logopic)
		$Attachment.ContentDisposition.Inline = $True
		$Attachment.ContentDisposition.DispositionType = "Inline"
		$Attachment.ContentType.MediaType = "image/png"
		$Logo = "cid:logo" 
				
        # Load XSL Argument List
        $XSLArg = New-Object System.Xml.Xsl.XsltArgumentList
        $XSLArg.Clear() 
        $XSLArg.AddParam("To", $Null, $ToDisName)
        $XSLArg.AddParam("Content", $Null, $Content)
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
		$imageToSend = new-object system.net.mail.linkedresource($Logopic,"image/png")
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

Function Reval_Parm { 
	Param (
		$Parm
	)
	if(($Parm -eq $null) -or ($Parm.Length -eq 0)) { $Parm = "" }
	$VarType = $Parm.GetType()	
	if($VarType.Fullname -eq "System.DBNull") { $Parm = 0 }	
	Return $Parm
} 

Function Query_ExchangeDB_Distrib {
	param (
		$query
	)
	$udl = Read-UDL-ConnectionString -UDLFile C:\Scripts\Utils\secdump.udl
	$hash = Invoke-UDL-SQL -connectionstring $udl -query $query
	return $hash
} 

Function Create_DB_Chart {
	param (		
		$ImagePath,
		$ImageType
	)
	
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")	

	# chart object
	$chart1 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
	$chart1.Width = 800
	$chart1.Height = 600
	$chart1.BackColor = [System.Drawing.Color]::White

	# title 
	[void]$chart1.Titles.Add("Exchange mailbox database distribution.")
	$chart1.Titles[0].Font = "Arial,13pt"
	$chart1.Titles[0].Alignment = "topCenter"

	# chart area 
	$chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
	$chartarea.Name = "ChartArea1"
	$chartarea.Area3DStyle.Enable3d = $true
   	$chartarea.AxisY.Title = "Mailbox count"
   	$chartarea.AxisX.Title = "Database name"
   	$chartarea.AxisY.Interval = 25
   	$chartarea.AxisX.Interval = 1
   	$chart1.ChartAreas.Add($chartarea)
   
	# legend 
	$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
	$legend.name = "Legend1"
	$chart1.Legends.Add($legend)
	
	# data source
	$query = 'select * from [dbo].[vw_Exchange_Mailbox_Distribution]'
	$datasource = Query_ExchangeDB_Distrib $query
   
	# data series
	[void]$chart1.Series.Add("Max Mailbox")
	$chart1.Series["Max Mailbox"].ChartType = "Bar"
	$chart1.Series["Max Mailbox"].BorderWidth = 3
	$chart1.Series["Max Mailbox"].IsVisibleInLegend = $true
	$chart1.Series["Max Mailbox"].chartarea = "ChartArea1"
	$chart1.Series["Max Mailbox"].Legend = "Legend1"
	$chart1.Series["Max Mailbox"].color = "#62B5CC"
	$datasource | ForEach-Object {
		$count = Reval_Parm($_.max_mb_count)
		[Void]$chart1.Series["Max Mailbox"].Points.addxy( $_.Database , $count) 
	}
   
	# data series
	[void]$chart1.Series.Add("Mailbox Count")
	$chart1.Series["Mailbox Count"].ChartType = "Bar"
	$chart1.Series["Mailbox Count"].IsVisibleInLegend = $true
	$chart1.Series["Mailbox Count"].BorderWidth = 3
	$chart1.Series["Mailbox Count"].chartarea = "ChartArea1"
	$chart1.Series["Mailbox Count"].Legend = "Legend1"
	$chart1.Series["Mailbox Count"].color = "#E3B64C"
	$datasource | ForEach-Object {[Void]$chart1.Series["Mailbox Count"].Points.addxy( $_.Database , $_.Mailbox_count) }
   
	# save chart	
	$chart1.SaveImage($ImagePath,$ImageType)   
}   

Function Create_ARCH_Chart {
	param (		
		$ImagePath,
		$ImageType
	)
	
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")	

	# chart object
	$chart1 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
	$chart1.Width = 800
	$chart1.Height = 600
	$chart1.BackColor = [System.Drawing.Color]::White

	# title 
	[void]$chart1.Titles.Add("Exchange archive database distribution.")
	$chart1.Titles[0].Font = "Arial,13pt"
	$chart1.Titles[0].Alignment = "topCenter"

	# chart area 
	$chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
	$chartarea.Name = "ChartArea1"
	$chartarea.Area3DStyle.Enable3d = $true
   	$chartarea.AxisY.Title = "Mailbox count"
   	$chartarea.AxisX.Title = "Database name"
   	$chartarea.AxisY.Interval = 25
   	$chartarea.AxisX.Interval = 1
   	$chart1.ChartAreas.Add($chartarea)
   
	# legend 
	$legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
	$legend.name = "Legend1"
	$chart1.Legends.Add($legend)
	
	# data source
	$query = 'select * from [dbo].[vw_Exchange_Archive_Distribution]'
	$datasource = Query_ExchangeDB_Distrib $query
   
	# data series
	[void]$chart1.Series.Add("Max Mailbox")
	$chart1.Series["Max Mailbox"].ChartType = "Bar"
	$chart1.Series["Max Mailbox"].BorderWidth = 3
	$chart1.Series["Max Mailbox"].IsVisibleInLegend = $true
	$chart1.Series["Max Mailbox"].chartarea = "ChartArea1"
	$chart1.Series["Max Mailbox"].Legend = "Legend1"
	$chart1.Series["Max Mailbox"].color = "#62B5CC"
	$datasource | ForEach-Object {
		$count = Reval_Parm($_.max_mb_count)	
		[Void]$chart1.Series["Max Mailbox"].Points.addxy( $_.Database , $count) 
	}
   
	# data series
	[void]$chart1.Series.Add("Mailbox Count")
	$chart1.Series["Mailbox Count"].ChartType = "Bar"
	$chart1.Series["Mailbox Count"].IsVisibleInLegend = $true
	$chart1.Series["Mailbox Count"].BorderWidth = 3
	$chart1.Series["Mailbox Count"].chartarea = "ChartArea1"
	$chart1.Series["Mailbox Count"].Legend = "Legend1"
	$chart1.Series["Mailbox Count"].color = "#E3B64C"
	$datasource | ForEach-Object {[Void]$chart1.Series["Mailbox Count"].Points.addxy( $_.Database , $_.Mailbox_count) }
   
	# save chart	
	$chart1.SaveImage($ImagePath,$ImageType)   
}

# ------------------------------------------------------------------------------
# Start script
cls
$ScriptName = $myInvocation.MyCommand.Name

$SendTo = "events@vdlnedcar.nl"
$dnsdomain = 'vdlnedcar.nl'
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-$ScriptName-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

# Here we go
$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition
$ImageType = 'png'

# Check how much space is left in the databases. If it reaches 75% or more we want to be alerted.
# Include only those databases that have a max_mb_count value present
$query = 'select * from [dbo].[vw_Exchange_Mailbox_Distribution] where not(max_mb_count is NULL)'
$hash = Query_ExchangeDB_Distrib $query
$totalsize = 0
$totalmaxsize = 0
foreach($row in $hash) {
	$dbname = $row.database
	$dbcount = $row.Mailbox_count
	$dbmax = $row.max_mb_count
	Echo-Log "$dbname $dbcount $dbmax"
	$totalsize += $row.Mailbox_count
	$totalmaxsize += $row.max_mb_count
}
$fillpercentage = [decimal]::round(($totalsize / $totalmaxsize)*100)
Echo-Log "Fill percentage: $fillpercentage%"

# Our threshold value
$MaxFillPercentage = 75
Echo-Log "Threshold: $MaxFillPercentage%"

if($fillpercentage -ge $MaxFillPercentage) {
	# We have reached critical levels
	# Create the chart
	$ImagePath = "$scriptpath\dbchart.png"
	Echo-Log "Creating chart image $ImagePath ($ImageType)"
	Create_DB_Chart $ImagePath $ImageType
   
	# Send the chart.
	$Title = "Exchange mailbox database distribution threshold has been reached. Value=$fillpercentage% Threshold=$MaxFillPercentage%" 
	Echo-Log "Sending mail to $SendTo from $SendFrom"
	Send-HTMLFormattedEmail -To $SendTo -ToDisName 'Administrator' -From $SendFrom -FromDisName $computername -Subject $Title -Content $Title -ImagePath $ImagePath -Relay 'smtp.nedcar.nl' -XSLPath "$scriptpath\dbformat.xsl"
} else {
	Echo-Log "No need to send email warning for Exchange mailboxes."
}

Echo-Log ""
Echo-Log "Checking Archive databases."
# Check how much space is left in the archives. 
$query = 'select * from [dbo].[vw_Exchange_Archive_Distribution] where not(max_mb_count is NULL)'
$hash = Query_ExchangeDB_Distrib $query
$totalsize = 0
$totalmaxsize = 0
foreach($row in $hash) {
	$dbname = $row.database
	$dbcount = $row.Mailbox_count
	$dbmax = $row.max_mb_count
	Echo-Log "$dbname $dbcount $dbmax"
	$totalsize += $row.Mailbox_count
	$totalmaxsize += $row.max_mb_count
}
$fillpercentage = [decimal]::round(($totalsize / $totalmaxsize)*100)
Echo-Log "Fill percentage: $fillpercentage%"

# Our threshold value
$MaxFillPercentage = 75
Echo-Log "Threshold: $MaxFillPercentage%"

if($fillpercentage -ge $MaxFillPercentage) {
	# We have reached critical levels
	# Create the chart
	$ImagePath = "$scriptpath\archchart.png"
	Echo-Log "Creating chart image $ImagePath ($ImageType)"
	Create_ARCH_Chart $ImagePath $ImageType
   
	# Send the chart.
	$Title = "Exchange archives distribution threshold has been reached. Value=$fillpercentage% Threshold=$MaxFillPercentage%" 
	Echo-Log "Sending mail to $SendTo from $SendFrom"
	Send-HTMLFormattedEmail -To $SendTo -ToDisName 'Administrator' -From $SendFrom -FromDisName $computername -Subject $Title -Content $Title -ImagePath $ImagePath -Relay 'smtp.nedcar.nl' -XSLPath "$scriptpath\archformat.xsl"
} else {
	Echo-Log "No need to send email warning for Exchange archives."
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)