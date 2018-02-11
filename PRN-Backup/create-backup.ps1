# ================================================
# Create Printer export file with PrintBRM tool
#
# Creates a daily backup of the local print server
# ================================================
#Requires -version 3.0

[CmdletBinding()]
param (
    [switch]$SaveRemote = $False,
    [string]$RemotePath = $null
)

# ------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop

Set-StrictMode -Version Latest

$ScriptLog = "$env:SYSTEMDRIVE\Logboek\PRN-Backup.log"
[void](Init-Log -LogFileName $ScriptLog $False -Alternate_location $True)

$backuptool = "$env:SYSTEMROOT\System32\Spool\tools\PrintBrm.exe"
$backupfile = "$env:SYSTEMDRIVE\Scripts\PRN-Backup\PRN-$env:COMPUTERNAME-BACKUP.printerExport"
$backupoptions = "-B -F $backupfile"

Echo-Log ("=" * 80)
Echo-Log "Starting printspooler backup on computer $env:COMPUTERNAME"
if(test-path $backupfile) {
    echo-Log "Removing previous backup file."
    remove-item $backupfile -Force -ErrorAction SilentlyContinue
}
if(test-path $backupfile) {
    echo-Log "ERROR: The previous backup file could not be removed successfully."    
} else {
    if(Test-Path $backuptool) {
        Echo-Log "Creating backup with command line:"
        Echo-Log "$backuptool $backupoptions"
        $log = Start-Executable -FilePath $backuptool -ArgumentList $backupoptions
        foreach($logline in $log) { echo-log $logline } 
        if(Test-Path $backupfile) {
            Echo-Log "The backup file was created successfully."
            if($SaveRemote) {
                Echo-Log "Creating remote copy of the backup to $RemotePath"
                Copy-Item $backupfile $RemotePath -ErrorAction Stop
            }
        } else {
            Echo-Log "ERROR: The backupfile was not found. The backup operation failed."
        }
    } else {
        Echo-Log "ERROR: Could not find $backuptool"
    }
}

Echo-Log "Done with printspooler backup."
Echo-Log ("=" * 80)

Close-LogSystem