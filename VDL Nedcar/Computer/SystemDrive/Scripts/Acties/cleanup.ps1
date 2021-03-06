# =========================================================
# VDL Nedcar - Information Systems
#
# .SYNOPSIS
# 	VNB File system cleanup
#
# .CREATED_BY
# 	Marcel Jussen
#
# .CHANGE_DATE
# 	12-05-2016
#
# .DESCRIPTION
#	Cleanup filesystem with XML input
#
# =========================================================
#Requires -version 3.0

[CmdletBinding()]
Param(
	[string]$CleanupXMLInputFile,
    [string]$ScriptMode = "PROD",
	[string]$ScriptLogFile
)

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

# ---------------------------------------------------------
# Ensures you only refer to variables that exist (great for typos)
# and enforces other “best-practice” coding rules.
Set-StrictMode -Version Latest

# ---------------------------------------------------------
# enforces all errors to become terminating unless you override with 
# per-command -ErrorAction parameters or wrap in a try-catch block
$script:ErrorActionPreference = "Stop"

# ---------------------------------------------------------
# Be aware that the DEBUG value is ALWAYS overriden by the cleanup type value in the config XML 
# So always set the debug parameter in the XML input file. DO NOT CHANGE THE VALUE HERE!!
$Global:DEBUG   = $False
# ---------------------------------------------------------
# Set the variable TEST_OVERRULE to true to override the XML debug attribute
# If the variable is set to true, debug mode is set to true. 
$Global:TEST_OVERRULE = $False

# ---------------------------------------------------------
# Check command line parameter -ScriptMode if it is set to DEBUG
if([string]::IsNullOrEmpty($ScriptMode) -ne $True) {
	$ScriptMode = $ScriptMode.Trim()
	$ScriptMode = $ScriptMode.ToUpper()
	if($ScriptMode -eq 'DEBUG') { $Global:DEBUG = $true }
}

# ---------------------------------------------------------
Function Show-FreeMemory {
# ---------------------------------------------------------
# Show free memory after trigger of garbage collection
# ---------------------------------------------------------
	try {
		# Trigger garbage collect		
		[System.GC]::Collect()
		
		$os = Get-Ciminstance Win32_OperatingSystem
		$pctFree = [math]::Round(($os.FreePhysicalMemory/$os.TotalVisibleMemorySize)*100,2)	
		$FreeGb = [math]::Round($os.FreePhysicalMemory/1mb,2)
		$msg = "Physical Memory free: $FreeGb Gb ($pctFree %) post GC collection"
		echo-Log $msg 
		
		$pctFree = [math]::Round(($os.FreeVirtualMemory/$os.TotalVirtualMemorySize)*100,2)	
		$FreeGb = [math]::Round($os.FreeVirtualMemory/1mb,2)
		$msg = "Virtual Memory free: $FreeGb Gb ($pctFree %)  post GC collection"
		echo-Log $msg 
	}
	catch {
		Echo-Log $_.Exception|format-list -force
	}
	Clear-LogCache
}

Function Check-CleanupXML {
# ---------------------------------------------------------
# Check input XML formatting
# ---------------------------------------------------------
	[cmdletbinding()]
    Param(
#        [parameter(ValueFromPipeline)]
#        [ValidateNotNullOrEmpty()] 
        [xml[]]$xmlData 
    )
    Process {
		$result = $false	
		$xmlCount = $xmldata.Count
		if ( $xmlCount -le 1 ) { 
			foreach($xdoc in $xmlData) {
				$xdoccount = $xdoc.ChildNodes.count
				if($xdoccount -gt 0) { $result = $true }
			}
		} else {
			Write-Error "XML input file does not contain valid cleanup information."
			$result = $false
		}	
		return $result
	}
}

