# =========================================================
# File system cleanup - Convert INI to XML input file.
#
# VDL Nedcar - Information Systems
# Marcel Jussen
# 10-02-2016
#
# =========================================================
#Requires -version 3.0

[CmdletBinding()]
Param(
	[string]$ScriptMode = "PROD"
)

# ---------------------------------------------------------
# Required modules
Import-Module VNB_PSLib -ErrorAction Stop

# ---------------------------------------------------------
# Ensures you only refer to variables that exist (great for typos) and 
# enforces some other “best-practice” coding rules.
Set-StrictMode -Version Latest

# ---------------------------------------------------------
# enforces all errors to become terminating unless you override with 
# per-command -ErrorAction parameters or wrap in a try-catch block
$script:ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# Override DEBUG mode. Go to production when set to $False, DEBUG when set to $True
$Global:DEBUG = $False

# ---------------------------------------------------------
# Check command line parameter -ScriptMode if it is set to DEBUG
#
if([string]::IsNullOrEmpty($ScriptMode) -ne $True) {
	$ScriptMode = $ScriptMode.Trim()
	$ScriptMode = $ScriptMode.ToUpper()
	if($ScriptMode -eq 'DEBUG') { $Global:DEBUG = $true }
}

# ---------------------------------------------------------
# Cleanup configuration attributes
$Global:DESCRIPTION = 'File system cleanup conversion'
$Global:VERSION = '2.0.1'
$Global:Type = 'PROD'

$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn = $null

#
# Translate Mask value to a wildcard value
#
Function Translate-Mask {
	[cmdletbinding()]
    Param(
#        [parameter(ValueFromPipeline)]
#        [ValidateNotNullOrEmpty()]
        [string]$maskvalue
    )
	Process {		
		$result = $null	
		$maskvalue = $maskvalue.Trim()
		if($maskvalue.contains('-')) { $maskvalue = $maskvalue.replace('-','') } 
		if($maskvalue.contains('+')) { $maskvalue = $maskvalue.replace('+','') } 
	
		# Evaluate values
		if($maskvalue -eq '*.*') { return $maskvalue }
		if($maskvalue.substring(0,2) -eq '*.') { return $maskvalue }
	
		# Convert '.xyz' to '*.xyz*'
		if($maskvalue.substring(0,1) -eq '.') { return "*$maskvalue" }
	
		# Convert 'xyz' to '*xyz*'
		if($maskvalue.substring(0,1) -ne '.') { return "*$maskvalue*" }
	
		Return $result
	}
}

