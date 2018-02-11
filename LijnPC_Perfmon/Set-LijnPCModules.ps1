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

# ---------------------------------------------------------
Configuration LIJNPCMODULES
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

    Node $Computername
    {
        File PSModulesCopy {
            DestinationPath = $ENV:ProgramFiles + '\WindowsPowerShell\Modules'
            SourcePath      = $SourcePath
            Type            = 'Directory'
            Attributes      = 'Archive'
            Checksum        = 'SHA-256'
            Ensure          = 'Present'
            Force           = $True
            Recurse         = $True
            MatchSource     = $True
        }
    }
}

$ScriptRoot = Split-Path -Parent $PSCommandPath

# Make sure to change location to the folder where this script is located.
Set-Location -Path $ScriptRoot
# ---------------------------------------------------------

$Computername = 'VDLNC00282'

$DSComputers = New-Object System.Collections.ArrayList
$item = New-Object System.Object
$item | Add-Member -MemberType NoteProperty -Name "hostname" -Value $Computername
$item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value $Computername
$DSComputers.Add($item) | Out-Null

if ($DSComputers -eq $null) {
    Write-Error "ERROR: No computers to process."
}
else {
    $StandaardPath = '\\s031.nedcar.nl\ncstd$\MODULES'
    $DSComputers | ForEach-Object {
        $CompName = [System.String]$_.hostname
        Write-Output "Compile DSC mof for computer: $CompName"

        Try {
            $PSTable = (Invoke-Command -Computername $CompName { $PsversionTable })
            $PSVerRemoteMin = $PSTable.PSVersion.Minor
            $PSVerRemoteMaj = $PSTable.PSVersion.Major

            Write-Output "Remote host Powershell version: $PSVerRemoteMaj.$PSVerRemoteMin"
            $SourcePath = $null
            if (($PSVerRemoteMaj -eq '4') -or ($PSVerRemoteMaj -eq '5')) {
                $SourcePath = $StandaardPath + '\PS' + $PSVerRemoteMaj
            }
            if ($SourcePath) {
                LIJNPCMODULES -Computername $CompName -SourcePath $SourcePath
            }
        }
        Catch {
            Write-Output "The Powershell version of the computer '$Compname' cannot be determined."
        }
    }
}

# Start-DscConfiguration .\LIJNPCMODULES -Verbose -Force -Wait