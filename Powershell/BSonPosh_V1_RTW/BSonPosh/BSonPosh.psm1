################################################################################
## Exported Variables (if you want them uncomment)
New-Variable -Name WebClient       -value (New-Object System.Net.WebClient)                                               -Scope Global -Force
New-Variable -Name NTIdentity      -value ([Security.Principal.WindowsIdentity]::GetCurrent())                            -Scope Global -Force
New-Variable -Name NTPrincipal     -value (new-object Security.Principal.WindowsPrincipal $NTIdentity)                    -Scope Global -Force
New-Variable -Name isAdmin         -value ($NTPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) -Scope Global -Force
New-Variable -Name svcutil         -value "C:\Program Files\Microsoft SDKs\Windows\v6.1\Bin\svcutil.exe"                  -Scope Global -Force
New-Variable -Name installUtilx86  -value "C:\Windows\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe"                 -Scope Global -Force
New-Variable -Name installUtilx64  -value "C:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe"               -Scope Global -Force
New-Variable -Name installUtil     -value ("{0}InstallUtil.exe" -f  [Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())   `
                                   -Scope Global -Force

################################################################################
function Get-BSonPosh
{
    <#
    .Synopsis
        Get all the command contained in the BSonPosh Module
        
    .Description
        Get all the command contained in the BSonPosh Module
        
    .Parameter Verb
    
    .Parameter Noun
    
    .Example
        Get-BSonPosh
        
    .Example
        Get-BSonPosh -verb Get
        
    .Example
        Get-BSonPosh -noun Host
        
    .ReturnValue
        function
        
    .Notes
        NAME:      Get-BSonPosh
        AUTHOR:    YetiCentral\bshell
        Website:   www.bsonposh.com
        #Requires -Version 2.0
    #>

    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Verb = "*",
        [Parameter()]
        [string]$noun = "*"
    )


    Process
    {
        Get-Command -Module BSonPosh -Verb $verb -noun $noun
    }#Process

} # Get-BSonPosh

New-Variable -Name BSonPoshModuleHome -Value $psScriptRoot -Scope Global -Force

$ErrorActionPreference = "SilentlyContinue"
# code to prevent the ntfs.dll file from locking
dir $env:TEMP *.die | Remove-Item -Force -ErrorAction 0
$NTFSDLL = "ntfs_{0}.die" -f (Get-Random)
copy $psScriptRoot\ntfs.dll $env:Temp\$NTFSDLL
[System.Reflection.Assembly]::LoadFile("$env:Temp\$NTFSDLL") | out-null
$ErrorActionPreference = "Continue"

# code to load scripts
dir $BSonPoshModuleHome *.ps1 | %{. $_.fullname}
dir $BSonPoshModuleHome\FormatFiles *.ps1xml | foreach-object{ Update-FormatData $_.fullname -ea 0 } 

Write-Host
