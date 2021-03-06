<#
#=======================================================================================
# Name: ExportData.ps1
# Version: 0.1
# Author: Raphael Perez - raphael@rflsystems.co.uk
# Date: 05/11/2013
# Comment: This script will export the collected information from a CM12R2 Infrastructure to Word format
#
# Test: This script was tested on a Windows 8.1 OS running against a CM12R2 Primary site
#       installed on a Windows Server 2012 R2 OS
#
# Thanks to: 
#		 Word functions copied from Carl Webster (www.carlwebster.com)
#		 Word functions copied from David O'Brien (www.david-obrien.net/2013/06/20/huge-powershell-inventory-script-for-configmgr-2012/)
#
# Updates:
#        0.1 - Raphael Perez - 24/10/2013 - Initial Script
#        0.2 - Raphael Perez - 05/11/2014
#                              Added Get-MessageInformation and Get-MessageSolution
#
# Usage:
#		 Option 1: powershell.exe -ExecutionPolicy Bypass .\ExportData.ps1 [Parameters]
#        Option 2: Open Powershell and execute .\ExportData.ps1 [Parameters]
#
# Parameters:
#
# Examples:
#        .\ExportData.ps1 
#=======================================================================================
#>
PARAM(
    [Parameter(Mandatory = $True, HelpMessage = "Collected data folder")] $reportfolder,
	[Parameter(Mandatory = $false, HelpMessage = "Export full data, not only summary")] $detailed = $true,
	[Parameter(Mandatory = $false, HelpMessage = "HealthCheck query file name")] $healthcheckfilename = "cm12R2healthcheck.xml",
	[Parameter(Mandatory = $false, HelpMessage = "Debug more?")] $healthcheckdebug = $false
)
$FormatEnumerationLimit = -1
$currentFolder = $PWD.Path
if ($currentFolder.substring($currentFolder.length-1) -ne '\') { $currentFolder+= '\' }

if ($healthcheckdebug -eq $true) { $PSDefaultParameterValues = @{"*:Verbose"=$True}; $currentFolder = "C:\Temp\CM12R2HealthCheck\" }

$logFolder = $currentFolder + "_Logs\"

if ($reportFolder.substring($reportFolder.length-1) -ne '\') { $reportFolder+= '\' }
$component = ($MyInvocation.MyCommand.Name -replace '.ps1', '')
$logfile = $logFolder + $component + ".log"
$Error.Clear()
$bLogValidation = $false

#####START FUNCTIONS#####
function Test-Powershell
{
    PARAM(
        [int]$version = 4
    )
    return ($PSVersionTable.psversion.Major -ge $version)
}

function Test-Powershell64bit
{
    return ([IntPtr]::size -eq 8)
}

Function Write-Log
{
    PARAM(
        [String]$Message,
        [int]$severity = 1,
        [string]$logfile = '',
        [bool]$showmsg = $true
        
    )
    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"
    $Date= Get-Date -Format "HH:mm:ss.fff"
    $Date2= Get-Date -Format "MM-dd-yyyy"
    $type=1
    
    if (($logfile -ne $null) -and ($logfile -ne ''))
    {    
        "<![LOG[$Message]LOG]!><time=`"$date+$($TimeZoneBias.bias)`" date=`"$date2`" component=`"$component`" context=`"`" type=`"$severity`" thread=`"`" file=`"`">" | Out-File -FilePath $logfile -Append -NoClobber -Encoding default
    }
    
    if ($showmsg -eq $true)
    {
        switch ($severity)
        {
            3 { Write-Host $Message -ForegroundColor Red }
            2 { Write-Host $Message -ForegroundColor Yellow }
            1 { Write-Host $Message }
        }
    }
}

Function Test-Folder
{
    PARAM(
        [String]$Path,
        [bool]$Create = $true
    )
    if (Test-Path -Path $Path) { return $true }
    elseif ($Create -eq $true)
    {
        try
        {
            New-Item ($Path) -type directory -force | out-null
            return $true        	
        }
        catch 
        {
            return $false
        }        
    }
    else { return $false }
}

function Get-MessageInformation
{
    PARAM(
		$MessageID
	)
	$msg = $MessagesXML.dtsHealthCheck.Message | Where-Object {$_.MessageId -eq $MessageID}
	if ($msg -eq $null)
	{ return "Unknown Message ID $MessageID" }
	else { return $msg.Description }
}

function Get-MessageSolution
{
    PARAM(
		$MessageID
	)
	$msg = $MessagesXML.dtsHealthCheck.MessageSolution | Where-Object {$_.MessageId -eq $MessageID}
	if ($msg -eq $null)
	{ return "There is no known possible solution for Message ID $MessageID" }
	else { return $msg.Description }
}
function Write-WordText
{
    PARAM(
		$wordselection,
		$text = "",
		$Style = "No Spacing",
		$bold = $false,
		$newline = $fals,
		$newpage = $false
	)
	#Write-Log -message ("Writting: $Style, $text") -logfile $logfile
	$texttowrite = ""
	$wordselection.Style = $Style

    if ($bold) { $wordselection.Font.Bold = 1 } else { $wordselection.Font.Bold = 0 }
	$texttowrite += $text 
	$wordselection.TypeText($text)
	If ($newline) { $wordselection.TypeParagraph() }	
	If ($newpage) { $wordselection.InsertNewPage() }	
}

Function Set-WordDocumentProperty 
{
    PARAM(
		$document,
		$name,
		$value
	)
	$prop = $document.BuiltInDocumentProperties | foreach { 
		$propname=$_.GetType().InvokeMember("Name","GetProperty",$null,$_,$null)
		if ($propname -eq $Name) { Return $_ }
	}

	$Prop.GetType().InvokeMember("Value","SetProperty",$null,$prop,$Value)
}
#####END FUNCTION#####
try
{
	$poshversion = $PSVersionTable.psversion.Major
	if (!(Test-Path -Path ($currentFolder + $healthcheckfilename)))
    {
        Write-Host "File $($currentFolder)$($healthcheckfilename) does not exist, no futher action taken" -ForegroundColor Red
		Exit
    }
    else { [xml]$HealthCheckXML = Get-Content ($currentFolder + $healthcheckfilename) }

	if (!(Test-Path -Path ($currentFolder + "Messages.xml")))
    {
        Write-Host "File $($currentFolder)Messages.xml does not exist, no futher action taken" -ForegroundColor Red
		Exit
    }
    else { [xml]$MessagesXML = Get-Content ($currentFolder + 'Messages.xml') }	

    if (Test-Folder -Path $logFolder)
    {
    	try
    	{
        	New-Item ($logFolder + 'Test.log') -type file -force | out-null 
        	Remove-Item ($logFolder + 'Test.log') -force | out-null 
    	}
    	catch
    	{
        	Write-Host "Unable to read/write file on $logFolder folder, no futher action taken" -ForegroundColor Red
        	Exit    
    	}
	}
	else
	{
        Write-Host "Unable to create Log Folder, no futher action taken" -ForegroundColor Red
        Exit
	}
	$bLogValidation = $true

	if (Test-Folder -Path $reportFolder -Create $false)
    {
		if (!(Test-Path -Path ($reportFolder + "config.xml")))
		{
        	Write-Log -message "File $($reportFolder)config.xml does not exist, no futher action taken" -severity 3 -logfile $logfile
        	Exit
		}
		else { $ConfigTable = Import-Clixml -Path ($reportFolder + "config.xml") }
		
		if ($poshversion -ne 3) { $NumberOfDays = $ConfigTable.Rows[0].NumberOfDays }
		else { $NumberOfDays = $ConfigTable.NumberOfDays }
		
		
		if (!(Test-Path -Path ($reportFolder + "report.xml")))
		{
        	Write-Log -message "File $($reportFolder)report.xml does not exist, no futher action taken" -severity 3 -logfile $logfile
        	Exit
		}
		else 
		{
	 		$ReportTable = New-Object system.Data.DataTable 'ReportTable'
	        $ReportTable = Import-Clixml -Path ($reportFolder + "report.xml")
		}
	}
	else
	{
        Write-Host "$reportFolder does not exist, no futher action taken" -ForegroundColor Red
        Exit
	}
	
    if (!(Test-Powershell -version 3))
    {
        Write-Log -message "Powershell version ($poshversion) not supported. Minimum version should be 3, no futher action taken" -severity 3 -logfile $logfile
        Exit
    }
    
    if (!(Test-Powershell64bit))
    {
        Write-Log -message "Powershell is not 64bit, no futher action taken" -severity 3 -logfile $logfile
        Exit
    }

	Write-Log -message "==========" -logfile $logfile -showmsg $false
    Write-Log -message "Starting HealthCheck" -logfile $logfile
    
    Write-Log -message "Running Powershell version $poshversion" -logfile $logfile
    Write-Log -message "Running Powershell 64 bits" -logfile $logfile
    Write-Log -message "Report Folder: $reportFolder" -logfile $logfile
    Write-Log -message "Detailed Report: $detailed" -logfile $logfile
	Write-Log -message "Number Of days: $NumberOfDays" -logfile $logfile

	$Word = New-Object -comobject "Word.Application"
	Write-Log -message "Word Version: $($Word.Version)" -logfile $logfile	
	
	if ($Word.Version -eq "15.0") 
	{
		$TableStyle = "Grid Table 4 - Accent 1"
		$TableSimpleStyle = "List Table 1 Light - Accent 1"
		$CoverPage = "Banded"
	}
	elseif ($Word.Version -eq "14.0") 
	{
		$TableStyle = "Medium Shading 1 - Accent 1"
		$TableSimpleStyle = "Light Grid - Accent 1"
		$CoverPage = "Conservative"
	}
	else 
	{ 
		Write-Log -message "This script requires Word 2010/2013 version, no further action taken" -severity 3 -logfile $logfile 
		Exit
	}
	
	$Word.Visible = $true
	$Doc = $Word.Documents.Add()
	$Selection = $Word.Selection
	
	$Word.Options.CheckGrammarAsYouType = $false
	$Word.Options.CheckSpellingAsYouType = $false
	
	$word.Templates.LoadBuildingBlocks() | Out-Null	
	$BuildingBlocks = $word.Templates | Where {$_.name -eq "Built-In Building Blocks.dotx"}
	$part = $BuildingBlocks.BuildingBlockEntries.Item($CoverPage)
	
	Set-WordDocumentProperty -document $doc -name "Title" -value "System Center 2012 R2 Configuration Manager HealthCheck"
	Set-WordDocumentProperty -document $doc -name "Subject" -value "www.rflsystems.co.uk"
	Set-WordDocumentProperty -document $doc -name "Author" -value "Author"
	Set-WordDocumentProperty -document $doc -name "Company" -value "Company"
	
	$part.Insert($selection.Range,$True) | out-null
	$selection.InsertNewPage()
	
	$toc=$BuildingBlocks.BuildingBlockEntries.Item("Automatic Table 2")
	$toc.insert($selection.Range,$True) | out-null
	$selection.InsertNewPage()
	
	$currentview = $doc.ActiveWindow.ActivePane.view.SeekView
	$doc.ActiveWindow.ActivePane.view.SeekView = 4
	$selection.HeaderFooter.Range.Text= "Copyright (c) 2014 - www.rflsystems.co.uk"
	$selection.HeaderFooter.PageNumbers.Add(2) | Out-Null
	$doc.ActiveWindow.ActivePane.view.SeekView = $currentview
	$selection.EndKey(6,0) | Out-Null
	
	Write-WordText -wordselection $selection -text "Abstract" -style "Heading 1" -newline $true
	Write-WordText -wordselection $selection -text "Write something here" -newline $true
	$selection.InsertNewPage()
	
	foreach ($healthCheck in $HealthCheckXML.dtsHealthCheck.HealthCheck)
    {
		if (($detailed -eq $false) -and ($healthCheck.section -eq '5')) { continue }
		
		$Description = $healthCheck.Description -replace("@@NumberOfDays@@", $NumberOfDays)
		if ($healthCheck.IsActive.tolower() -ne 'true') { continue }
        if ($healthCheck.IsTextOnly.tolower() -eq 'true') 
		{
			Write-WordText -wordselection $selection -text $Description -style $healthCheck.WordStyle -newline $true
			Continue;
		}
		
		Write-WordText -wordselection $selection -text $Description -style $healthCheck.WordStyle -newline $true
        $bFound = $false
		foreach ($rp in $ReportTable)
		{
			if ($rp.TableName -eq $healthCheck.XMLFile)
			{
                $bFound = $true
				Write-Log -message (" - Exporting $($rp.XMLFile) ...") -logfile $logfile
				$filename = $rp.XMLFile				
				if ($filename.IndexOf("_") -gt 0)
				{
					$xmltitle = $filename.Substring(0,$filename.IndexOf("_"))
					$xmltile = ($rp.TableName.Substring(0,$rp.TableName.IndexOf("_")).Replace("@","")).Tolower()
					switch ($xmltile)
					{
						"sitecode" { $xmltile = "Site Code: "; break; }
						"servername" { $xmltile = "Server Name: "; break; }
					}
					switch ($healthCheck.WordStyle)
					{
						"Heading 1" { $newstyle = "Heading 2"; break; }
						"Heading 2" { $newstyle = "Heading 3"; break; }
						"Heading 3" { $newstyle = "Heading 4"; break; }
						default { $newstyle = $healthCheck.WordStyle; break }
					}
					
					$xmltile += $filename.Substring(0,$filename.IndexOf("_"))

					Write-WordText -wordselection $selection -text $xmltile -style $newstyle -newline $true
				}				
				
	            if (!(Test-Path ($reportFolder + $rp.XMLFile)))
    	        {
					Write-WordText -wordselection $selection -text $healthCheck.EmptyText -newline $true
					Write-Log -message ("Table does not exist") -logfile $logfile -severity 2
					$selection.TypeParagraph()
				}
				else
				{
	        		$datatable = Import-Clixml -Path ($reportFolder + $filename)
		            $count = 0
		            $datatable | ? {$count++}
					
		            if ($count -eq 0)
		            {
						Write-WordText -wordselection $selection -text $healthCheck.EmptyText -newline $true
						Write-Log -message ("Table: 0 rows") -logfile $logfile -severity 2
						$selection.TypeParagraph()
		                continue
		            }

					switch ($healthCheck.PrintType.ToLower())
                	{
						"table"
						{
							$Table = $Null
					        $TableRange = $Null
					        $TableRange = $doc.Application.Selection.Range
							$Columns = $HealthCheck.Fields.Field.Count
					        
							$Table = $doc.Tables.Add($TableRange, $count+1, $Columns)
							$table.Style = $TableStyle

							$i = 1;
							Write-Log -message ("Table: $count rows and $Columns columns") -logfile $logfile

							foreach ($field in $HealthCheck.Fields.Field)
	                        {
								$Table.Cell(1, $i).Range.Font.Bold = $True
								$Table.Cell(1, $i).Range.Text = $field.Description
								$i++
	                        }
							$xRow = 2
							$records = 1
							$y=0
							foreach ($row in $datatable)
		                    {
								if ($records -ge 500)
								{
									Write-Log -message ("Exported $(500*($y+1)) records") -logfile $logfile
									$records = 1
									$y++
								}
								$i = 1;
								foreach ($field in $HealthCheck.Fields.Field)
		                        {
									$Table.Cell($xRow, $i).Range.Font.Bold = $false
									$TextToWord = "";
									switch ($field.Format.ToLower())
									{
										"message" 
										{
											$TextToWord = Get-MessageInformation -MessageID ($row.$($field.FieldName))
											break ;
										}
										"messagesolution" 
										{
											$TextToWord = Get-MessageSolution -MessageID ($row.$($field.FieldName))
											break ;
										}										
										default
										{
											$TextToWord = $row.$($field.FieldName);
											break;
										}
									}
                                    if ([string]::IsNullOrEmpty($TextToWord)) { $TextToWord = " " }
									$Table.Cell($xRow, $i).Range.Text = $TextToWord
									$i++
		                        }
								$xRow++
								$records++
							}

					        $selection.EndOf(15) | Out-Null
					        $selection.MoveDown() | Out-Null
							$doc.ActiveWindow.ActivePane.view.SeekView = 0
							$selection.EndKey(6, 0) | Out-Null
							$selection.TypeParagraph()
							break
						}
						"simpletable"
						{
							$Table = $Null
					        $TableRange = $Null
					        $TableRange = $doc.Application.Selection.Range
							$Columns = $HealthCheck.Fields.Field.Count
					        
							$Table = $doc.Tables.Add($TableRange, $Columns, 2)
							$table.Style = $TableSimpleStyle
							$i = 1;
							Write-Log -message ("Table: $Columns rows and 2 columns") -logfile $logfile
							$records = 1
							$y=0
		                    foreach ($field in $HealthCheck.Fields.Field)
		                    {
								if ($records -ge 500)
								{
									Write-Log -message ("Exported $(500*($y+1)) records") -logfile $logfile
									$records = 1
									$y++
								}
								$Table.Cell($i, 1).Range.Font.Bold = $true
								$Table.Cell($i, 1).Range.Text = $field.Description
							
								$Table.Cell($i, 2).Range.Font.Bold = $false
								if ($poshversion -ne 3)
								{ 
									$TextToWord = "";
									switch ($field.Format.ToLower())
									{
										"message" 
										{
											$TextToWord = Get-MessageInformation -MessageID ($datatable.Rows[0].$($field.FieldName))
											break ;
										}
										"messagesolution" 
										{
											$TextToWord = Get-MessageSolution -MessageID ($datatable.Rows[0].$($field.FieldName))
											break ;
										}											
										default
										{
											$TextToWord = $datatable.Rows[0].$($field.FieldName)
											break;
										}
									}
                                    if ([string]::IsNullOrEmpty($TextToWord)) { $TextToWord = " " }
									$Table.Cell($i, 2).Range.Text = $TextToWord
								}
								else 
								{
									$TextToWord = "";
									switch ($field.Format.ToLower())
									{
										"message" 
										{
											$TextToWord = Get-MessageInformation -MessageID ($datatable.$($field.FieldName))
											break ;
										}
										"messagesolution" 
										{
											$TextToWord = Get-MessageSolution -MessageID ($datatable.$($field.FieldName))
											break ;
										}											
										default
										{
											$TextToWord = $datatable.$($field.FieldName) 
											break;
										}
									}
                                    if ([string]::IsNullOrEmpty($TextToWord)) { $TextToWord = " " }
									$Table.Cell($i, 2).Range.Text = $TextToWord
								}
								$i++
								$records++
							}

					        $selection.EndOf(15) | Out-Null
					        $selection.MoveDown() | Out-Null
							$doc.ActiveWindow.ActivePane.view.SeekView = 0
							$selection.EndKey(6, 0) | Out-Null
							$selection.TypeParagraph()
							break
							break
						}
						default
						{
							$records = 1
							$y=0
		                    foreach ($row in $datatable)
		                    {
								if ($records -ge 500)
								{
									Write-Log -message ("Exported $(500*($y+1)) records") -logfile $logfile
									$records = 1
									$y++
								}
		                        foreach ($field in $HealthCheck.Fields.Field)
		                        {
									$TextToWord = "";
									switch ($field.Format.ToLower())
									{
										"message" 
										{
											$TextToWord = ($field.Description + " : " + (Get-MessageInformation -MessageID ($row.$($field.FieldName))))
											break ;
										}
										"messagesolution" 
										{
											$TextToWord = ($field.Description + " : " + (Get-MessageSolution -MessageID ($row.$($field.FieldName))))
											break ;
										}												
										default
										{
											$TextToWord = ($field.Description + " : " + $row.$($field.FieldName))
											break;
										}
									}
                                    if ([string]::IsNullOrEmpty($TextToWord)) { $TextToWord = " " }
									Write-WordText -wordselection $selection -text $TextToWord -newline $true
		                        }
								$selection.TypeParagraph()
								$records++
		                    }
						}
                	}
				}
			}
		}
        if ($bFound -eq $false) 
		{
		    Write-WordText -wordselection $selection -text $healthCheck.EmptyText -newline $true
		    Write-Log -message ("Table does not exist") -logfile $logfile -severity 2
		    $selection.TypeParagraph()
		}
	}
}
catch
{
	Write-Log -message "Something bad happen that I don't know about" -severity 3 -logfile $logfile
	Write-Log -message "The following error happen, no futher action taken" -severity 3 -logfile $logfile
    $errorMessage = $Error[0].Exception.Message
    $errorCode = "0x{0:X}" -f $Error[0].Exception.ErrorCode
    Write-Log -message "Error $errorCode : $errorMessage" -logfile $logfile -severity 3
    Write-Log -message "Full Error Message Error $($error[0].ToString())" -logfile $logfile -severity 3
	$Error.Clear()
}
finally
{
	#if ($toc -ne $null) { $Doc.Fields | ForEach-Object{ $_.Update() } | Out-Null }
	if ($toc -ne $null) { $doc.TablesOfContents.item(1).Update() }
	if ($bLogValidation -eq $false)
	{
		Write-Host "Ending HealthCheck Export"
        Write-Host "==========" 
	}
	else
	{
        Write-Log -message "Ending HealthCheck Export" -logfile $logfile
        Write-Log -message "==========" -logfile $logfile
	}
}