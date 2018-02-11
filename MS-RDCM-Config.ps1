# ---------------------------------------------------------
# Microsoft Remote Desktop Manager 2.2 
# Create configuration from domain 
# Marcel Jussen
# ---------------------------------------------------------
cls

#Requires -version 2.0

# Be aware that the DEBUG value is ALWAYS overriden by the cleanup type value in the config XML 
# So always set the debug parameter through the XML file! Do not change the value here.
$Global:DEBUG   = $false

# Text values
$Global:cSpacer = "  "
$Global:cReq    = "=>"
$Global:cWarn   = "@@"
$Global:cErr    = "**"

$Global:ScriptStart = Get-Date

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1

# ---------------------------------------------------------

Function Check-Cleanup-XML {
	param ( 
		[xml] $xmlData 
	)
	
	$result = $false
	$nodes = $xmldata.SelectNodes("RDCMan")
	if ( $nodes.Count -ne 0 ) {
		if($xmlData.RDCMan.version -eq "2.2") {
			$result = $true		
		}
	} else {
		Write-Error "XML input file does not contain valid XML markup."
		$result = $false
	}	
	return $result
}

Function Parse-Cleanup-XML {
	param ( 
		[string] $FSOType, 
		[string] $FSOFolder, 
		[int] $FSOAge, 
		[string] $FSOInclude, 
		[string] $FSOExclude, 
		[int] $FSOKeep 
	)
	
	if ($FSOFolder -ne "") { 
		if (Test-Path $FSOFolder) {	
			if ($Global:DEBUG) { 
				Echo-Log "$Global:cWarn DEBUG mode. Type: $FSOType" 
			}
			switch ($FSOType)
			{
				# Remove a single file
				"FILE" { 
					Cleanup_File -FSOfolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude 
				}
				
				# Remove files in a folder
				"FILES_NORECURSE" { 
					Cleanup_Files -FSOFolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude -FSOExclude $FSOExclude -FSOKeep $FSOKeep -Recurse $false 
				}
				
				# Remove files in a folder and all its subfolders
				"FILES_RECURSE" { 
					Cleanup_Files -FSOFolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude -FSOExclude $FSOExclude -FSOKeep $FSOKeep -Recurse $true 
				}
				"FILES" { 
					Cleanup_Files -FSOFolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude -FSOExclude $FSOExclude -FSOKeep $FSOKeep -Recurse $true 
				}
				
				# Remove a folder and its contents
				"FOLDER" { 
					Cleanup_Folder -FSOFolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude -FSOExclude $FSOExclude -FSOKeep $FSOKeep 
				}					
				
				#Remove subfolders and their contents
				"SUBFOLDERS" { 
					Cleanup_Subfolders -FSOFolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude -FSOExclude $FSOExclude -FSOKeep $FSOKeep 
				}
				"FOLDERS" { 
					Cleanup_Subfolders -FSOFolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude -FSOExclude $FSOExclude -FSOKeep $FSOKeep 
				}
				
				# Create a zip archive with the contents of a folder
				"ZIPFILES" { 
				} 
				"ZIP" { 
				}
				
				# Cleanup old MS update archive folders from SYSTEMROOT
				"UPDATEARCHIVE" { 
					Cleanup_WU_Archives -FSOFolder $FSOFolder -FSOAge $FSOAge -FSOInclude $FSOInclude -FSOExclude $FSOExclude -FSOKeep $FSOKeep 
				} 
				
				default { 
					Error-Log "$Global:cErr $FSOType An invalid type value was used!" 
				} 
			}
		} else {
			Echo-Log "$Global:cErr $FSOFolder is not found and skipped."
		}
	} else {
		Error-Log "$Global:cErr Invalid markup in XML file. Folder parameter cannot be empty."
	}	
}

$xml_filepath = "C:\Users\q055817\Google Drive\NedCar\nedcar.rdg"
if (Test-Path $xml_filepath) {	
	$xml = Get-Content $xml_filepath
	$xmldata = [xml]$xml
	
	if ( Check-Cleanup-XML $xmlData -eq $true ) {
						
		$ScriptName = $myInvocation.MyCommand.Path				
		$Global:glb_EVENTLOGScriptName = $ScriptName
		
		$Global:EventLogFile = "RDCMan-Config.log"
		[void](Init-Log -LogFileName $Global:EventLogFile)
		
		Echo-Log ("=" * 80)
		Echo-Log "Started script   : $ScriptName"
		Echo-Log "Using input file : $xml_filepath"				
				
		$Global:DEBUG = $true
			
		if (Test-Admin) {			
			$fso = $xmldata.SelectNodes("RDCMan/file/server")
			foreach ($a in $fso) {
				$rdcm_name = $a.name
				$rdcm_displayName = $a.displayName
				$rdcm_comment = $a.comment
				$rdcm_logonCredentials = $a.logonCredentials
							
				$srv = Search-AD-Server $rdcm_name				
				if($srv -eq $null) {
					Echo-Log "$rdcm_name <- not found in AD"
				} else {
					$comment = Get-ComputerComment $rdcm_name
					Echo-Log "$rdcm_name $comment"					
				}
				
            # <connectionSettings inherit="FromParent" />
            # <gatewaySettings inherit="FromParent" />
            # <remoteDesktop inherit="FromParent" />
            # <localResources inherit="FromParent" />
            # <securitySettings inherit="FromParent" />
            # <displaySettings inherit="FromParent" />
						
			}					
		} else {
			Error-Log "$Global:cErr This script is NOT running as an Administrator."
			Error-Log "$Global:cErr Script is aborted."
			Exit
		}
		
		Echo-Log ("-" * 80)
		Echo-Log "Statistics."		
		Echo-Log ("-" * 80)
		if ($Global:DEBUG -eq $True) { 
			Echo-Log "Script mode                 : *D*E*B*U*G* Changes are NOT applied."
			Echo-Log ""
		}
		
		$xmldata.Save
		
		
		if ($Global:DEBUG -eq $True) { 
			Echo-Log ""
			Echo-Log "Script mode                 : *D*E*B*U*G* Changes are NOT applied."
		}
		Echo-Log ("-" * 80)
		$min = New-TimeSpan -Start ($Global:ScriptStart) -End (Get-Date)
		Echo-Log "Script running time         : $min"
		Echo-Log ("-" * 80)
		Echo-Log "Ended script $ScriptName"		
		Echo-Log ("=" * 80)
	} else {
		Write-Error "$Global:cErr $xml_filepath is not a valid input file."
	}		
} else {
	Write-Error "$Global:cErr ERROR: XML input file $xml_filepath cannot be found!"
}