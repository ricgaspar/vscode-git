# ------------------------------------------------------------------------------
<#
.SYNOPSIS
    Synchronize website content to Display PC's.

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	11-03-2015

.CHANGE_DATE
	06-10-2015 Removed remote CRC check.
 
.DESCRIPTION
    Synchronizes website content to display PC's (koffie automaten)
#>
# ------------------------------------------------------------------------------
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib -force
# ---------------------------------------------------------

$Global:DEBUG = $false
$GLobal:ADOU_DisplayPC = 'LDAP://OU=DisplayPC_KoffieAutomaat,OU=IT,OU=Factory,DC=nedcar,DC=nl'		

# ------------------------------------------------------------------------------

Function Collect-AD-Computers {
	param (
		[string]$ADSearchFilter = '(objectCategory=Computer)',
		[string]$OUPath 
	)

	begin {
		try {
			$colResults = $null
			$objOU = New-Object System.DirectoryServices.DirectoryEntry($OUPath)
			$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
		}
		catch { } 
	}
	process {
		try {
			$objSearcher.SearchRoot = $objOU
			$objSearcher.PageSize = 5000
			$objSearcher.Filter = $ADSearchFilter      
			$colResults = $objSearcher.FindAll()
		}
		catch { } 
		return $colResults
	}
}