# ---------------------------------------------------------
Function Parse-CleanupXML {
# ---------------------------------------------------------
# Parse each cleanup parameter
# ---------------------------------------------------------
	[cmdletbinding()]
    Param(
		[ValidateNotNullOrEmpty()]
		$CleanupParams      
    )
    Process {        
   		if ([string]::IsNullOrEmpty($CleanupParams.ObjectPath) -eq $false) { 
    		if (Test-Path $CleanupParams.ObjectPath) {	
	    		
				if ($Global:DEBUG) { 
		    		Echo-Log "$Global:cWarn (DEBUG) Type:[$($CleanupParams.Type)]" 
			    }
				
				# Always define recursion as not needed.
				$Recurse = $false
				
   				switch ($CleanupParams.Type)
    			{
	    			# Remove a single file
		    		"FILE" { Invoke-CleanupFile $CleanupParams }
				
   					# Remove files in a folder but not its subfolders
    				"FILES_NORECURSE" { Invoke-CleanupFiles $CleanupParams }
				
   					# Remove files in a folder and all its subfolders
    				"FILES" { 
						$CleanupParams.Recurse = $true
	    				Invoke-CleanupFiles $CleanupParams
		    		}
			    	"FILES_RECURSE" {
						$CleanupParams.Recurse = $true
   						Invoke-CleanupFiles $CleanupParams
    				}				
		    		
		    		# Remove a folder
			    	"FOLDER" { Invoke-CleanupFolder $CleanupParams }					
				
    				#Remove subfolders from a folder
				    "FOLDERS" { Invoke-CleanupFolders $CleanupParams }
					"SUBFOLDERS" { Invoke-CleanupFolders $CleanupParams }
				
   					# Remove all files and folders from a folder
    				"ALL" { 						
						Invoke-CleanupFolders $CleanupParams
						$CleanupParams.Recurse = $true
	    				Invoke-CleanupFiles $CleanupParams
			    	}
					"ALLCONTENT" { 						
						Invoke-CleanupFolders $CleanupParams
						$CleanupParams.Recurse = $true
	    				Invoke-CleanupFiles $CleanupParams
			    	}
					
					# Create a zip archive per file in a folder and its subfolders.					
					"ZIPSINGLEFILE_TO_SINGLEARCHIVE" {
						# Archive name is determined by file name
						$CleanupParams.ZipFile = $null
						# Move file into a zip archive 
						$CleanupParams.ZipAction = 'M'
						Invoke-ZipFileToArchive $CleanupParams
					}
				
   					# Create a zip archive with the contents of a folder but not its subfolders.
    				"ZIPFILES" {
	    				# Archive name
		    			$CleanupParams.ZipFile = $($CleanupParams.ObjectPath) + "\archive.zip" 
			    		# Move files from a folder into a zip archive without subfolder recursion
				    	$CleanupParams.ZipAction = 'M'
					    Invoke-ZipFilesAndFolders $CleanupParams
				    }
						
                    # Creates a zip archive with the contents of a folder and its subfolders
   					"ZIPFILESFOLDERS" { 
    					# Archive name
	    				$CleanupParams.ZipFile = $($CleanupParams.ObjectPath) + "\archive.zip" 
		    			# Move files and folders from a folder into a zip archive.
			    		$CleanupParams.ZipAction = 'M -r'
				    	Invoke-ZipFilesAndFolders $CleanupParams
   					}
							
				    # Create a zip archive per subfolder with subfolder recursion.
				    "ZIPSUBFOLDERSONLY" {
						$CleanupParams.ZipAction = 'M -r'
					    Invoke-ZipSubFoldersOnly $CleanupParams
   					} 
	    				
		    		# Create a zip archive per subfolder in a history folder with subfolder recursion.
	    			"ZIPHISTORY" { 					
						$CleanupParams.ZipAction = 'M -r'
                        Invoke-ZipSingleFiles $CleanupParams
				    } 
					"ZIPSINGLEFILES" { 					
						$CleanupParams.ZipAction = 'M -r'
                        Invoke-ZipSingleFiles $CleanupParams
				    }
					
					# Create a zip archive per month in SAP Audit log folder containing AUD files
					"ZIPSAPAUDITLOGS" {
						# Move to archive and do not store full path names
						$CleanupParams.ZipAction = 'M -ep1'
						Invoke-ZipSAPAuditLogs $CleanupParams
					}

                    # NTFS Compress folder and contents with recursion
                    "COMPRESSNTFSFOLDER" {
                        Invoke-CompressFolder $($CleanupParams.ObjectPath)
                    }

                    # NTFS Compress folder and contents with recursion
                    "DECOMPRESSNTFSFOLDER" {
                        Invoke-DecompressFolder $($CleanupParams.ObjectPath)
                    }					
				    
					# Anything else does not fly here..
  					default { 
    					Error-Log "$Global:cErr ERROR: Invalid type value '$($CleanupParams.Type)' was used." 
	    			} 
		    	}
				
				# Show free memory
				Show-FreeMemory 
				
		    } else {
			    Echo-Log "$Global:cErr ERROR: $($CleanupParams.ObjectPath) was not found."
		    }
	    } else {
		    Error-Log "$Global:cErr ERROR: Invalid markup in XML file. Folder parameter cannot be empty."
	    }
    }           
}