#
# Convert contents of a cleanup INI file to a cleanup XML file
#
Function Convert-INIFile {
	[cmdletbinding()]
    Param(
#        [parameter(ValueFromPipeline)]
#        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$Ini_path,
		
#		[parameter(ValueFromPipeline)]
#        [ValidateNotNullOrEmpty()]
        [string]$Xml_path
    )

    Begin {
        $LOGFILE = $(Split-Path $Ini_path) + '\Cleanup.log'
        $LOGFILEAPPEND = 'false'     
    }
	
	Process {		
		
		# DB logging values
		$Systemname = $env:COMPUTERNAME
		$ConvertDate = Get-Date
	
		$conversion_result = $null
		Echo-Log ("=" * 80) 
		Echo-Log "Start XML conversion of $Ini_path"
		$FSO = $null
		$infile = Get-Content $Ini_path
		foreach($line in $infile) {
	
			# Remove any leading or trailing spaces first
			$line = $line.Trim()
			if([string]::IsNullOrEmpty($line) -eq $false) { 
				if($line.Length -gt 0) {
			
					# Search for comment character at start of the line
					$CommentChar = $line.Substring(0,1)
				
					# If this is not a comment line it must be a configuration line
					if($CommentChar -ne ';') {									
						# Remove trailing comment from a configuration line
						$pos = $line.LastIndexOf(';')
						if($pos -gt 0) { 
							$line = $line.substring(0,$pos) 
							$line = $line.Trim()
						}					
					
						Echo-Log $line 
						# Convert the line to an array of values
						$optarr = $line -split ','
	
						# Minimum number of items must be 3 (for three mandatory configuration items)
						$cmcount = $optarr.Count
						if($cmcount -lt 3) {
							Echo-Log "ERROR: The number of manadatory configuration items is not correct." 
							return $false
						}
					
						$cfgoption = $optarr[0].Trim()
									
						# Check if option is allowed and add to option array list					
						switch ($cfgoption) 
    					{ 
							'$LOGFILE$' { $LOGFILE = $optarr[1] ; if($optarr[2] -eq 'OVERWRITE') { $LOGFILEAPPEND = 'false' } }
        					'$FILE$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$FILES$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$FOLDER$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$FOLDERS$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$ALLCONTENT$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$UDPATEARCHIVES$' { Echo-Log "Skipping deprecated option $cfgoption" }
							'$ZIPFILES$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$ZIPFILESFOLDERS$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$ZIPSUBFOLDERSONLY$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
							'$ZIPSINGLEFILES$' { $FSO += , $optarr ; Echo-Log "Adding option $cfgoption" }
        
							# Anything else will result in an error.
    	    				default {
								Echo-Log "ERROR: Configuration option $cfgoption could not be determined."								
								return $false
							}
    					}
					}
				}
			}	
		}
 
		# get an XMLTextWriter to create the XML
		$XmlWriter = New-Object System.XMl.XmlTextWriter($Xml_path, $Null)

		# choose a pretty formatting:
		$xmlWriter.Formatting = 'Indented'
		$xmlWriter.Indentation = 1
		$XmlWriter.IndentChar = "`t"

		# write the header
		$xmlWriter.WriteStartDocument()
 
		# set XSL statements
		$xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
		
		# create root element "machines" and add some attributes to it
		$xmlWriter.WriteStartElement('cleanup')	

		# Add configuration attributes
		$XmlWriter.WriteAttributeString('description', $Global:DESCRIPTION)
		$XmlWriter.WriteAttributeString('version', $Global:VERSION)
		$XmlWriter.WriteAttributeString('type', $Global:Type)
		$XmlWriter.WriteAttributeString('logfile', $LOGFILE)
		$XmlWriter.WriteAttributeString('append', $LOGFILEAPPEND)	
	
		$date = Get-Date
		$Comment = "This file is the result of a conversion that took place on $date"
		$xmlWriter.WriteComment($Comment)
	
		foreach($Opt in $FSO) {	
			$ClType = $Opt[0].Replace('$','')
			$ClPath = $Opt[1]
			$ClMask = $null
			$ClKeep = $null
	
			# Remove deprecated entries which we do not need.
			$skipped = $false
			if($ClPath.contains('OCSInv')) { $skipped = $true }
			if($ClPath.contains('PSMOM')) { $skipped = $true }
			if($ClPath.contains('PSRemoteMom')) { $skipped = $true }
			if($ClPath.contains('DefragRun')) { $skipped = $true }			
	
			if($skipped -eq $false) { 
				# create root element "fsobject" and add attributes to it
				$xmlWriter.WriteStartElement('fsobject')	
				$XmlWriter.WriteAttributeString('description', 'File system object')				
			
				$ClAge = $Opt[2]
			
				#
				# <option>,<name>,<age> [,<mask>][,<keep>]
				#
	
				# Mandatory attributes
				$XmlWriter.WriteAttributeString('type', $ClType)
				$XmlWriter.WriteAttributeString('path', $ClPath)
				$XmlWriter.WriteAttributeString('age', $ClAge)
	
				# Optional attributes			
				if($opt.Count -gt 3) { $ClMask = $Opt[3] }
				if($opt.Count -gt 4) { $ClKeep = $Opt[4] }
				
				if([string]::IsNullOrEmpty($ClKeep) -eq $false) { $XmlWriter.WriteAttributeString('keep', $ClKeep) }
			
				# Split up mask string into include and exclude wildcards
				$ClInclude = $null
				$ClExclude = $null
			
				$exclude = $null
				$include = $null
			
				# Check mask parameter
				if([string]::IsNullOrEmpty($ClMask) -ne $true) {
					Echo-Log "Converting mask values: $ClMask" 
					# Create an array of mask values
					$ClMask = $ClMask.Trim()				
					if($ClMask.contains(' ')) {
						$maskarr = $ClMask -split ' '
						if($maskarr.count -gt 0) {
							foreach($mask in $maskarr) {
								$mask = $mask.Trim()													
								$transval = Translate-Mask $mask 
								if($mask.contains('-')) {
									if($exclude -eq $null) { 
										$exclude = $transval
									} else {
										$exclude = $exclude + ',' + $transval
									}
								} else {
									if($include -eq $null) { 
										$include = $transval 
									} else {
										$include = $include + ',' + $transval 
									}
								}
							}
						}
					} else {
						# The mask does not contain multiple values
						$mask = $ClMask.Trim()				
						$transval = Translate-Mask $mask
						if($mask.contains('-')) {
							if($exclude -eq $null) { 
								$exclude = $transval
							} else {
								$exclude = $exclude + ',' + $transval
							}
						} else {
							if($include -eq $null) { 
								$include = $transval 
							} else {
								$include = $include + ',' + $transval 
							}
						}
					}
				}			
				
				# Revert to original mask if option ZIPSINGLEFILES is choosen
				# if($ClType -eq 'ZIPSINGLEFILES') { $include = $Opt[3] }
				
				# Make sure the FILE and FOLDER type does not includes a wildcard as it is pointless
				if($ClType -eq 'FILE') { if([string]::IsNullOrEmpty($include) -eq $false) { $include = $null ;  $exclude = $null } }
				if($ClType -eq 'FOLDER') { if([string]::IsNullOrEmpty($include) -eq $false) { $include = $null ;  $exclude = $null } }
				
				# Make sure the FOLDERS type includes the default wildcard *
				# This result is an assumption!
				if($ClType -eq 'FOLDERS') {	if($include -eq $null) { $include = '*' } }
				
				# Make sure invalid masks are corrected
				if($include -eq '*.*') { $include = '*' } 
				if($exclude -eq '*.*') { $exclude = '*' } 
								 
				if([string]::IsNullOrEmpty($include) -eq $false) { 
					Echo-Log "Adding include attribute value: $include" 
					$XmlWriter.WriteAttributeString('include', $include) 
				}			
				if([string]::IsNullOrEmpty($exclude) -eq $false) { 
					Echo-Log "Adding exclude attribute value: $exclude" 
					$XmlWriter.WriteAttributeString('exclude', $exclude) 
				}
				
				$Comment = "Converted from $Ini_path"
				$XmlWriter.WriteAttributeString('comment', $Comment)
	
				# close the "fsobject" node:
				$xmlWriter.WriteEndElement()
				
				# Log conversion to database
				if([string]::IsNullOrEmpty($ClKeep)) { $ClKeep = 0}
								
				$query = "INSERT INTO [dbo].[CleanupConversion] ([Systemname],[ConvertDate],[Type],[Path],"
				$query += "[Age],[Keep],[Include],[Exclude],[Comment],[Description]) "
				$query += "VALUES ('$Systemname', '$ConvertDate','$CLType',"
				$query += "'$CLPath',$CLAge,$ClKeep,'$include','$exclude','$Comment','$Global:DESCRIPTION')"

				try {
					$data = Query-SQL $query $SQLconn
				}
				catch {
				}
			}
		}
 
 		Echo-Log "Creating XML document $Xml_path" 
		# finalize the document:
		$xmlWriter.WriteEndDocument()
		$xmlWriter.Flush()
		$xmlWriter.Close()

		Echo-Log "End XML conversion of $Ini_path" 
		Echo-Log ("=" * 80) 
	
		$conversion_result = Test-Path $Xml_path
		return $conversion_result	
	}
}

