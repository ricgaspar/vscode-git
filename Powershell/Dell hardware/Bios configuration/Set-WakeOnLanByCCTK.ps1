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
# ========================================================
Function Set-Output {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$Message
    )
    $LogTime = Get-Date
    $LogText = "[$($logTime)] $($Message)"
    Add-Content "$Env:ProgramData\VDL Nedcar\Logboek\BIOS\Set-WakeOnLanByCCTK.log" $LogText
    Write-Output $LogText
}

New-Item -Path "$Env:ProgramData\VDL Nedcar\Logboek\BIOS" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
Remove-Item -Path "$Env:ProgramData\VDL Nedcar\Logboek\BIOS\Set-WakeOnLanByCCTK.log" -Force -ErrorAction SilentlyContinue | Out-Null
# Update Dell BIOS to accept Wake-On-LAN
Set-Output "[$env:COMPUTERNAME] Start of script."
Set-Output "[$env:COMPUTERNAME] Powershell version: $($PSVersionTable.PSVersion)"
$ErrorVal = $False
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
    Set-Output "[$env:COMPUTERNAME] Computername: $env:COMPUTERNAME"
    Set-Output "[$env:COMPUTERNAME] Make: $($Make.Manufacturer)"
    if (($Make.Model -eq 'Optiplex 7040') -or ($Make.Model -eq 'Latitude E5570')) {
        Set-Output "[$env:COMPUTERNAME] Model (*): $($Make.Model)"
        $VerArray = $($Biosver.SMBIOSBIOSVersion).split('.')
        Set-Output "[$env:COMPUTERNAME] Major: $($VerArray[0])"
        Set-Output "[$env:COMPUTERNAME] Minor: $($VerArray[1])"

        if ( ($($VerArray[0]) -ge $AcceptedBIOSMajor ) -and ( $($VerArray[1]) -ge $AcceptedBIOSMinor) ) {
            Set-Output "[$env:COMPUTERNAME] BIOS: $($BIOSver.SMBIOSBIOSVersion)"
            Set-Output "[$env:COMPUTERNAME] A valid BIOS version was found."
        }
        else {
            Set-Output "[$env:COMPUTERNAME] BIOS (*): $($BIOSver.SMBIOSBIOSVersion)"
            Set-Output "[$env:COMPUTERNAME] ERROR: BIOS version is not valid. Cannot update this BIOS."
            Set-Output "[$env:COMPUTERNAME] Acceptable BIOS version should at least be $($AcceptedBIOS)"
            $ErrorVal = $True
        }
    }
    else {
        Set-Output "[$env:COMPUTERNAME] Model: $($Make.Model)"
        Set-Output "[$env:COMPUTERNAME] BIOS: $($BIOSver.SMBIOSBIOSVersion)"
        Set-Output "[$env:COMPUTERNAME] A valid BIOS version was found."
    }
}

#
# If BIOS version is OK, check for required parameter values and update if needed.
#
if ((!$ErrorVal) -and (Test-Path 'C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe')) {
    Set-Output "[$env:COMPUTERNAME] The CCTK commandline tool was found."

    $CommandsArgs = '--valsetuppwd=kleinevogel --wakeonlan=enable', '--valsetuppwd=kleinevogel --deepsleepctrl=disable'

    ForEach ($Args in $CommandsArgs) {
        Set-Output "[$env:COMPUTERNAME] Start process."
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.FileName = 'C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe'
        $process.StartInfo.Arguments = $Args
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
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



    # $process = New-Object System.Diagnostics.Process
    # $process.StartInfo.FileName = 'C:\ProgramData\VDL Nedcar\CCTK.3.2\UpdateBiosConfiguration.cmd'
    # $process.StartInfo.UseShellExecute = $false
    # $process.StartInfo.RedirectStandardOutput = $true
    # if ( $process.Start() ) {
    #     $output = $process.StandardOutput.ReadToEnd() -replace "\r\n$", ""
    #     if ( $output ) {
    #         if ( $output.Contains("`r`n") ) { $output -split "`r`n" }
    #         elseif ( $output.Contains("`n") ) { $output -split "`n" }
    #     }
    #     else {
    #         $output
    #   		}
    # }

    # $process.WaitForExit()
    # & "$Env:SystemRoot\system32\cmd.exe" `
    #   		/c exit $process.ExitCode
}
else {
    if ($ErrorVal) {
        Set-Output "[$env:COMPUTERNAME] ERROR: The computer BIOS version is not compatible."
    }
    else {
        Set-Output "[$env:COMPUTERNAME] ERROR: The CCTK commandline tool was not found."
    }
}
Set-Output "[$env:COMPUTERNAME] End of script. Bye bye."