# --------------------------------------------------------- 
Function Copy-Howto {
# ---------------------------------------------------------
# Copy user manual next to the input XML 
# ---------------------------------------------------------
	param (
		[ValidateNotNullOrEmpty()]
		[string]$Path
	)
	begin {
		$DocFile = 'Windows FS Cleanup script v1.0.pdf'
		$Howto = "C:\Scripts\Acties\$DocFile"
		$Destination = $Path + '\' + $DocFile
	}
	process {
		if((Test-Path $Howto) -and -not(Test-Path($Destination))) {
			try {
				Copy-Item -Path $Howto -Destination $Path -ErrorAction SilentlyContinue
			}
			catch {
				Echo-Log "ERROR: Could not copy documentation document to $path"
			}
		}
	}
}

# ---------------------------------------------------------
Function Remove-ByXML { 
# ---------------------------------------------------------
# Start cleanup by loading and evaluating the input XML
# ---------------------------------------------------------
	[cmdletbinding()]
    Param(
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
		[string]$xml_filepath
    )	
	
    Process {
		if (Test-Path $xml_filepath) {
			# Copy the documentation file next to the XML file
			Copy-HowTo -Path (Split-Path $xml_filepath -Parent)
			
			Echo-Log "Reading XML attributes from $xml_filepath" 
			# load it into an XML object:
			$xml = New-Object -TypeName XML
			
			try {
				$xml.Load($xml_filepath)	
				$xmldata = $xml
			}
			catch {
				Echo-Log "ERROR: Loading the XML file resulted in an unrecoverable error."
				$xmldata = $null
			}
			
			$xmltype = $null
			$xmllogfile = $null			
			$xmllogfileappend = $null
	
			if ( (Check-CleanupXML $xmlData) -eq $true ) {
				try {
					$xmltype = $xmldata.cleanup.GetAttribute("type")
					$xmllogfile = $xmldata.cleanup.GetAttribute("logfile")
					$t = $xmldata.cleanup.GetAttribute("append")
					$xmllogfileappend = ($t.ToUpper() -eq "TRUE")
				}
				catch {
					$xmltype = $null
					$xmllogfile = $null			
					$xmllogfileappend = $null
				}
				
				#
				# check config properties and set default values if needed
				#
				if([string]::IsNullOrEmpty($xmltype)) { 
					Echo-Log "Cleanup configuration type was not defined."	
					Echo-Log "Using default value: PROD"
					$xmltype = 'PROD'
				}
				Echo-Log "Cleanup configuration state: $xmltype"
								
				if([string]::IsNullOrEmpty($xmllogfileappend)) { 
					Echo-Log "Cleanup configuration log mode was not defined."
					Echo-Log "Using default value: TRUE"
					$xmllogfileappend = $True
				}				
				Echo-Log "Cleanup configuration logfile append mode: $xmllogfileappend"
				
				#
				# Check command line parameter -ScriptLogFile 
				# Override log file name from XML file if it is set.
				#
				if([string]::IsNullOrEmpty($ScriptLogFile) -ne $True) { 
					Echo-Log "Cleanup logfile path is overridden by command prompt value."
					$xmllogfile = $ScriptLogFile				
				}
				
				if([string]::IsNullOrEmpty($xmllogfile)) {					
					Echo-Log "Cleanup configuration logfile path was not defined."
					$xmllogfile = '%SYSTEMDRIVE%\Logboek\Cleanup\Remove-undefined-log.log'
					Echo-Log "Using default value: $xmllogfile"
				}
				
		
				# Replace environment variables with real values.
				$xmllogfile = [System.Environment]::ExpandEnvironmentVariables($xmllogfile)
				Echo-Log "Initialize logfile: $xmllogfile"
				
				$Global:glb_EVENTLOGFile = $xmllogfile
				[void](Init-Log -LogFileName $xmllogfile $xmllogfileappend -alternate_location $True)				

                Echo-Log ("=" * 80)
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
				
				Echo-Log "Using input file : $xml_filepath"		
				Echo-Log "Logging appended : $xmllogfileappend"
				
				# Reset statistics
				Initialize-Cleanup

				# Be aware that the DEBUG value is ALWAYS overriden by the cleanup type value in the config XML 
				# So always set the debug parameter through the XML file! Do not change the value here.
				$Global:DEBUG = $false
				switch ( $xmltype.ToUpper() ) {
					"PROD"       { $Global:DEBUG = $false }
					"PRODUCTION" { $Global:DEBUG = $false }
					"PRODUCTIE"  { $Global:DEBUG = $false }
					"PRODUKTIE"  { $Global:DEBUG = $false }
					"PRODUKTION" { $Global:DEBUG = $false }
					default      { $Global:DEBUG = $true }
				}
			
				# Check if the script overrules DEBUG mode from the XML file
				if($Global:TEST_OVERRULE -eq $true) {
					Echo-Log "Script overruled debug mode is applied."
					$Global:DEBUG = $true
				}
			
				if($Global:DEBUG -ne $true ) {
					Echo-Log "Script mode is PRODUCTION. Changes are applied to the file system." 
				} else {
					Echo-Log "Script mode is *D*E*B*U*G*. Changes are NOT applied to the file system."				
				}
				if (Test-Admin) {			
					try {
						$fsobjects = $xmldata.SelectNodes("cleanup/fsobject")
						Echo-Log "The cleanup configuration contains [$($fsobjects.count)] rules."
					}
					catch {
						$fsobjects = $null
						Echo-Log "The cleanup configuration does not contain any rules."
					}
					
					$RuleCount = 0
					foreach ($fsoobj in $fsobjects) {
						$RuleCount++
						# A field variable not present in the XML file results in a $null value for that field
						# A field present but not filled with a value results in an empty string and must be changed into a $null value						

						# Mandatory field
						$fso_Folder = $null
						if (Get-Member -InputObject $fsoobj -Name path -MemberType Properties) {
							# Check folder string and convert environment values to realtime values
							$fso_Folder = [System.Environment]::ExpandEnvironmentVariables($fsoobj.path)
						}

						# Mandatory field
						$fso_type = $null
						if (Get-Member -InputObject $fsoobj -Name type -MemberType Properties) {
							$fso_type = $fsoobj.type
							$fso_type = $fso_type.ToUpper()
						}
						if([string]::IsNullOrEmpty($fso_type) -eq $false) { if($fso_type.length -eq 0 ) { $fso_type = $null } } 

						# Mandatory field
						$fso_age = $null
						if (Get-Member -InputObject $fsoobj -Name age -MemberType Properties) {
							$fso_age = $fsoobj.age
						}
						if([string]::IsNullOrEmpty($fso_age) -eq $false) { if($fso_age.length -eq 0) { $fso_age = $null } } 

						# Comment value and type value can have any value
						$fso_comment = $null
						if (Get-Member -InputObject $fsoobj -Name comment -MemberType Properties) {
							$fso_comment = $fsoobj.comment
						}						
						Echo-Log ("-" * 80)
						if ([string]::IsNullOrEmpty($fso_comment) -eq $false) { Echo-Log "Comment: $fso_comment" }
				
						# Check wildcard values. Empty values are converted to NULL
						$fso_include = '*'
						if (Get-Member -InputObject $fsoobj -Name include -MemberType Properties) {
    						$fso_include = $fsoobj.include
						} 
						if([string]::IsNullOrEmpty($fso_include) -eq $false) { if($fso_include.length -eq 0) { $fso_include = $null } } 
						
						$fso_exclude = $null
						if (Get-Member -InputObject $fsoobj -Name exclude -MemberType Properties) {
							$fso_exclude = $fsoobj.exclude
						} 						
						if([string]::IsNullOrEmpty($fso_exclude) -eq $false) { if($fso_exclude.length -eq 0) { $fso_exclude = $null } } 						
				
						$fso_keep = $null
						if (Get-Member -InputObject $fsoobj -Name keep -MemberType Properties) {
							$fso_keep = $fsoobj.keep
						}
						if([string]::IsNullOrEmpty($fso_keep) -eq $false) { if($fso_keep.length -eq 0) { $fso_keep = $null } } 

                        # Check for minimum requirements
						Echo-Log "Processing rule number [$RuleCount]"
						if(([string]::IsNullOrEmpty($fso_type) -eq $false) -and ([string]::IsNullOrEmpty($fso_folder) -eq $false) -and ([string]::IsNullOrEmpty($fso_age) -eq $false)) {
							
							# Lets use splatting for all our cleanup parameters
							$CleanupParams = @{
								Type = [string]$fso_type
								ObjectPath = [string]$fso_Folder
								Age = [int]$fso_age
								Include = [string]$fso_include
								Exclude = [string]$fso_exclude
								Keep = [int]$fso_keep
								ZipFile = [string]""
								ZipAction = [string]""
								Recurse = $false
							}						    
							Parse-CleanupXML $CleanupParams
                        } else {							
                            Error-Log "$Global:cErr This is fucked up. There is no type, folder or age defined!"
                        }
					}					
				} else {
					Error-Log "$Global:cErr This script is NOT running as an Administrator."
					Error-Log "$Global:cErr Script is aborted."
					Exit
				}
		
				Echo-Log ("-" * 80)
				Echo-Log "Cleanup has finished."				
				Echo-Log ("-" * 80)
				if ($Global:DEBUG -eq $True) { 
					Echo-Log "Script mode is *D*E*B*U*G*. Changes are NOT applied." 
				} 				
				Echo-Log "Using input file            : $xml_filepath"		
				Show-CleanupInfo $xml_filepath				
				$min = New-TimeSpan -Start ($Global:ScriptStart) -End (Get-Date)
				Echo-Log "Cleanup running time        : $min"				
				Echo-Log ("=" * 80)

                Close-LogSystem
			} else {
				Write-Error "$Global:cErr $xml_filepath is not a valid input file."
			}		
		} else {
			Write-Error "$Global:cErr ERROR: XML input file $xml_filepath cannot be found!"
		}
	}
}

