# ------------------------------------------------------------------------------
# Define cleanup XML definitions for SPATZ workstation
#
# Marcel Jussen
# 21-11-2014
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $false
$Global:PathRoot = $null

#
# Checks if the default folder for Spatz exists and inventories the folders that contain
# a predefined pathname pattern.
#
Function Check_SPATZ_Path {
	Param (
		[string]$Spatz_Path = 'D:\Matuschek',
		[string]$Include = '*QA_Curves*'
    ) 		
	try {
		Get-ChildItem -path $Spatz_Path -Include $Include -Recurse -Force -errorAction SilentlyContinue | where {$_.psIsContainer -eq $true} | select Fullname
		# The fast way... for PS3 or PS4
		# [System.IO.Directory]::EnumerateDirectories($Spatz_Path, $Include, "AllDirectories")		
	}
	
	catch [UnauthorizedAccessException] {
    	$exception = $_.Exception.Message
  	}    
}

Function Create_SPATZ_Cleanup {
	param (
		[String]$XML_Path = 'C:\Scripts\Cleanup\SPATZ.xml',
		[Object]$Curves_Folders
	)
	
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
	$XmlWriter.WriteAttributeString('description', 'SPATZ Cleanup old CRW data in QA_Curves')
	$XmlWriter.WriteAttributeString('version', '1.0')
	$XmlWriter.WriteAttributeString('type', 'PRODUCTION')
	$XmlWriter.WriteAttributeString('logfile', 'C:\Logboek\Cleanup\SPATZ_QA_Curves_Cleanup.log')
	$XmlWriter.WriteAttributeString('append', 'False')	
	
	$date = Get-Date
	$Comment = "This file was automatically created on $date"
	$xmlWriter.WriteComment($Comment)
	
	$Comment = @"

  ####################
  USAGE
  ####################
  <fsobject type=<type> path=<path> age=<age> keep=<keep> include=<include> exclude=<exclude> description=<description> comment=<comment> />

  ####################
  MANDATORY ATTRIBUTES
  ####################
  <type> : (string)      The following strings apply to <type>:
  
  FILE                   Deletes a single file in folder <path> if older than <age> days.
  FILES or FILES_RECURSE Deletes all files in folder <path> and all its subfolders
                           if the file is older than <age> days but keep the latest <keep> number of files.
  FILES_NORECURSE        Deletes all files in folder <path> if the file is older than <age> days
                           but keep the latest <keep> number of files. Files in subfolders are not touched.
  
  FOLDER                 Deletes folder <folder> and content if the folder is older than <age> days.
  FOLDERS                Deletes only subfolders in folder <folder> if the subfolder is older than <age> days 
                           but keep the latest <keep> number of folders.
  ALLCONTENT             Deletes files and subfolders in a folder if the file/folder is older than <age>                         
						 
  ZIPFILES               Compress contents of a folder <path> into a ZIP archive named archive.zip No subdirs under the folder are archived.
  ZIPFILESFOLDERS        Compress contents of a folder <path> and all its subfolders into a ZIP archive (archive.zip).
  ZIPSUBFOLDERSONLY      Compress contents of a folder <path> of all subfolders into a ZIP (archive.zip). Make an archive per subfolder.				  
                         Archive names are always set to 'archive.zip'.
						 
  ZIPSINGLEFILES         Compress a single data file into a zip file in the subfolder named history. Only the include option is used. 
                         This type does not travers subfolders.
						 
  <path> : (string)      Pathname of file or folder. May include environment variables which are expanded in realtime values. 
                         Examples: C:\Temp or %SYSTEMDRIVE%\Temp
  
  <age>  : (integer)     Age in days. 
                         Files/folders with a last modification date less than OR equal to the current date minus <age> days are deleted.

  ####################
  OPTIONAL ATTRIBUTES
  ####################
  <keep>        : (integer)  Default=0. Keep a number of files. The latest number of files or folders are kept.
  <include>     : (wildcard) Default=*.* Part of the pathname to include in the cleanup.
  <exclude>     : (wildcard) Default=null Part of the pathname to exclude in the cleanup.
  <description> : (string)   Used to add a description for the cleanup rule.
  <comment>     : (string)   Used to add comments for the cleanup rule.

  ####################
  EXAMPLES
  ####################
  <fsobject type="FILES" path="%SYSTEMDRIVE%\inetpub\logs\LogFiles" age="91" keep="100" />
  Deletes all files in C:\inetpub\logs\LogFiles and its subfolders which have not been modified in less than 91 days but keep the 100 youngest files.
  
  <fsobject type="FILES" path="C:\temp" age="10" include="*.cup"/>
  Deletes all files ending in .cup in C:\temp and its subfolders which have not been modified in less than 10.
  
  <fsobject type="ZIPFILESFOLDERS" path="C:\Temp" age="25"/>
  ZIP contents of folder C:\Temp and all its subfolders into a ZIP archive called C:\Temp\archive.zip.
  
  
"@

	# Write comment to XML file
	$XmlWriter.WriteComment($Comment)
	
	if($Curves_Folders) { 
		foreach($Folder in $Curves_Folders) {
			$ClType = 'FOLDER'
			$ClAge = 60
			
			# List subfolders
			
			#  The fast way for PS3 or PS4 
			# $Curves_SubFolders = [System.IO.Directory]::EnumerateDirectories($Folder)
			$Curves_SubFolders =  Get-ChildItem -path $Folder.Fullname -Force -errorAction SilentlyContinue | where {$_.psIsContainer -eq $true} | select Fullname
			
			foreach($SubFolder in $Curves_SubFolders) {
				$ClPath = $SubFolder.Fullname
				
                if($CLPath.Length -gt 0) {			
				    $xmlWriter.WriteStartElement('fsobject')	
				    $XmlWriter.WriteAttributeString('description', 'File system object')
				    $XmlWriter.WriteAttributeString('type', $ClType)
				    $XmlWriter.WriteAttributeString('path', $ClPath)
				    $XmlWriter.WriteAttributeString('age', $ClAge)
				    $xmlWriter.WriteEndElement()
                }
			}
		}
	}
	
	Echo-Log "Creating XML document $Xml_path" 
	# finalize the document:
	$xmlWriter.WriteEndDocument()
	$xmlWriter.Flush()
	$xmlWriter.Close()

}