#
# Create XML filepath from the INI filepath
#
Function Create-XMLPath {
	[cmdletbinding()]
    Param(
#        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
#        [ValidateNotNullOrEmpty()] 
        [string[]]$ini_filepath
    )
    Process {
       	$ini_filename = Split-Path $ini_filepath -Leaf
		$xml_filename = $ini_filename.replace('.ini', '.xml')
		$standard_xml = (Split-Path $ini_filepath) + '\' + $xml_filename	
		return $standard_xml
    }
}

#
# Rename the INI file so it becomes unusable
#
Function Rename-INIFile {
	[cmdletbinding()]
    Param(
#        [parameter(ValueFromPipeline)]
#        [ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
        [string]$ini_filepath
    )
    Process {
		
		if ($Global:DEBUG -eq $true) { Echo-Log "$Global:cWarn DEBUG: INI file is not renamed." ; return }
	
		$ini_filename = Split-Path $ini_filepath -Leaf		
		$new_filename = $ini_filename.replace('.ini', '.do_not_use.in_')
		$new_filepath = (Split-Path $ini_filepath) + '\' + $new_filename	
		if(Test-Path $new_filepath) { 
			Echo-Log "Removing existing file $new_filename" 
			Remove-Item $new_filepath -Force -ErrorAction SilentlyContinue 
		}
		Echo-Log "Rename file $ini_filepath to $new_filename" 
		Rename-Item -Path $ini_filepath -NewName $new_filename		
	}
}