# ---------------------------------------------------------
Function Remove-CleanupSetByXML {
# ---------------------------------------------------------
# Start evaluating the cleanup set
# ---------------------------------------------------------
	[cmdletbinding()]
    Param(
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
		[string]$xml_cleanupset_filepath
    )
    Process {
		Echo-Log "Processing additional cleanup files defined in $xml_cleanupset_filepath"		
		if (Test-Path $xml_cleanupset_filepath) {
			# Copy the documentation file next to the XML file
			Copy-HowTo -Path (Split-Path $xml_cleanupset_filepath -Parent)
		
			# load it into an XML object:
			$xml = New-Object -TypeName XML
			try {
				$xml.Load($xml_cleanupset_filepath)	
				$xmldata = $xml
			}
			catch {
				Echo-Log "ERROR: Loading the XML file resulted in an unrecoverable error."
				$xmldata = $null
			}
	
			if ( (Check-CleanupXML $xmlData) -eq $true ) {		
				if (Test-Admin) {
					$xmlobjects = $xmldata.SelectNodes("cleanup/CleanupObj")					
					Echo-Log "The cleanup set contains [$($xmlobjects.count)] cleanup configuration files."
					
					foreach ($xmlobj in $xmlobjects) {
						# A field variable not present in the XML file results in a $null value for that field
						# A field present but not filled with a value results in an empty string and must be changed into a $null value
				
						# Comment value and type value can have any value
                        try { $xml_comment = $xmlobj.comment }
                        catch { $xml_comment = $null }
                        try { $xml_description = $xmlobj.description }
                        catch { $xml_description = $null } 
				
						# Check path string and convert environment values to realtime values
						$xml_filepath = [System.Environment]::ExpandEnvironmentVariables($xmlobj.path)						
						if(test-path($xml_filepath)) {
							Remove-ByXML $xml_filepath
						} else {
							Echo-Log "Could not read $xml_filepath"
						}				
					}					
				} else {
					Error-Log "$Global:cErr This script is NOT running as an Administrator."
					Error-Log "$Global:cErr Script is aborted."
				}
			} else {
				Write-Error "$Global:cErr $xml_filepath is not a valid input file."
			}		
		} else {
			Write-Error "$Global:cErr ERROR: XML input file $xml_filepath cannot be found!"
		}
	}
}

