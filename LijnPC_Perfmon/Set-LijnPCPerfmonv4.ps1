# ---------------------------------------------------------
<#
.SYNOPSIS

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
#
# Can only be deployed on Powershell v4 machines!!!
#


# ---------------------------------------------------------
Configuration LIJNPCPERFMONv4
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

    Node $Computername
    {
        Script LijnPCLogMan {
            GetScript  = {
                Return @{
                    Result = [string]'VDL Nedcar'
                }
            }
            SetScript  = {
                Write-host "Dummy"
            }
            TestScript = {
                return $true
            }
        }

        # Add additional scheduled task that restarts the collector after a reboot.
        Script LijnPCPerfmonSchedTask {
            GetScript  = {
                Return @{
                    Result = [string]'VDL Nedcar'
                }
            }
            SetScript  = {
                $TaskName = 'LijnPC after reboot'
                $TaskDescr = 'Datacollector set LijnPC'
                $TaskCommand = 'C:\WINDOWS\system32\schtasks.exe'
                $TaskArg = '/Run /TN "\Microsoft\Windows\PLA\LijnPC"'
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
                # $trigger.Delay = 'PT5M'

                $action = $TaskDefinition.Actions.Create(0)
                $action.Path = $TaskCommand
                $action.Arguments = $TaskArg

                $rootFolder = $ScheduleObject.GetFolder('\Microsoft\Windows\PLA')
                $UserAcct = 'SYSTEM'
                $UserPass = $null
                $newTask = $rootFolder.RegisterTaskDefinition($TaskName, $TaskDefinition, 6, $UserAcct, $UserPass, 1)
                $newTask
            }
            TestScript = {
                $scheduleObject = New-Object -ComObject schedule.service
                $scheduleObject.connect()
                $folder = $scheduleObject.GetFolder('\Microsoft\Windows\PLA')
                $task = [bool]($folder.GetTasks(1) | Where-Object { $_.Name -eq 'LijnPC after reboot' } | Select-Object Name)
                $task
            }
            DependsOn  = "[Script]LijnPCLogMan"
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

    $DSComputers | ForEach-Object {

        $CompName = [System.String]$_.hostname
        Write-Output "Computer: $CompName"

        $PerfmonDSCname = 'LijnPC'
        $PerfDCSstatus = (logman query -s $CompName -n $PerfmonDSCname) -match 'LijnPC'
        if ($PerfDCSStatus) {
            write-output "The perfmon collector set already exists."
        }
        else {
            write-output "Installing the The perfmon collector set."
            $install = logman import -s $CompName -xml "\\s031.nedcar.nl\ncstd$\PROGRAMDATA\VDL Nedcar\Perfmon\LijnPC.xml" -y -name LijnPC
            $install
        }

        $PerfDCSstatus = (logman query -s $CompName -n $PerfmonDSCname) -match 'LijnPC'

        $TaskName = 'LijnPC after reboot'
        $TaskDescr = 'Datacollector set LijnPC'
        $TaskCommand = 'C:\WINDOWS\system32\schtasks.exe'
        $TaskArg = '/Run /TN "\Microsoft\Windows\PLA\LijnPC"'
        $TaskStartTime = [datetime]::Now.AddMinutes(5).ToString('s')

        $ScheduleObject = new-object -ComObject Schedule.Service
        $ScheduleObject.Connect("$CompName")

        $folder = $scheduleObject.GetFolder('\Microsoft\Windows\PLA')
        # Check if permon scheduled task exists.
        $perftask = [bool]($folder.GetTasks(1) | Where-Object { $_.Name -eq 'LijnPC' } | Select-Object Name)
        # Check if additional task already exists
        $task = [bool]($folder.GetTasks(1) | Where-Object { $_.Name -eq 'LijnPC after reboot' } | Select-Object Name)
        if ($perftask) {
            Write-Output "The perfmon task 'LijnPC' exists."
            if (!$task ) {
                Write-Output "Creating scheduled tasks 'LijnPC after reboot'."
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
                # $trigger.Delay = 'PT5M'

                $action = $TaskDefinition.Actions.Create(0)
                $action.Path = $TaskCommand
                $action.Arguments = $TaskArg

                $rootFolder = $ScheduleObject.GetFolder('\Microsoft\Windows\PLA')
                $UserAcct = 'SYSTEM'
                $UserPass = $null
                $rootFolder.RegisterTaskDefinition($TaskName, $TaskDefinition, 6, $UserAcct, $UserPass, 1)
            }
        }
        else {
            Write-Output "The perfmon task 'LijnPC' does not exist."
            if ($task) {
                Write-Output "Removing the additional task 'LijnPC after reboot'."
                $rootFolder = $ScheduleObject.GetFolder('\Microsoft\Windows\PLA')
                #
                #
            }
            else {
                Write-Output "No additional stuff to do."
            }
        }
    }
}
