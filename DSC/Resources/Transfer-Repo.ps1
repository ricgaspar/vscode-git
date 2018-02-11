# ---------------------------------------------------------
<#
.SYNOPSIS
    Creates a local repository for the
    Nedcar Standard Server environment.

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
function loopNodes {
    param (
        $oElmntParent,
        $strPath
    )
    #Write-Host $strPath
    $dirInfo = New-Object System.IO.DirectoryInfo $strPath
    $dirInfo.GetDirectories() | ForEach-Object {
        $OutNull = $oElmntChild = $xmlDoc.CreateElement("folder")
        $OutNull = $oElmntChild.SetAttribute("name", $_.Name)
        $OutNull = $oElmntParent.AppendChild($oElmntChild)
        loopNodes $oElmntChild ($strPath + "\" + $_.Name)
    }
    $dirInfo.GetFiles() | ForEach-Object {
        $crc32 = Get-Crc32 $_.FullName
        $OutNull = $oElmntChild = $xmlDoc.CreateElement("file")
        $OutNull = $oElmntChild.SetAttribute("name", $_.Name)
        $OutNull = $oElmntChild.SetAttribute("bytesSize", $_.Length)
        $OutNull = $oElmntChild.SetAttribute("crc32", $crc32)
        $OutNull = $oElmntParent.AppendChild($oElmntChild)
    }
}
function Set-Manifest {
    param (
        $SourcePath,
        $ManifestPathName
    )
    $path = $SourcePath
    $xmlDoc = New-Object xml
    if ($path -ne '') {
        $OutNull = $xmlDoc.AppendChild($xmlDoc.CreateProcessingInstruction("xml", "version='1.0'"))
        $OutNull = $oElmntRoot = $xmlDoc.CreateElement("baseDir")
        $OutNull = $oElmntRoot.SetAttribute("path", $path)
        $OutNull = $oElmntRoot.SetAttribute("description", "This is the root folder")
        $OutNull = $xmlDoc.AppendChild($oElmntRoot)
        loopNodes $oElmntRoot $path
    }
    $OutNull = $xmlDoc.Save($ManifestPathName)
}

# ---------------------------------------------------------
Configuration NCSTDREPO
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoSource,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ManifestSource,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BinSource
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    $RepoSYSTEMDRIVE = $RepoSource + '\SYSTEMDRIVE'
    $RepoSYSTEMRoot = $RepoSource + '\SYSTEMROOT'

    Node $Computername
    {
        File NCSTDFolder {
            DestinationPath = "$Env:SYSTEMDRIVE\ProgramData\VDL Nedcar\NCSTD"
            Type            = 'Directory'
            Ensure          = "Present"
            Force           = $true
        }
        File NCSTDFolderBin {
            DestinationPath = "$Env:SYSTEMDRIVE\ProgramData\VDL Nedcar\NCSTD\Bin"
            SourcePath      = $BinSource
            Type            = 'Directory'
            Attributes      = "Archive"
            Checksum        = "SHA-256"
            Ensure          = "Present"
            Force           = $True
            Recurse         = $True
            DependsOn       = "[File]NCSTDFolder"
        }

        File NCSTDManifestCopy
        {
            DestinationPath = "$Env:SYSTEMDRIVE\ProgramData\VDL Nedcar\NCSTD\Etc"
            SourcePath      = $ManifestSource
            Type            = 'Directory'
            Attributes      = "Archive"
            Checksum        = "SHA-256"
            Ensure          = "Present"
            Force           = $True
            Recurse         = $True
            DependsOn       = "[File]NCSTDFolder"
        }

        File NCSTDFolderRepository {
            DestinationPath = "$Env:SYSTEMDRIVE\ProgramData\VDL Nedcar\NCSTD\Repository"
            Type            = 'Directory'
            Ensure          = "Present"
            Force           = $true
            DependsOn       = "[File]NCSTDFolder"
        }

        File NCSTDSystemDriveCopy
        {
            DestinationPath = "$Env:SYSTEMDRIVE\ProgramData\VDL Nedcar\NCSTD\Repository\SystemDrive"
            SourcePath      = $RepoSYSTEMDRIVE
            Type            = 'Directory'
            Attributes      = "Archive"
            Checksum        = "SHA-256"
            Ensure          = "Present"
            Force           = $True
            Recurse         = $True
            DependsOn       = "[File]NCSTDFolderRepository"
        }

        File NCSTDSystemRootCopy
        {
            DestinationPath = "$Env:SYSTEMDRIVE\ProgramData\VDL Nedcar\NCSTD\Repository\SystemRoot"
            SourcePath      = $RepoSYSTEMROOT
            Type            = 'Directory'
            Attributes      = "Archive"
            Checksum        = "SHA-256"
            Ensure          = "Present"
            Force           = $True
            Recurse         = $True
            DependsOn       = "[File]NCSTDFolderRepository"
        }
    }
}

$ScriptRoot = Split-Path -Parent $PSCommandPath

$RepoSourcePath = '\\s031.nedcar.nl\NCSTD$\Repository'
$BinSourcePath = $RepoSourcePath + '\BIN'
$ManifestSourcePath = $RepoSourcePath + '\ETC'

$SourceFolderPath = $RepoSourcePath + '\SYSTEMDRIVE'
$ManifestPath = $ManifestSourcePath + '\ManifestSystemDrive.xml'
Set-Manifest -SourcePath $SourceFolderPath -ManifestPathName $ManifestPath

$SourceFolderPath = $RepoSourcePath + '\SYSTEMROOT'
$ManifestPath = $ManifestSourcePath + '\ManifestSystemRoot.xml'
Set-Manifest -SourcePath $SourceFolderPath -ManifestPathName $ManifestPath

Write-Output "Repository    : $($RepoSourcePath)"
Write-Output "Manifest      : $($ManifestSourcePath)"
Write-Output "Bin source    : $($BinSourcePath)"

# ---------------------------------------------------------

$DSComputers = New-Object System.Collections.ArrayList
$item = New-Object System.Object
$item | Add-Member -MemberType NoteProperty -Name "hostname" -Value "vdlnc01800"
$item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value "vdlnc01800.nedcar.nl"
$DSComputers.Add($item) | Out-Null

$item = New-Object System.Object
$item | Add-Member -MemberType NoteProperty -Name "hostname" -Value "vdlnc00106t"
$item | Add-Member -MemberType NoteProperty -Name "dnshostname" -Value "vdlnc00106t.nedcar.nl"
$DSComputers.Add($item) | Out-Null

if ($DSComputers -eq $null) {
    Write-Error "ERROR: No computers collected from $ADOU_DisplayPC"
}
else {
    $DSComputers | ForEach-Object {
        $CompName = [System.String]$_.dnshostname
        Write-Output "Compile DSC mof for computer: $CompName"

        Set-Location -Path $ScriptRoot
        NCSTDREPO -Computername $CompName `
            -RepoSource $RepoSourcePath `
            -ManifestSource $ManifestSourcePath `
            -BinSource $BinSourcePath
    }
}