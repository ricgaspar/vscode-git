# ---------------------------------------------------------
<#
.SYNOPSIS

.REQUIRES

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	06-10-2017

.CHANGE_DATE
	06-10-2017
#>
# ---------------------------------------------------------
#
# Can only be deployed on Powershell v5+ machines!!!
#

# ---------------------------------------------------------
Configuration LIJNPCPERFMON
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SourcePath
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DSCResource -ModuleName 'xComputerManagement'
    Import-DscResource -ModuleName 'Logman'

    Node $Computername
    {
        # Install Performance data collector set LijnPC.xml with LogMan
        Logman LijnPCPerfmonLogman {
            DataCollectorSetName = 'LijnPC'
            Ensure               = 'Present'
            XmlTemplatePath      = $SourcePath + '\LijnPC.xml'
        }

        # Add additional scheduled task that restarts the collector after a reboot.
        xScheduledTask xScheduledTaskOnceAdd {
            TaskName          = 'LijnPC after Reboot'
            TaskPath          = '\Microsoft\Windows\PLA'
            ActionExecutable  = 'C:\WINDOWS\system32\schtasks.exe'
            ActionArguments   = '/Run /TN "\Microsoft\Windows\PLA\LijnPC"'
            ScheduleType      = 'AtStartup'
            ActionWorkingPath = (Get-Location).Path
            Enable            = $true
            Priority          = 9
            DependsOn         = '[Logman]LijnPCPerfmonLogman'
        }

    }
}

$ScriptRoot = Split-Path -Parent $PSCommandPath
Set-Location -Path $ScriptRoot

# ---------------------------------------------------------

$Computername = 'VDLNC01800'

$DSComputers = New-Object System.Collections.ArrayList
$item = New-Object System.Object
$item | Add-Member -MemberType NoteProperty -Name "hostname" -Value $Computername
$item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value $Computername
$DSComputers.Add($item) | Out-Null

if ($DSComputers -eq $null) {
    Write-Error "ERROR: No computers to process."
}
else {
    # Use XML file at this location for import bij LogMan
    $SourcePath = '\\s031.nedcar.nl\ncstd$\PROGRAMDATA\VDL Nedcar\Perfmon'

    $DSComputers | ForEach-Object {
        $CompName = [System.String]$_.hostname
        Write-Output "Compile DSC mof for computer: $CompName"

        LIJNPCPERFMON -Computername $CompName -SourcePath $SourcePath

        # Start-DscConfiguration .\LIJNPCPERFMON -Verbose -Force -Wait
    }
}