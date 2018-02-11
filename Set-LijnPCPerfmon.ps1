# ---------------------------------------------------------
<#
.SYNOPSIS
    Creates a repository for the
    Nedcar Standard Server environment on remote computers
    - Creates C:\ProgramData\VDL Nedcar\NCSTD
    - Creates scheduled task to install/update NCSTD

.REQUIRES
    Access to \\S031\NCSTD$ for domain computers

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	27-09-2017

.CHANGE_DATE
	27-09-2017
#>
# ---------------------------------------------------------
#-requires 3.0
Import-Module VNB_PSLib -Force

$Global:DEBUG = $false

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
    Import-DscResource -ModuleName 'Logman'

    Node $Computername
    {
        Logman LijnPCPerfmonLogman {
            DataCollectorSetName = 'LijnPC'
            Ensure = 'Present'
            XmlTemplatePath = $SourcePath + '\LijnPC.xml'                         
        }

        Script LijnPCPerfmonSchedTask {
            GetScript = {
                Return @{
                    Result = [string]'VDL Nedcar'
                }
            }
            SetScript  = {
                $TaskName = 'LijnPC after reboot'
                $TaskDescr = 'Datacollector set LijnPC'
                $TaskCommand = 'C:\WINDOWS\system32\rundll32.exe'
                $TaskArg = 'C:\WINDOWS\system32\pla.dll,PlaHost "LijnPC" "$(Arg0)"'
                $TaskStartTime = [datetime]::Now.AddMinutes(5).ToString('s')

                $ScheduleObject = new-object -ComObject Schedule.Service
                $ScheduleObject.Connect()

                $TaskDefinition = $ScheduleObject.NewTask(0)
                $TaskDefinition.RegistrationInfo.Description = $TaskDescr
                $TaskDefinition.RegistrationInfo.Author = 'SYSTEM'
                $TaskDefinition.Settings.Enabled = $true
                $TaskDefinition.Settings.AllowDemandStart = $true
                $TaskDefinition.Settings.DisallowStartIfOnBatteries = $false
                $TaskDefinition.Settings.ExecutionTimeLimit = 'PT0S'

                $triggers = $TaskDefinition.Triggers
                $trigger = $triggers.Create(8) # Creates a "At System Startup" trigger
                $trigger.StartBoundary = $TaskStartTime
                $trigger.Enabled = $true
                $trigger.Delay = 'PT5M'

                $action = $TaskDefinition.Actions.Create(0)
                $action.Path = $TaskCommand
                $action.Arguments = $TaskArg

                $rootFolder = $ScheduleObject.GetFolder('\Microsoft\Windows\PLA')
                $UserAcct = 'SYSTEM'
                $UserPass = $null
                $newTask = $rootFolder.RegisterTaskDefinition($TaskName, $TaskDefinition, 6, $UserAcct, $UserPass,1)
                $newTask
            }
            TestScript = {
                $scheduleObject = New-Object -ComObject schedule.service
                $scheduleObject.connect()
                $folder = $scheduleObject.GetFolder('\Microsoft\Windows\PLA')
                $task = [bool]($folder.GetTasks(1) | Where-Object { $_.Name -eq 'LijnPC after reboot' } | Select-Object Name)
                $task
            }
            DependsOn  = "[Logman]LijnPCPerfmonLogman"
        }

    }
}

$ScriptRoot = Split-Path -Parent $PSCommandPath

# ---------------------------------------------------------

$DSComputers = New-Object System.Collections.ArrayList
$item = New-Object System.Object
$item | Add-Member -MemberType NoteProperty -Name "hostname" -Value $env:Computername
$item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value $env:Computername
$DSComputers.Add($item) | Out-Null

if ($DSComputers -eq $null) {
    Write-Error "ERROR: No computers to process."
}
else {

    $DSComputers | ForEach-Object {
        $CompName = [System.String]$_.hostname
        Write-Output "Compile DSC mof for computer: $CompName"

        Set-Location -Path $ScriptRoot
        LIJNPCPERFMON -Computername $CompName -SourcePath $ScriptRoot

        Start-DscConfiguration .\LIJNPCPERFMON -Verbose -Force -Wait
    }
}