# ---------------------------------------------------------
Function Get-ComputerApproval {
# ---------------------------------------------------------
# Check cleanup approval by scanning the approval lists
# ---------------------------------------------------------
    Process {
        $Result = $False
        Try {
            $Computername = $env:COMPUTERNAME
            $ApprovedList = Get-Content "C:\Scripts\Acties\systems-approved.ini"            
            $DisapprovedList = Get-Content "C:\Scripts\Acties\systems-disapproved.ini"

            # Check if approved
            if(!$Result) { $Result = (($ApprovedList | Select-String -Pattern '\*') -ne $null) }
            if(!$Result) { $Result = (($ApprovedList | Select-String -Pattern $Computername) -ne $null) }

            # Check if not approved
            if($Result) { $Result = !(($DisapprovedList | Select-String -Pattern '\*') -ne $null) }
            if($Result) { $Result = !(($DisapprovedList | Select-String -Pattern $Computername) -ne $null) }                    
        }
        Catch {
            Write-Host "ERROR: An error occured during approval check."
            $Result = $False
        }
        
        $Result
    }
}

# =========================================================
# Record start of script.
cls
$BaseStart = Get-Date
# Script Timer
$Global:ScriptStart = Get-Date

# Create default folder structure if it is not there already
[void]( Create-FolderStruct "$env:SYSTEMDRIVE\Logboek\Cleanup" )
[void]( Create-FolderStruct "$env:SYSTEMDRIVE\Scripts\Cleanup" )

