# ------------------------------------------------------------------------------
<#
.SYNOPSIS
    Remove CRC log files from display computers that cannot be connected to.

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	11-09-2017

.CHANGE_DATE
	11-09-2017
 
.DESCRIPTION
    Remove CRC log files from display computers that cannot be connected to.
	
#>
# ------------------------------------------------------------------------------
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

$Global:DEBUG = $false

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

#
# Set global variables
if ( $Global:DEBUG ) { 
    # TEST Values
    $SourceRoot = '\\S008\d$\Display_Koffieautomaten\Test'	    
}
else {
    # Production values
    $SourceRoot = '\\nedcar.nl\Office\PRES_OFF\Display_Koffieautomaten'		
}

# Initialise log file
$LogPath = '\\s008.nedcar.nl\D$\Display_Koffieautomaten\Logs'
$SyncLog = "$LogPath\DisplayPC_CRC_Maintenance_v2.log"
[void](Init-Log -LogFileName $SyncLog $False -alternate_location $True)

#
# Record start of script.
$BaseStart = Get-Date
Echo-Log ("=" * 80)
Echo-Log "Start CRC maintenance run."
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
        $JobHeader = "CancelShutDownRestart_"
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
            # Check path for specifics
            if ($dspath.contains('OU=Bodyshop')) { $CRCLog = "$LogPath\crc\Bodyshop.$dnshostname.CRC" }
            if ($dspath.contains('OU=FA')) { $CRCLog = "$LogPath\crc\FA.$dnshostname.CRC" }
            if ($dspath.contains('OU=Kantoor')) { $CRCLog = "$LogPath\crc\Kantoor.$dnshostname.CRC" }
            if ($dspath.contains('OU=Lakstraat')) { $CRCLog = "$LogPath\crc\Lakstraat.$dnshostname.CRC" }
            if ($dspath.contains('OU=Pershal')) { $CRCLog = "$LogPath\crc\Pershal.$dnshostname.CRC" }    
            # Test displays get their content from Kantoor.
            if ($dspath.contains('OU=Test')) { $CRCLog = "$LogPath\crc\Kantoor.$dnshostname.CRC" }
                             
            # Resolve DNS to IP address
            $IPAddress = [string]((Resolve-DnsName $CompName).IPAddress) 
            $strOutput += "[$CompName] DNS registered IP address: '$IPAddress'`n"
            $ReverseDNS = ''
            # Now do a reverse DNS lookup.
            try {                    
                $ReverseDNS = [System.Net.Dns]::GetHostByAddress($IPAddress) 
            }
            catch {
                $strOutput += "[$CompName] Reverse DNS resolve of IP address '$IPAddress' ended in error.`n"
            }
            $strOutput += "[$CompName] IP address: '$IPAddress' resolves to '$($ReverseDNS.HostName)'`n"

            # Check if reverse DNS results in the same computer host name.
            # If the host is switched off, it's reverse DNS registration could be taken by another computer.
            if ($ReverseDNS.HostName -ne $CompName) {                                                                           	
                $strOutput += "ERROR: [$CompName] A reverse DNS lookup failure occured. The IP address does not belong to this computer.`n"
            }
            else { 
                $strOutput += "[$CompName] Test if computer '$CompName' can be connected to.`n"
                # Can we connect to the remote computer?
                $Connected = Test-Connection $CompName -ErrorAction SilentlyContinue
                if ($Connected) {                        						    
                    $strOutput += "[$CompName] Successfully made a connection to '$CompName'.`n"
                }
                else {
                    $strOutput += "ERROR: [$CompName] Cannot connect to $CompName. IP address: $IPAddress`n"
                    if (Test-Path $CRCLog) { Remove-Item $CRCLog -Force -ErrorAction SilentlyContinue }
                    $CRCLogTemp = "$CRCLog.tmp"
                    if (Test-Path $CRCLogTemp) { Remove-Item $CRCLogTemp -Force -ErrorAction SilentlyContinue }
                }
            }
            $ExitCode = $LastExitCode            
            $strOutput += "`n$CompName job return code: $ExitCode`n"            
            
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
            echo-log $strOutput
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