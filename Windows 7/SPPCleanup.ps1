#
# ISSUE:
#     Software Protection Platform service (sppsvc) needs to be stopped (to enable the deletions in the next step).
#     Four files need to be deleted (remnants of previous protocol, that’s how the PG wants it phrased).
#     Software Protection Platform service (sppsvc) needs to be restarted.
#     A forced activation request needs to be sent to the environment’s KMS host
#
# WORK-AROUND:
#    From elevated cmd prompt: 
#    net stop sppsvc 
#    del %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0 /ah 
#    del %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0 /ah 
#    del %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat 
#    del %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat 
#    net start sppsvc 
#    cscript.exe slmgr.vbs /ato
#    exit
#

#
# Ensuring that the current session is running elevated. If not, then exit.
#
$windowsIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($windowsIdentity)

$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
if (-NOT ($windowsPrincipal.IsInRole($adminRole))) {
   throw "This prompt must be running elevated!"
}

Write-Output "Running cleanup of SPP previous protocol ..."

$ServiceName = "sppsvc"

#
# Let us attempt to stop the SPPSVC service, but only if it is in the Running state.
#
$arrService = Get-Service -Name $ServiceName
if ($arrService.Status -eq "Running") {
    try {
        Stop-Service $ServiceName -ErrorAction Stop
        Write-Output "SPPSVC was stopped."
    }
    catch {
        Write-Output "Could not stop SPPSVC: $($_.Exception.Message)"
        exit
    }
}

#
# Let us now delete the files specified in the scenario work-around.
# Deleting the first file. Note that without the use of -Force, the script cannot delete hidden files.
#
if (Test-Path %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0) {
    try {
        Remove-Item -path %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0 -Force -ErrorAction Stop
        Write-Output "%windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0 was deleted"
    }
    catch {
        Write-Output "Failed to delete %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0: $($_.Exception.Message)"
    }
}
else {
    Write-Output "%windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-0.C7483456-A289-439d-8115-601632D005A0 does not exist."
}

#
# Deleting the second file. Note once again that without the use of -Force, the script cannot delete hidden files.
#
if (Test-Path %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0) {
    try {
        Remove-Item %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0 -Force -ErrorAction Stop
        Write-Output "%windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0 was deleted"
    }
    catch {
        Write-Output "Failed to delete %windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0: $($_.Exception.Message)"
    }
}
else {
    Write-Output "%windir%\system32\7B296FB0-376B-497e-B012-9C450E1B7327-5P-1.C7483456-A289-439d-8115-601632D005A0 does not exist."
}

#
# Deleting the third file.
#
if (Test-Path %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat) {
    try {
        Remove-Item %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat -ErrorAction Stop
        Write-Output "%windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat was deleted"
    }
    catch {
        Write-Output "Failed to delete %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat: $($_.Exception.Message)"
    }
}
else {
    Write-Output "%windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\tokens.dat does not exist."
}

#
# Deleting the fourth file.
#
if (Test-Path %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat) {
    try {
        Remove-Item %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat -ErrorAction Stop
        Write-Output "%windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat was deleted"
    }
    catch {
        Write-Output "Failed to delete %windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat: $($_.Exception.Message)"
    }
}
else {
    Write-Output "%windir%\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\SoftwareProtectionPlatform\cache\cache.dat does not exist."
}

#
# Let us start the SPPSVC service, but only if its in the Stopped state.
#
$arrService = Get-Service -Name $ServiceName
if ($arrService.Status -eq "Stopped") {
    try {
        Start-Service $ServiceName -ErrorAction Stop
        Write-Output "SPPSVC was started."
    }
    catch {
        Write-Output "Could not start SPPSVC: $($_.Exception.Message). If the required files were deleted, you can ignore this message and manually start the SPPSVC service."
        # We are deliberately not exiting the script since the required file deletions may have been successful.
        #exit
    }
}

#
# Now let us execute the specified VBScript file. We pass //B in order to suppress script errors and prompts from displaying
$exe = “C:\WINDOWS\System32\cscript.exe”
$exeArg1 = “C:\WINDOWS\System32\slmgr.vbs"
$exeArg2 = "/ato"

try {
    Write-Output "Starting Windows Software Licensing Management Tool ..."
    Start-Process -FilePath $exe -ArgumentList $exeArg1,$exeArg2 -NoNewWindow -Wait -ErrorAction Stop
    Write-Output "Cleanup of SPP Completed"
}
catch {
    Write-Output "Failed to start process: $($_.Exception.Message)"
    exit
}