# =========================================================
# VDL Nedcar - Information Systems
#
# .SYNOPSIS
# 	Update Dell BIOS parameters for Wake On LAN feature
#
# .CREATED_BY
# 	Marcel Jussen
#
# .CHANGE_DATE
# 	01-06-2018
#
# .DESCRIPTION
#	Updates the WakeOnLAN and DeepSleepCtrl parameters to enable Wake On LAN
#
# =========================================================
#Requires -version 4.0

Set-StrictMode -Version Latest

# Update Dell BIOS to accept Wake-On-LAN
Write-Output ("-" * 80)
Write-Output "[$env:COMPUTERNAME] Start of script."

New-Item -Path "$Env:ProgramData\VDL Nedcar\Logboek\BIOS" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

#
# WARNING
# Dell Optiplex 7040 and Latitude E5570 share a common BIOS model which has a critical bug when version < 1.5.0
#
$BIOSver = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop | Select-Object SMBIOSBIOSVersion
$Make = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object Manufacturer, Model
$AcceptedBIOSMajor = '1'
$AcceptedBIOSMinor = '5'
$AcceptedBIOS = $AcceptedBIOSMajor + '.' + $AcceptedBIOSMinor
if ($Make.Manufacturer -eq 'Dell Inc.') {
    Write-Output "[$env:COMPUTERNAME] Computername: $env:COMPUTERNAME"
    Write-Output "[$env:COMPUTERNAME] Make: $($Make.Manufacturer)"
    if (($Make.Model -eq 'Optiplex 7040') -or ($Make.Model -eq 'Latitude E5570')) {
        Write-Output "[$env:COMPUTERNAME] Model (*): $($Make.Model)"
        $VerArray = $($Biosver.SMBIOSBIOSVersion).split('.')
        Write-Output "[$env:COMPUTERNAME] Major: $($VerArray[0])"
        Write-Output "[$env:COMPUTERNAME] Minor: $($VerArray[1])"

        if ( ($($VerArray[0]) -ge $AcceptedBIOSMajor ) -and ( $($VerArray[1]) -ge $AcceptedBIOSMinor) ) {
            Write-Output "[$env:COMPUTERNAME] BIOS: $($BIOSver.SMBIOSBIOSVersion)"
            Write-Output "[$env:COMPUTERNAME] A valid BIOS version was found."
        }
        else {
            Write-Output "[$env:COMPUTERNAME] BIOS (*): $($BIOSver.SMBIOSBIOSVersion)"
            Write-Output "[$env:COMPUTERNAME] ERROR: BIOS version is not valid. Cannot update this BIOS."
            Write-Output "[$env:COMPUTERNAME] Acceptable BIOS version should at least be $($AcceptedBIOS)"
            Exit
        }
    }
    else {
        Write-Output "[$env:COMPUTERNAME] Model: $($Make.Model)"
        Write-Output "[$env:COMPUTERNAME] BIOS: $($BIOSver.SMBIOSBIOSVersion)"
        Write-Output "[$env:COMPUTERNAME] A valid BIOS version was found."
    }
}

#
# If BIOS version is OK, check for required parameter values and update if needed.
#
Write-Output ("-" * 80)

if (Test-Path 'C:\ProgramData\VDL Nedcar\CCTK.3.2') {
    Write-Output "[$env:COMPUTERNAME] The CCTK commandline tool was found."

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = 'C:\ProgramData\VDL Nedcar\CCTK.3.2\UpdateBiosConfiguration.cmd'
  	$process.StartInfo.UseShellExecute = $false
  	$process.StartInfo.RedirectStandardOutput = $true
  	if ( $process.Start() ) {
        $output = $process.StandardOutput.ReadToEnd() -replace "\r\n$", ""
        if ( $output ) {
            if ( $output.Contains("`r`n") ) { $output -split "`r`n" }
            elseif ( $output.Contains("`n") ) { $output -split "`n" }
        }
        else {
            $output
      		}
    }

    $process.WaitForExit()
    & "$Env:SystemRoot\system32\cmd.exe" `
      		/c exit $process.ExitCode
}
else {
    Write-Output "[$env:COMPUTERNAME] ERROR: The CCTK commandline tool was not found."
}

Write-Output ("-" * 80)
Write-Output "[$env:COMPUTERNAME] End of script. Bye bye."
Write-Output ("-" * 80)

# Stop-Transcript