Function Create-CleanupSetXML {
	param (
		$arr_xml,
		[string[]]$xml_cleanupset
	)
					
	# get an XMLTextWriter to create the XML					
	$XmlWriter = New-Object System.XMl.XmlTextWriter($xml_cleanupset, $Null)	

	# choose a pretty formatting:
	$xmlWriter.Formatting = 'Indented'
	$xmlWriter.Indentation = 1
	$XmlWriter.IndentChar = "`t"

	# write the header
	$xmlWriter.WriteStartDocument()

	# set XSL statements
	$xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
		
	# create root element "machines" and add some attributes to it
	$xmlWriter.WriteStartElement('cleanup')	

	# Add configuration attributes
	$XmlWriter.WriteAttributeString('description', 'Set of cleanup XML files')
	$XmlWriter.WriteAttributeString('version', '1.0')					
	
	$date = Get-Date
	$Comment = "This file is the result of a conversion that took place on $date"
	$xmlWriter.WriteComment($Comment)
					
	foreach($xmlfile in $arr_xml) {	
		# create root element "CleanupObj" and add attributes to it
		$xmlWriter.WriteStartElement('CleanupObj')
		$XmlWriter.WriteAttributeString('path', $xmlfile) 
		$xmlWriter.WriteAttributeString('description', 'Cleanup configuration set')
		$xmlWriter.WriteAttributeString('comment', "Converted by Cleanup_ini2xml on $date")		
		
		# close the "CleanupObj" node:
		$xmlWriter.WriteEndElement()
	}
	
	# finalize the document:
	$xmlWriter.WriteEndDocument()
	$xmlWriter.Flush()
	$xmlWriter.Close()
}

Function New-CleanupSetXML {
	param (
		[string[]]$xml_cleanupset
	)
					
	# get an XMLTextWriter to create the XML					
	$XmlWriter = New-Object System.XMl.XmlTextWriter($xml_cleanupset, $Null)	

	# choose a pretty formatting:
	$xmlWriter.Formatting = 'Indented'
	$xmlWriter.Indentation = 1
	$XmlWriter.IndentChar = "`t"

	# write the header
	$xmlWriter.WriteStartDocument()

	# set XSL statements
	$xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
		
	# create root element "machines" and add some attributes to it
	$xmlWriter.WriteStartElement('cleanup')	

	# Add configuration attributes
	$XmlWriter.WriteAttributeString('description', 'Set of cleanup XML files')
	$XmlWriter.WriteAttributeString('version', '1.0')					
	
	$date = Get-Date
	$Comment = "New Cleanup set configuration created on $date"
	$xmlWriter.WriteComment($Comment)	
	
	# finalize the document:
	$xmlWriter.WriteEndDocument()
	$xmlWriter.Flush()
	$xmlWriter.Close()
}

#----------------------------------------------------------------------------------
cls
# Create default folder structure if it is not there already
Create-FolderStruct "C:\Logboek\Cleanup"
Create-FolderStruct "C:\Scripts\Cleanup"

Remove-Item 'C:\Logboek\Cleanup\*' -Force -ErrorAction SilentlyContinue

# Start logging
$Global:glb_EVENTLOGFile = 'C:\Logboek\Cleanup\Cleanup-INI2XML.log'
[void](Init-Log -LogFileName $Global:glb_EVENTLOGFile $false -alternate_location $True)

Echo-Log "Starting conversion script on system $($env:Computername)." 
$psmaj = ($PSVersionTable.PSVersion).Major
$psmin = ($PSVersionTable.PSVersion).Minor
$PsText = "Powershell $psmaj.$psmin"
if($psmaj -ge 3) { 
	$x64Prc = [Environment]::Is64BitProcess
	if($x64Prc -eq $True) { $PsText += " running x64 host process" }
}
if (Test-Admin) {
	$PsText += " in (UAC) Administrator mode."
} else {
	$PsText += " in regular user mode."
}
Echo-Log $PsText

