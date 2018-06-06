# =========================================================
# Uninstall all versions of Check Point VPN
#
# Marcel Jussen
# 06-06-2018
#
# Change:
# =========================================================
#Requires -version 3.0
Function Append-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [system.string]
        $Message
    )
    $logTime = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    Write-host "[$logtime]: $message"
    Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

#-----------------------------------------------------------------------
$PSScriptName = $myInvocation.MyCommand.Name
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

New-Item -Path "$ENV:ProgramData\VDL Nedcar\Logboek\W10Upgrade\" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$SCRIPTLOG = "$ENV:ProgramData\VDL Nedcar\Logboek\W10Upgrade\Check-Point-VPN-Uninstall.log"
if (Test-Path $SCRIPTLOG) {
    Remove-Item $SCRIPTLOG -Force -ErrorAction SilentlyContinue
}
Append-Log "Started script $PSScriptName from $PSScriptRoot"

#-----------------------------------------------------------------------
# Search package title.
$PackageTitle = 'Check Point VPN'

# Package version text which will not be uninstalled.
$ApprovedVersion = '98.60.6012'

# If any version of the package was uninstalled, this indicator file shows which it was.
$IndicatorFile = "$ENV:ProgramData\VDL Nedcar\Logboek\W10Upgrade\CheckPoint.Package.log"
Remove-Item -Path $IndicatorFile -Force -ErrorAction SilentlyContinue | Out-Null
#-----------------------------------------------------------------------

Append-Log "Search Wow6432Node uninstall keys for package title '$PackageTitle'."
$uninstall32 = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $PackageTitle } | Select-Object UninstallString
$uninstall32Version = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $PackageTitle } | Select-Object DisplayVersion
if ($uninstall32) {
    $uninstall32 = $uninstall32.UninstallString -Replace "msiexec.exe", "" -Replace "/I", "" -Replace "/X", ""
    $uninstall32 = $uninstall32.Trim()
    Append-Log "Found package $uninstall32"
    Append-Log "Version of this package: $($uninstall64Version.DisplayVersion)"
    if ($($uninstall32Version.DisplayVersion) -ne $ApprovedVersion) {
        Append-Log "Unapproved version found: $($uninstall32Version.DisplayVersion)"
        Append-Log "Uninstalling package $uninstall32"

        # Save indicator file that shows which package was uninstalled.
        Add-Content -Path $IndicatorFile -Value $uninstall32
        Add-Content -Path $IndicatorFile -Value $($uninstall32Version.DisplayVersion)

        #Start-Process "msiexec.exe" -arg "/X $uninstall32 /quiet /norestart" -Wait
        Append-Log "Uninstalling package done."
    }
    else {
        Append-Log "Approved version found: $($uninstall32Version.DisplayVersion)"
        Append-Log "This package will not be uninstalled."
    }
}
else {
    Append-Log "No x86 uninstall keys found."
}

Append-Log "Search uninstall keys for package title '$PackageTitle'."
$uninstall64 = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $PackageTitle } | Select-Object UninstallString
$uninstall64Version = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $PackageTitle } | Select-Object DisplayVersion
if ($uninstall64) {
    $uninstall64 = $uninstall64.UninstallString -Replace "msiexec.exe", "" -Replace "/I", "" -Replace "/X", ""
    $uninstall64 = $uninstall64.Trim()
    Append-Log "Found package $uninstall64"
    Append-Log "Version of this package: $($uninstall64Version.DisplayVersion)"
    if ($($uninstall64Version.DisplayVersion) -ne $ApprovedVersion) {
        Append-Log "Unapproved version found: $($uninstall64Version.DisplayVersion)"
        Append-Log "Uninstalling package $uninstall64"

        # Save indicator file that shows which package was uninstalled.
        Add-Content -Path $IndicatorFile -Value $uninstall64
        Add-Content -Path $IndicatorFile -Value $($uninstall64Version.DisplayVersion)

        #Start-Process "msiexec.exe" -arg "/X $uninstall64 /quiet /norestart" -Wait
        Append-Log "Uninstalling package done."
    }
    else {
        Append-Log "Approved version found: $($uninstall64Version.DisplayVersion)"
        Append-Log "This package will not be uninstalled."
    }
}
else {
    Append-Log "No x64 uninstall keys found."
}

Append-Log "Ended script $PSScriptName from $PSScriptRoot"