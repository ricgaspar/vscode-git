# ------------------------------------------------------------------------------
<#
.SYNOPSIS


.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	11-09-2017

.CHANGE_DATE
	11-09-2017

.DESCRIPTION


#>
# ------------------------------------------------------------------------------
#-requires 5.0

# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

$Global:DEBUG = $false
Function Get-RemoteComputersFromAD {
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
$LogPath = 'C:\Logboek\RUN-UpdateBIOSRemotely.log'
[void](Init-Log -LogFileName $LogPath $False -alternate_location $True)

# Record start of script.
$BaseStart = Get-Date
Echo-Log ("=" * 80)
Echo-Log "Start CRC maintenance run."
Echo-Log ("=" * 80)

#
# Search Active Directory for computers
$ADOU = 'LDAP://OU=FACTORY,DC=nedcar,DC=nl'
Echo-Log "Collecting computers from $ADOU"
$DSComputers = Get-RemoteComputersFromAD -OUPath $ADOU | Where-Object { $_.properties.dnshostname -eq 'vdlnc00429.nedcar.nl'}

# $ADOU = 'LDAP://DC=nedcar,DC=nl'
# Echo-Log "Collecting computers from $ADOU"
# $DSComputers = Get-RemoteComputersFromAD -OUPath $ADOU | Where-Object { $_.properties.dnshostname -eq 'vdlnc02583.nedcar.nl'}

if ($DSComputers -eq $null) {
    Echo-Log "ERROR: No computers collected."
}
else {
    $JobTimer = @{}

    $count = 0
    $startedcount = 0
    $DSComputers | ForEach-Object {
        $CompName = [System.String]$_.properties.dnshostname

        # Format the job name per computer
        $JobHeader = "CancelShutDownRestart_"
        $JobName = $JobHeader + $CompName

        $CurrTime = Get-Date
        $JobTimer.add("$CompName", $CurrTime)
        $startedcount++

        $LogText = "($startedcount) Trying to start job for $CompName"
        Echo-Log $LogText

        # Start job
        Start-Job -Name $JobName -ArgumentList $CompName -ScriptBlock {
            # This is the script block actually executed for each computer
            $Error.Clear()
            $CompName = $args[0]

            Copy-Item -Path 'C:\VSCode\vscode-git\Dell\CCTK.3.2' -Destination "\\$CompName\C$\ProgramData\VDL Nedcar" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            Invoke-Command -ComputerName $CompName -FilePath "C:\VSCode\vscode-git\Powershell\Dell hardware\Bios configuration\Set-WakeOnLanByCCTK.ps1"

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