$UDL = Read-UDLConnectionString $glb_UDL
$SQLconn = New-UDLSQLconnection $UDL
if ($SQLconn.state -eq "Closed") { 
	Echo-Log "The SQL connection could not be made or is forcefully closed."	
	$ErrorVal=9010
	return $ErrorVal
}
	
# Execute view from SECDUMP.
$Systemname = $env:COMPUTERNAME
$query = "Delete from CleanupConversion where Systemname = '$Systemname'"
$data = Query-SQL $query $SQLconn

if ($Global:DEBUG -eq $true) {
	Echo-Log "$Global:cWarn *D*E*B*U*G* MODE: INI files are not tampered with. This is a test run only." 
}

$ErrorC = $false
# Convert the default INI
$standard_ini = 'C:\Scripts\Acties\cleanup.ini'	
if (Test-Path $standard_ini) {	
	$standard_xml = Create-XMLPath $standard_ini
#    if(Test-Path $standard_xml) {
#        Echo-Log "$Global:cReq $standard_ini is skipped because it is already converted."
#    } else {
	    Echo-Log "Converting default INI: $standard_ini to $standard_xml" 
 	    $result = Convert-INIFile $standard_ini $standard_xml
	    if($result) {
		    Echo-Log "The conversion was successfully completed." 
		    Rename-INIFile $standard_ini
	    } else {		
		    Echo-Log "$Global:cErr ERROR: The conversion was not successfully completed." 
		    $ErrorC = $true
	    }
 #   }
} else {
	Echo-Log "$Global:cErr ERROR:$standard_ini was not found. There is nothing to convert."  
}

# Convert additional INI files
$arr_inifiles = 'C:\Scripts\Cleanup\CleanupSet.ini'
$xml_cleanupset = 'C:\Scripts\Cleanup\CleanupSet.xml'
if(Test-Path $arr_inifiles) {
	$ini_files = Get-Content $arr_inifiles
	if([string]::IsNullOrEmpty($ini_files) -eq $false) { 
		$xmlarr = $null
		foreach($add_ini in $ini_files) { 
			if( ([string]::IsNullOrEmpty($add_ini) -eq $false) -and (Test-Path $add_ini)) {	
				$add_xml = Create-XMLPath $add_ini
				Echo-Log "Converting additional INI: $add_ini to $add_xml"  
				$result = Convert-INIFile $add_ini $add_xml
				if($result) {
					Echo-Log "The conversion was successfully completed."  										
					# Add new XML filename to array
					$xmlarr += , $add_xml									
					
					# Rename the INI file to make sure it isn't used again.
					Rename-INIFile $add_ini
					
				} else {
					Echo-Log "$Global:cErr ERROR: The conversion was not successfully completed."  
					$ErrorC = $true
				}
			} else {
                if( ([string]::IsNullOrEmpty($add_ini) -eq $false) ) {
				    Echo-Log "$Global:cErr ERROR: $add_ini cannot be found. Invalid file entry?"
                }
			}
		}
		
		if($xmlarr) {
			Echo-Log "Creating CleanupSet.xml from array of successfully converted INI files."
			Create-CleanupSetXML $xmlarr $xml_cleanupset
		} else {
			Echo-Log "$Global:cErr ERROR:No CleanupSet.xml needs to be created. No INI conversions were successfull."
		}
		
		# Rename CleanupSet.ini
		Rename-INIFile $arr_inifiles
	} else {
		Echo-Log "$Global:cReq $arr_inifiles is empty."
	}
} else {
	Echo-Log "$arr_inifiles was empty or not found."
	if(Test-Path $xml_cleanupset) {
		Echo-Log "$xml_cleanupset was found. We do not touch an existing set."
	} else {
		Echo-Log "$xml_cleanupset was not found. A new set is created."
		New-CleanupSetXML $xml_cleanupset
	}
}

# We are done.
Echo-Log "End of conversion script."

Close-LogSystem

Remove-SQLconnection $SQLconn

# =========================================================
# Check if an error was thrown, if so, send an email.
#
if($ErrorC -eq $true) {
	$SendTo = "m.jussen@vdlnedcar.nl"
	$CompName = $env:COMPUTERNAME
	$title = "$CompName Cleanup conversion returned an error."
	Send-HTMLEmail-LogFile -FromAddress "m.jussen@vdlnedcar.nl" -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $Global:EventLogFile -Headline $Title
}
# =========================================================