Function Create_CleanupSet {
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
	$Comment = "This file was automatically created on $date"
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

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Spatz_Cleanup_Define"

# Create logboek folder if it does not exist
if([System.IO.Directory]::Exists('C:\Logboek') -ne $true) {
	$temp = New-Item -ItemType directory -Path 'C:\Logboek' -ErrorAction SilentlyContinue
}
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"
Echo-Log ("-"*60)

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

# Check if the application is installed 
$SPATZ_Folder = 'D:\Matuschek\'
$AppPresent = [System.IO.Directory]::Exists($SPATZ_Folder)

if($AppPresent -ne $true) {
	Echo-Log "Spatz Studio NET.exe could not be found. We assume that archiving/cleanup is not needed."	
} else {

	$SPATZ_Include = '*QA_Curves*'
	Echo-Log "Create collection of folders with $SPATZ_Include"
	$folders = Check_SPATZ_Path $SPATZ_Folder $SPATZ_Include	
	
	$Cleanup_Definition = 'C:\Scripts\Cleanup\SPATZ.xml' 
	
	# Create Cleanup definition file.
    Echo-Log "Creating definition file."
	Create_SPATZ_Cleanup $Cleanup_Definition $folders
	
	# Add cleanup definition file to Cleanup definition set.
    Echo-Log "Adding definition file to cleanup set."
	$xmlarr = $null
	$xml_cleanupset = 'C:\Scripts\Cleanup\CleanupSet.xml'
	$xmlarr += $Cleanup_Definition
	Create_CleanupSet $xmlarr $xml_cleanupset
}

# We are done. Close the log.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)