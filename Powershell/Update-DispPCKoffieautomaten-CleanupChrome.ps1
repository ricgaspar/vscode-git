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

$Global:DEBUG = $True

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
$SyncLog = "$LogPath\DisplayPC_CleanupChrome.log"
# Remove error log if normal log was created.
$ErrorLogPath = "$LogPath\SyncError_CleanupChrome.log"
if (Test-Path $ErrorLogPath) { Remove-Item $ErrorLogPath -Force -ErrorAction SilentlyContinue }
[void](Init-Log -LogFileName $SyncLog $False -alternate_location $True)

#
# Record start of script.
$BaseStart = Get-Date
Write-Output ("=" * 80)
Write-Output "Start synchronsation run."
Write-Output ("=" * 80)

#
# Search Active Directory for computers
Write-Output "Collecting computers from $ADOU_DisplayPC"
$ADOU_DisplayPC = 'LDAP://OU=DisplayPC_KoffieAutomaat,OU=IT,OU=Factory,DC=nedcar,DC=nl'

# Or select a test computers for testing purposes.
if ( $Global:DEBUG ) {
    $ADOU_DisplayPC = 'LDAP://OU=Bodyshop,OU=DisplayPC_KoffieAutomaat,OU=IT,OU=Factory,DC=nedcar,DC=nl'
}
$DSComputers = Get-DisplayComputers -OUPath $ADOU_DisplayPC

if ($DSComputers -eq $null) {
    Write-Output "ERROR: No computers collected from $ADOU_DisplayPC"
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
        $JobHeader = "CleanupChrome_"
        $JobName = $JobHeader + $CompName

        $CurrTime = Get-Date
        $JobTimer.add("$CompName", $CurrTime)
        $startedcount++

        $LogText = "($startedcount) Trying to start job for $CompName"
        Write-Output $LogText

        # Start job
        Start-Job -Name $JobName -ArgumentList $CompName, $dspath -ScriptBlock {
            # This is the script block actually executed for each computer
            $Error.Clear()
            $CompName = $args[0]
            $strOutput = "[$CompName] Job script block started.`n"

            # Check if computer is available, first retrieve the IP address
            # Resolve DNS to IP address
            $IPAddress = [string]((Resolve-DnsName $CompName).IPAddress)

            # Now do a reverse DNS lookup.
            try {
                $ReverseDNS = ''
                $ReverseDNS = [System.Net.Dns]::GetHostByAddress($IPAddress)
            }
            catch {}
            Write-Output "[$CompName] IP address: '$IPAddress' resolves to '$($ReverseDNS.HostName)'`n"

            # Check if reverse DNS results in the same computer host name.
            # If the host is switched off, it's reverse DNS registration could be taken by another computer.
            if ($ReverseDNS.HostName -ne $CompName) {
                $CompConnErr++
                $syncresulttext = "ERROR: [$CompName] A reverse DNS lookup failure occured. The IP address does not belong to this computer.`n"
                $strOutput += $syncresulttext
            }
            else {

                # Can we connect to the remote computer?
                $Connected = Test-Connection $CompName -ErrorAction SilentlyContinue
                if ($Connected) {
                    Write-Output "[$CompName] Connected."

                    $DestinationPath = "\\$CompName\C$\Users\InfoKiosk\AppData\Local\Google\Chrome\User Data"
                    $FilesTMP = Get-Childitem $DestinationPath -Recurse | Where-object {$_.extension -eq ".tmp"}
                    $FilesTMP | Remove-Item -Recurse -Force

                }
                else {
                    $syncresulttext = "ERROR: [$CompName] The computer is pingable but the destination path cannot be found!`n"
                    $strOutput += $syncresulttext
                }
            }

            # Return text output
            Write-Output $strOutput
        } | Out-Null

        # Check on running jobs
        Receive-Job -Name "$JobHeader*" | ForEach-Object {
            $count++
            $Output = $_
            foreach ($strOutput in $Output) {
                Write-Output $strOutput
            }
        }

        # Check if number of running jobs does not exceed 20
        do {
            Write-Output "Check running jobs status."
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
                Write-Output "Waiting for jobs to complete..."
                Start-Sleep 1
            }
        } while ($RunningJobs -gt 20)
    }

    # Check for jobs to complete
    do {
        Write-Output "Check job completion."
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
            Write-Output "Waiting for jobs to complete..."
            Start-Sleep 1
        }
    } while ($RunningJobs -gt 0)

    # Check output of all jobs completed.
    Receive-Job -Name "$JobHeader*" | ForEach-Object {
        $Output = $_
        foreach ($strOutput in $Output) {
            Write-Output $strOutput
        }
    }

    Write-Output "Removing jobs."
    Remove-Job -Name "$JobHeader*" | ForEach-Object {
    }
}

$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Write-Output ("Run time: $min)")
Write-Output ("=" * 80)

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================