function Start-Executable {
# ---------------------------------------------------------
# Execute a command line program
# This functions sets variable $LASTEXITCODE which contains 
# the exit code of the executed program.
# ---------------------------------------------------------
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string] 
		$FilePath,
	
		[parameter(Mandatory=$True)]
		[String[]]
		$ArgumentList
	)
  	Begin {
  		$OFS = " "
	}
	
	Process {
  		$process = New-Object System.Diagnostics.Process
  		$process.StartInfo.FileName = $FilePath
  		$process.StartInfo.Arguments = $ArgumentList
  		$process.StartInfo.UseShellExecute = $false
  		$process.StartInfo.RedirectStandardOutput = $true
  		if ( $process.Start() ) {
    		$output = $process.StandardOutput.ReadToEnd() -replace "\r\n$",""
    		if ( $output ) {
      			if ( $output.Contains("`r`n") ) {
        			$output -split "`r`n"
      			}
      			elseif ( $output.Contains("`n") ) {
        			$output -split "`n"
      			}
      			else {
        			$output
      			}
			}
    		$process.WaitForExit()
    			& "$Env:SystemRoot\system32\cmd.exe" `
      			/c exit $process.ExitCode
		}
	}
}

Function Build-CRCLog {
# 
# Creates a log containing the CRC values of each file to be synced to a remote computer
#
	param (
		[System.String]$Logfile,
		[System.String]$Path
	)

	begin {
		$Change = $False
		if(Test-Path $Path) { 							
			$filecount = @( Get-ChildItem $Path ).Count
			if($filecount -gt 0) {
				$files = Get-ChildItem $Path
				$CRCArr = @()
				# Collect CRC32 values for all files with their filenames
				foreach($file in $files) {
                    $CRCArr += $file.Name
					$CRCArr += Get-Crc32 $file.FullName
				}

				# Check if the previous log holds the same CRC32 values
				if(Test-Path $logfile) {
					$TempLog = "$logfile.tmp"
					$CRCArr | Out-File $Templog -Force -ErrorAction SilentlyContinue

					# Retrieve CR32 from both log files 
					$CRCPrevlog = Get-Crc32 $logfile
					$CRCTmpLog = Get-Crc32 $Templog

					# Compare values to see if changes have been made
					$Change = ($CRCPrevlog -ne $CRCTmpLog)										
				} else {
					# If there is no log file, signal that changes have been made by default					
					$Change = $True
				}

				# Save the CRC32 values to the default log
				$CRCArr | Out-File $logfile -Force -ErrorAction SilentlyContinue
			} 
		}
		return $Change
	}
}

# ---------------------------------------------------------
Clear-Host

$SourceRoot = '\\nedcar.nl\Office\PRES_OFF\Display_Koffieautomaten'
$LogPath = '\\s008.nedcar.nl\D$\Display_Koffieautomaten\Logs'
$ErrorLogPath = "$LogPath\SyncError.log"
$SyncLog = "$LogPath\DisplayPC_Synchronisation.log"

# Remove error log if normal log was created.
if(Test-Path $ErrorLogPath) { Remove-Item $ErrorLogPath -Force -ErrorAction SilentlyContinue }

# Initialise log file
[void](Init-Log -LogFileName $SyncLog $False -alternate_location $True)

#
# Record start of script.
$BaseStart = Get-Date
Echo-Log ("="*80)
Echo-Log "Start synchronsation run."
Echo-Log ("="*80)

# Stats
$CompSynced = 0
$CompConnErr = 0

#
# Search Active Directory for computers
Echo-Log "Collecting computers from $ADOU_DisplayPC"
$ADSearchFilter = '(objectCategory=Computer)'
$DSComputers = Collect-AD-Computers -ADSearchFilter $ADSearchFilter -OUPath $GLobal:ADOU_DisplayPC

#
# Select a single computer for testing purposes. 
if ( $Global:DEBUG ) { 
    $DSComputers = $DSComputers |  where { $_.properties.name -eq 'VDLNC01448' } 
}

if($DSComputers -eq $null) { 
	Echo-Log "ERROR: No computers collected from $ADOU_DisplayPC"
} else {
	Echo-Log "Number of computer objects found: $($DSComputers.Count)"	
	$cnt = 0
	foreach ($objComputer in $DSComputers) {
		$cnt++
    	$objItem = $objComputer.Properties
		$dnshostname = [System.String]$objItem.dnshostname
		$dspath = [System.String]$objItem.distinguishedname		
		
		if($dnshostname.Length -gt 0) {
            Echo-Log ('-'*80)
			Echo-Log "[$dnshostname] Computer [$cnt] object: $dspath"
			Echo-Log "[$dnshostname] Computer object DNS name: $dnshostname"
			$ComputerStart = Get-Date
		
			# Reset status
			$syncresulttext = $null
			$syncresult = 0
			
			$DestinationPath = "\\$dnshostname\c$\wamp\www\images"
			
            # Default contents is set to NULL
            $SourceFolder = $null
			
			# Check path for specifics
			if($dspath.contains('OU=Bodyshop')) { 
				$SourceFolder = $SourceRoot + '\Bodyshop'
				$CRCLog = "$LogPath\crc\Bodyshop.$dnshostname.CRC"
			}
			if($dspath.contains('OU=FA')) { 
				$SourceFolder = $SourceRoot + '\FA' 
				$CRCLog = "$LogPath\crc\FA.$dnshostname.CRC"
			}
			if($dspath.contains('OU=Kantoor')) { 
				$SourceFolder = $SourceRoot + '\Kantoor' 
				$CRCLog = "$LogPath\crc\Kantoor.$dnshostname.CRC"
			}			
			if($dspath.contains('OU=Lakstraat')) { 
				$SourceFolder = $SourceRoot + '\Lakstraat' 
				$CRCLog = "$LogPath\crc\Lakstraat.$dnshostname.CRC"
			}
			if($dspath.contains('OU=Pershal')) { 
				$SourceFolder = $SourceRoot + '\Pershal' 
				$CRCLog = "$LogPath\crc\Pershal.$dnshostname.CRC"
			}
			
			# Test displays get their content from Kantoor.
			if($dspath.contains('OU=Test')) { 
				$SourceFolder = $SourceRoot + '\Kantoor' 
				$CRCLog = "$LogPath\crc\Kantoor.$dnshostname.CRC"
			}
			
            # If the computer is not located in a specific OU, the source folder is set to NULL and this computer is ignored.
			if($SourceFolder -ne $null) {
			
				Echo-Log "[$dnshostname] Source for this computer : $SourceFolder"
				if(Test-Path $SourceFolder) { 							
				
                    # Check for empty folder
                    $filecount = @( Get-ChildItem $SourceFolder ).Count
                    if($filecount -gt 0) {
					
                        Echo-log "[$dnshostname] Source file holds $filecount files to sync."

						# Check if changes must be applied. Check CRC32 for each file and compare to local CRC log.
						$SourceIsChanged = Build-CRCLog -Logfile $CRCLog -Path $SourceFolder												
						if($SourceIsChanged) {
							Echo-Log "[$dnshostname] Changes in the source folder are detected."	
							
                        	# Check if computer is available, first retrieve the IP address
                        	# Resolve DNS to IP address
                        	$IPAddress = [string]((Resolve-DnsName $dnshostname).IPAddress)                        
                        
                        	# Now do a reverse DNS lookup.
                        	try {
                            	$ReverseDNS = ''
                            	$ReverseDNS = [System.Net.Dns]::GetHostByAddress($IPAddress) 
                        	}
                        	catch{}                       
                        	Echo-Log "[$dnshostname] IP address: '$IPAddress' resolves to '$($ReverseDNS.HostName)'"

                        	# Check if reverse DNS results in the same computer host name.
                        	# If the host is switched off, it's reverse DNS registration could be taken by another computer.
                        	if($ReverseDNS.HostName -ne $dnshostname) {                                                        
                            	$syncresult = -1
                            	$CompConnErr++
                            	$syncresulttext = "ERROR: [$dnshostname] A reverse DNS lookup failure occured. The IP address does not belong to this computer."
				            	Echo-Log $syncresulttext
                        	} else {                        

                            	# Can we connect to the remote computer?
                            	$Connected = Test-Connection $dnshostname -ErrorAction SilentlyContinue
                            	if($Connected) {                        						    
                                	Echo-Log "[$dnshostname] Connected."

									$DestinationPath = "\\$dnshostname\c$\wamp\www\images"
									$SourceCRC32 = Get-Crc32 $CRCLog
								
									Echo-Log "[$dnshostname] Changes are synchronised to the remote computer."										

									#
									# Update the image files
									#
									$DestinationPath = "\\$dnshostname\c$\wamp\www\images"									
									if(Test-Path $DestinationPath) {
										$RCResult = ""
		    							$RCResult = Start-Executable -FilePath 'robocopy' -ArgumentList "$SourceFolder $DestinationPath /mir /np /R:1 /W:2 /TEE"
										foreach($line in $RCResult) { Echo-Log $line }
										# Add counter for successfull synced computers                           
										$CompSynced++
									} else {
										$syncresult = -1                                
					    				$syncresulttext = "ERROR: [$dnshostname] The computer is pingable but the destination path cannot be found!"		
				    					Echo-Log $syncresulttext
									}                           									
								} else {
						        	$syncresult = -1
                                	$CompConnErr++
						        	$syncresulttext = "ERROR: [$dnshostname] Cannot connect to $dnshostname. IP address: $IPAddress"		
						        	Echo-Log $syncresulttext
					        	}
                        	}
						} else {
							$syncresult = 0
							Echo-Log "[$dnshostname] There are no changes in the source folder."		
						}
                    } else {
                       	$syncresult = -1
                       	$syncresulttext = "ERROR: [$dnshostname] Source folder is empty (no files). Synchronize is not executed."			
				       	Echo-Log $syncresulttext
                    }
									
				} else {
					$syncresult = -1
					$syncresulttext = "ERROR: [$dnshostname] The source folder $SourceFolder cannot be found."
					Echo-Log $syncresulttext
				}
			} else {				
				$syncresulttext = "WARNING: [$dnshostname] Is this display PC correctly placed in AD? The resulting source folder pathname is empty."
				Echo-Log $syncresulttext				
			}				
				
			$SyncTimePerComputer = New-TimeSpan -Start ($ComputerStart) -End (Get-Date)
			Echo-Log "[$dnshostname] Computer synchronisation time : $SyncTimePerComputer"
				
			#
			# Add errors to error log file
			if($syncresult -ne 0) {                 
				$syncresulttext | Out-File -FilePath $ErrorLogPath -Append -NoClobber -Force -ErrorAction SilentlyContinue	
			}		
		}
	}
}

$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log ("="*80)
Echo-Log "Computers synchronised: $CompSynced"
if($CompSynced -ne 0) {
	Echo-Log "Computers with connection errors: $CompConnErr"
}
Echo-Log "Total Display PC synchronisation running time : $min"
Echo-Log ("="*80)

if ($CompSynced -gt 0) {
	$Title = "Koffie automaten display computers zijn gesynchroniseerd."
	$SendTo = "m.jussen@vdlnedcar.nl"
	$dnsdomain = 'vdlnedcar.nl'
	$computername = gc env:computername
	$SendFrom = "$computername@$dnsdomain"
	# Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $SyncLog -Headline $Title	
}

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================