$Cleanup_BaseLog = "$env:SYSTEMDRIVE\Logboek\Cleanup\Cleanup-base.log"
$Global:glb_EVENTLOGFile = $Cleanup_BaseLog
[void](Init-Log -LogFileName $Cleanup_BaseLog $False -alternate_location $True)

Echo-Log ("=" * 80)
Echo-Log "Starting cleanup process on $($env:Computername)."

# ---------------------------------------------------------
$Approved = Get-ComputerApproval
if($Approved) { 

    # Check if input was passed on the command line
    # If so, use this as our input XML file
    if([string]::IsNullOrEmpty($CleanupXMLInputFile)) {
	    $xml_filepath = "$env:SYSTEMDRIVE\Scripts\Acties\cleanup.xml"
	    Echo-Log "$Global:cReq Using default cleanup definition file: $xml_filepath"
    } else {
	    # Process default cleanup configuration file	
	    $xml_filepath = $CleanupXMLInputFile
	    Echo-Log "$Global:cReq Using command line defined cleanup definition file: $xml_filepath"
    }

    # Start cleanup with input file
    if([System.IO.File]::Exists($xml_filepath)) {		
	    Remove-ByXML $xml_filepath
    } else {
	    $Global:glb_EVENTLOGFile = $Cleanup_BaseLog
	    Echo-Log "Default cleanup definition file $xml_filepath was not found."
    }
    
    # Return logging to Base log in append mode
    $Global:glb_EVENTLOGFile = $Cleanup_BaseLog
    [void](Init-Log -LogFileName $Cleanup_BaseLog $True -alternate_location $True)       

    # ---------------------------------------------------------
    # Process additional cleanup configuration files
    # Only if the cleanup was not defined with command line option    
    if([string]::IsNullOrEmpty($CleanupXMLInputFile)) {
	    $collect_cleanup_files = "$env:SYSTEMDRIVE\Scripts\Cleanup\CleanupSet.xml"
	    if(Test-Path $collect_cleanup_files) {		   
		    Remove-CleanupSetByXML $collect_cleanup_files        
	    } else {
		    Echo-Log "Cleanup set $collect_cleanup_files was not found."
	    }	
    } else {
        # Return logging to Base log in append mode
        $Global:glb_EVENTLOGFile = $Cleanup_BaseLog
        [void](Init-Log -LogFileName $Cleanup_BaseLog $True -alternate_location $True)

	    Echo-Log ("=" * 80)	
	    Echo-Log "No additional cleanup definition files are used."	
	    Echo-Log ("=" * 80)	
    }

} else {
    Echo-Log "This computer is not approved to run this script."
    Echo-Log "Check C:\Scripts\Acties\systems-approved.ini and systems-disapproved.ini for valid systemnames."
}

# ---------------------------------------------------------
# Return logging to Base log in append mode
$Global:glb_EVENTLOGFile = $Cleanup_BaseLog
[void](Init-Log -LogFileName $Cleanup_BaseLog $True -alternate_location $True)

Echo-Log "End of cleanup script."
$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log "Total cleanup running time : $min"				
Echo-Log ("=" * 80)

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================