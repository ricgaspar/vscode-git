# =========================================================
# VDL Nedcar - Information Systems
#
# .SYNOPSIS
# 	Repair remote CCM agents
#
# .CREATED_BY
# 	Marcel Jussen
#
# .CHANGE_DATE
# 	16-06-2016
#
# .DESCRIPTION
#	Uninstall and re-install CCM agents due to 10808 events (policy compile errors)
#
# =========================================================
#Requires -version 3.0

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

# ---------------------------------------------------------
# enforces all errors to become terminating unless you override with 
# per-command -ErrorAction parameters or wrap in a try-catch block
$script:ErrorActionPreference = "Stop"

Function Get-BrokenClients {
    $SQLconn = New-SQLconnection s007.nedcar.nl 'CM_VNB'
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

    $ClientArray = @()
	# Execute view from SECDUMP.
	$query = "select distinct MachineName from StatusMessages where (MessageID = '10808') and datediff(MINUTE, Time, Getdate()) <= (120+15)"
	$data = Query-SQL $query $SQLconn
	if($data) {
        $reccount = $data.Count	
		ForEach($rec in $data) {
            $MachineName = $rec.MachineName 
            $ClientArray += $MachineName
        }
    }
    $ClientArray 
}

Function Invoke-RepairClient {
    param (
        [string]$RemoteComputer,
        [string]$ScriptRoot
    )
       
    $remote = Test-WSMan $RemoteComputer -ErrorAction SilentlyContinue
    if($remote) { 
        Echo-Log "  WSMAN test was successfull."        

        "copy C:\Scripts\SCCM\ClientRepair\repair.cmd \\$RemoteComputer\C$\Windows\Temp\* /Y" | Out-File D:\repair.cmd -Append -NoClobber -Encoding Default
        "copy C:\Scripts\SCCM\ClientRepair\ccmreinst.ps1 \\$RemoteComputer\C$\Windows\Temp\* /Y" | Out-File D:\repair.cmd -Append -NoClobber -Encoding Default
        $ArgumentList = [string]"psexec \\$RemoteComputer -u nedcar\Adm1 -p J0m4w1@gdc -d C:\Windows\Temp\repair.cmd"
        $ArgumentList | Out-File D:\repair.cmd -Append -NoClobber -Encoding Default
        $ExecTime = Get-Date –f "yyyy-MM-dd-HHmmss"
        "$RemoteComputer repair started at $ExecTime" | Out-File D:\repairedlist.log -Append -NoClobber -Encoding Default                    

    } else {
        Echo-Log "  WSMAN test ended in error."
    }
}

# =========================================================
# Record start of script.
cls
$BaseStart = Get-Date

# Create default folder structure if it is not there already
[void]( Create-FolderStruct "$env:SYSTEMDRIVE\Logboek\SCCM Client Repair" )
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$logTime = Get-Date –f "yyyy-MM-dd-HHmmss"
$RepairLog = "$env:SYSTEMDRIVE\Logboek\SCCM Client Repair\Remote-Repair-$logTime.log"
$Global:glb_EVENTLOGFile = $RepairLog
[void](Init-Log -LogFileName $RepairLog $False -alternate_location $True)
Echo-Log ("=" * 80)

Remove-Item D:\repair.cmd -Force -ErrorAction SilentlyContinue
"@echo off" | Out-File D:\repair.cmd -Append -NoClobber -Encoding Default
$ApprovedList = Get-Content "D:\repairedlist.log"

$BrokenClients = Get-BrokenClients
ForEach( $RemoteComputer in $BrokenClients) {
    Echo-Log "Computer: $RemoteComputer"
    $Result = (($ApprovedList | Select-String -Pattern $RemoteComputer) -ne $null) 
    if($Result) { 
        $ExecTime = Get-Date –f "yyyy-MM-dd-HHmmss"
        $ErrTxt = "ERROR: Computer $RemoteComputer was already repaired."
        Echo-Log $ErrTxt  
        "$ExecTime $ErrTxt" | Out-File D:\errorlist.log -Append -NoClobber -Encoding Default
    } else {
        Invoke-RepairClient -RemoteComputer $RemoteComputer -ScriptRoot $PSScriptRoot
    }
}

Echo-Log "End of cleanup script."
$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log "Total script running time : $min"				
Echo-Log ("=" * 80)

Close-LogSystem