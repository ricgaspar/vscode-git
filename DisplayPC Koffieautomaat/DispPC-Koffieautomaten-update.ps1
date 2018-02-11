# ------------------------------------------------------------------------------
<#
.SYNOPSIS
    Update JPG to display computers that can be connected to.

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	11-09-2017

.CHANGE_DATE
	11-09-2017
 
.DESCRIPTION
    Update JPG to display computers that can be connected to.
	
#>
# ------------------------------------------------------------------------------
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

$Global:DEBUG = $False

Function Get-DisplayComputers {
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

# ---------------------------------------------------------
Clear-Host

# Initialise log file
$LogPath = '\\s008.nedcar.nl\D$\Display_Koffieautomaten\Logs'
$SyncLog = "$LogPath\DisplayPC_Synchronisation_v2.log"
# Remove error log if normal log was created.
$ErrorLogPath = "$LogPath\SyncError_v2.log"
if (Test-Path $ErrorLogPath) { Remove-Item $ErrorLogPath -Force -ErrorAction SilentlyContinue }
[void](Init-Log -LogFileName $SyncLog $False -alternate_location $True)

#
# Record start of script.
$BaseStart = Get-Date
Echo-Log ("=" * 80)
Echo-Log "Start synchronsation run."
Echo-Log ("=" * 80)

#
# Search Active Directory for computers
Echo-Log "Collecting computers from $ADOU_DisplayPC"
$ADOU_DisplayPC = 'LDAP://OU=DisplayPC_KoffieAutomaat,OU=IT,OU=Factory,DC=nedcar,DC=nl'	

# Or select a test computers for testing purposes. 
if ( $Global:DEBUG ) { 
    $ADOU_DisplayPC = 'LDAP://OU=Test,OU=DisplayPC_KoffieAutomaat,OU=IT,OU=Factory,DC=nedcar,DC=nl'
}
$DSComputers = Get-DisplayComputers -OUPath $ADOU_DisplayPC    

if ($DSComputers -eq $null) { 
    Echo-Log "ERROR: No computers collected from $ADOU_DisplayPC"
} 
else {
    $JobTimer = @{}
   
    $count = 0
    $startedcount = 0
    $DSComputers | ForEach-Object {         
        $dnshostname = [System.String]$_.properties.dnshostname
        $dspath = [System.String]$_.properties.distinguishedname	  
        $CompName = $dnshostname
        
        # Format the job name per computer
        $JobHeader = "UpdateKoffieJPGImages_"
        $JobName = $JobHeader + $CompName

        $CurrTime = Get-Date
        $JobTimer.add("$CompName", $CurrTime)        
        $startedcount++

        $LogText = "($startedcount) Trying to start job for $CompName"
        Echo-Log $LogText

        # Start job
        Start-Job -Name $JobName -ArgumentList $CompName, $dspath -ScriptBlock {
            # This is the script block actually executed for each computer
            $Error.Clear()
            $CompName = $args[0]
            $DSPath = $args[1]

            $strOutput = "[$CompName] Job script block started.`n"
            $DestinationPath = "\\$CompName\c$\wamp\www\images"
            $SourceRoot = '\\nedcar.nl\Office\PRES_OFF\Display_Koffieautomaten'

            # Check path for specifics
            if ($dspath.contains('OU=Bodyshop')) { $SourceFolder = $SourceRoot + '\Bodyshop' }
            if ($dspath.contains('OU=FA')) { $SourceFolder = $SourceRoot + '\FA' }
            if ($dspath.contains('OU=Kantoor')) { $SourceFolder = $SourceRoot + '\Kantoor' }			
            if ($dspath.contains('OU=Lakstraat')) { $SourceFolder = $SourceRoot + '\Lakstraat' }
            if ($dspath.contains('OU=Pershal')) { $SourceFolder = $SourceRoot + '\Pershal' }			            
            if ($dspath.contains('OU=Test')) { $SourceFolder = $SourceRoot + '\Kantoor' }
            
            # If the computer is not located in a specific OU, the source folder is set to NULL and this computer is ignored.
            if ($SourceFolder -ne $null) {
                $strOutput += "[$CompName] Source for this computer : $SourceFolder`n"
                if (Test-Path $SourceFolder) {                
                    # Check for empty folder
                    $filecount = @( Get-ChildItem $SourceFolder ).Count
                    if ($filecount -gt 0) {
                        $strOutput += "[$CompName] Source file holds $filecount files to sync.`n"

                        # Check if computer is available, first retrieve the IP address
                        # Resolve DNS to IP address
                        $IPAddress = [string]((Resolve-DnsName $CompName).IPAddress)                        
                        
                        # Now do a reverse DNS lookup.
                        try {
                            $ReverseDNS = ''
                            $ReverseDNS = [System.Net.Dns]::GetHostByAddress($IPAddress) 
                        }
                        catch {}                       
                        Echo-Log "[$CompName] IP address: '$IPAddress' resolves to '$($ReverseDNS.HostName)'`n"

                        # Check if reverse DNS results in the same computer host name.
                        # If the host is switched off, it's reverse DNS registration could be taken by another computer.
                        if ($ReverseDNS.HostName -ne $CompName) {                                                        
                            $syncresult = -1
                            $CompConnErr++
                            $syncresulttext = "ERROR: [$CompName] A reverse DNS lookup failure occured. The IP address does not belong to this computer.`n"
                            $strOutput += $syncresulttext
                        }
                        else {                        

                            # Can we connect to the remote computer?
                            $Connected = Test-Connection $CompName -ErrorAction SilentlyContinue
                            if ($Connected) {                        						    
                                Echo-Log "[$CompName] Connected."
                                $DestinationPath = "\\$CompName\c$\wamp\www\images"								
                                $strOutput += "[$CompName] Changes are synchronised to the remote computer.`n"										

                                #
                                # Update the image files
                                #
                                $DestinationPath = "\\$CompName\c$\wamp\www\images"									
                                if (Test-Path $DestinationPath) {
                                    $RCResult = ""
                                    $RCResult = Start-Executable -FilePath 'robocopy' -ArgumentList "$SourceFolder $DestinationPath /mir /np /R:1 /W:2 /TEE"
                                    foreach ($line in $RCResult) {$strOutput += "[$CompName] $line `n"}
                                    # Add counter for successfull synced computers                           
                                    $CompSynced++
                                }
                                else {
                                    $syncresult = -1                                
                                    $syncresulttext = "ERROR: [$CompName] The computer is pingable but the destination path cannot be found!`n"		
                                    $strOutput += $syncresulttext
                                }                           									
                            }
                            else {
                                $syncresult = -1
                                $CompConnErr++
                                $syncresulttext = "ERROR: [$CompName] Cannot connect to $CompName. IP address: $IPAddress`n"		
                                $strOutput += $syncresulttext
                            }
                        }
						
                    }
                    else {
                       	$syncresult = -1
                       	$syncresulttext = "ERROR: [$CompName] Source folder is empty (no files). Synchronize is not executed.`n"			
                        $strOutput += $syncresulttext
                    }
									
                }
                else {
                    $syncresult = -1
                    $syncresulttext = "ERROR: [$CompName] The source folder $SourceFolder cannot be found.`n"
                    $strOutput += $syncresulttext
                }
            }
            else {				
                $syncresulttext = "WARNING: [$CompName] Is this display PC correctly placed in AD? The resulting source folder pathname is empty.`n"
                $strOutput += $syncresulttext				
            }
            
            # Return text output
            Write-Output $strOutput
        } | Out-Null
    
        # Check on running jobs
        Receive-Job -Name "$JobHeader*" | ForEach-Object {
            $count++
            $Output = $_
            foreach ($strOutput in $Output) {
                Echo-Log $strOutput            
            }
        }

        # Check if number of running jobs does not exceed 20
        do {
            Echo-Log "Check running jobs status."
            $RunningJobs = 0
            $IgnoredJobs = 0
            Get-Job | where-object {$_.Name -like "$JobHeader*" -and $_.State -eq "Running"} | ForEach-Object {
                $JobID = $_.ID
                if ($SkippedJobs -inotcontains "$JobID") {
                    $RunningJobs++
                    $CurrTime = Get-Date                    
                    $JobCompName = $_.Name
                    $JobCompName = $JobCompName.replace($JobHeader, "")
                    $StartTime = $JobTimer["$JobCompName"]
                    $CompareTime = $CurrTime - $StartTime
                    if ($CompareTime.Minutes -gt 2 -and $IgnoredJobs -eq 0) {
                        $SkippedJobs += @("$JobID")
                        $IgnoredJobs++
                        $NumUnsuccess++
                    }
                }
            }
            # Wait for any jobs to complete
            if ($RunningJobs -gt 20) {
                Echo-Log "Waiting for jobs to complete..."                
                Start-Sleep 1            
            }
        } while ($RunningJobs -gt 20)
    }

    # Check for jobs to complete
    do {
        Echo-Log "Check job completion."
        $RunningJobs = 0
        $IgnoredJobs = 0
        get-job | where-object {$_.Name -like "$JobHeader*" -and $_.State -eq "Running"} | ForEach-Object {
            $JobID = $_.ID
            if ($SkippedJobs -inotcontains "$JobID") {
                $RunningJobs++
                $CurrTime = Get-Date                
                $JobCompName = $_.Name
                $JobCompName = $JobCompName.replace($JobHeader, "")
                $StartTime = $JobTimer["$JobCompName"]
                $CompareTime = $CurrTime - $StartTime
                if ($CompareTime.Minutes -gt 2 -and $IgnoredJobs -eq 0) {
                    $SkippedJobs += @($_.ID)
                    $IgnoredJobs++
                    $NumUnsuccess++
                }
            }
        }
        if ($RunningJobs -gt 0) {
            Echo-Log "Waiting for jobs to complete..."
            Start-Sleep 1            
        }
    } while ($RunningJobs -gt 0)
 
    # Check output of all jobs completed.
    Receive-Job -Name "$JobHeader*" | ForEach-Object {    
        $Output = $_
        foreach ($strOutput in $Output) {
            Echo-Log $strOutput
        }
    }

    Echo-Log "Removing jobs."
    Remove-Job -Name "$JobHeader*" | ForEach-Object {
    }
}

$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log ("Run time: $min)")
Echo-Log ("=" * 80)

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================