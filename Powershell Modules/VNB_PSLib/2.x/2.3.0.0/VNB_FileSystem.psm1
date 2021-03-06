<#
.SYNOPSIS
    VNB Library - File system

.CREATED_BY
	Marcel Jussen

.VERSION
	2.3.0.0

.CHANGE_DATE
	20-11-2017

.DESCRIPTION
    File systems functions
#>
#Requires -version 4.0

function Test-DirExists
{
    # ---------------------------------------------------------
    # Returns true is a directory exists
    # ---------------------------------------------------------
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias("Path", "Folder", "Foldername")]
        [string]
        $FolderPath
    )
    Process
    {
        return ([IO.Directory]::Exists($FolderPath))
    }
}
Set-Alias Exists-Dir Test-DirExists
Set-Alias Test-PathExists Test-DirExists

function Test-FileExists
{
    # ---------------------------------------------------------
    # Returns true if a file exists
    # ---------------------------------------------------------
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias("Path", "File", "Filename")]
        [string]
        $FilePath
    )
    Process
    {
        return ([IO.File]::Exists($FilePath))
    }
}
Set-Alias Exists-File Test-FileExists

function New-FolderStructure
{
    # ---------------------------------------------------------
    # Create a folder structure with recursion
    # ---------------------------------------------------------
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Alias("Path", "FilePath", "Filename")]
        [string]
        $FolderPath
    )
    Begin
    {
        $arr = $FolderPath -split '\\'
        $drive = $arr[0]
        $NewPath = $drive
    }

    Process
    {
        try
        {
            # if(Test-DirExists($FolderPath)) { return 0 }
            foreach ($fldr in $arr)
            {
                if ($fldr -ne $drive)
                {
                    $NewPath += ('\' + $fldr)
                    if ( !(Test-DirExists($FolderPath)) )
                    {
                        [Void][system.io.directory]::CreateDirectory($NewPath)
                    }
                }
            }
        }
        Catch [System.Management.Automation.PSArgumentException]
        {
            "Invalid object while trying to create a folder structure."
        }
        Catch [system.exception]
        {
            "Caught a system exception while trying to create a folder structure."
        }
    }
}
set-alias Create-FolderStruct New-FolderStructure

function Get-FilesByAge
{
    # ---------------------------------------------------------
    # Returs an array of files sorted by age
    # ---------------------------------------------------------
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        [Alias("Path", "Folder", "Foldername")]
        [string]
        $FolderPath,

        [parameter(Mandatory = $False)]
        [string]
        $Include = "*",

        [parameter(Mandatory = $False)]
        [string]
        $Exclude = "",

        [parameter(Mandatory = $False)]
        [alias("Age")]
        [int]
        $age_in_days = 0,

        [parameter(Mandatory = $False)]
        [int]
        $Recurse = $false
    )

    Begin
    {
        $Now = Get-Date
        $LastWrite = $Now.AddDays( - $Age_in_days)
    }

    Process
    {
        # -Recurse parm is always needed when using -Include and/or -Exclude
        if ($Recurse -eq $True)
        {
            $Files = Get-ChildItem -path $FolderPath -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |
                Where-Object {$_.psIsContainer -eq $false} |
                Where-Object {$_.LastWriteTime -le "$LastWrite"}
        }
        else
        {
            # When recursion of folders is not wanted make sure the directory name is equal to the folder path
            $Files = Get-ChildItem -path $FolderPath -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |
                Where-Object {$_.psIsContainer -eq $false} |
                Where-Object {$_.DirectoryName -eq $FolderPath} |
                Where-Object {$_.LastWriteTime -le "$LastWrite"}
        }

        $Files = $Files | Sort-Object @{expression = {$_.LastWriteTime}; Descending = $true}
        return $Files
    }
}
Set-Alias Files_ByAge Get-FilesByAge

function Get-FoldersByAge
{
    # ---------------------------------------------------------
    # Returns an array of folders sorted by age
    # ---------------------------------------------------------
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $True)]
        [Alias("Path", "Folder", "Foldername")]
        [string]
        $FolderPath,

        [parameter(Mandatory = $False)]
        [string]
        $Include = "*",

        [parameter(Mandatory = $False)]
        [string]
        $Exclude = "",

        [parameter(Mandatory = $False)]
        [alias("Age")]
        [int]
        $age_in_days = 0,

        [parameter(Mandatory = $False)]
        [int]
        $Recurse = $false
    )

    Begin
    {
        $Now = Get-Date
        $LastWrite = $Now.AddDays( - $Age_in_days)

        # Add include wildcard to path
        # if($Include) { $FolderPath = "$Folderpath\$Include" }
    }

    Process
    {
        # -Recurse parm is always needed when using -Include and/or -Exclude
        if ($Recurse -eq $True)
        {
            $Folders = Get-ChildItem -path $FolderPath -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |
                Where-Object {$_.psIsContainer -eq $true} |
                Where-Object {$_.LastWriteTime -le "$LastWrite"}
        }
        else
        {
            # When recursion of folders is not needed make sure the Parent name of the folder is equal to the leaf name of the path
            $LeafFolder = Split-Path $FolderPath -Leaf
            if (($Include -eq $null) -or ($Include -eq '*'))
            {
                $Folders = Get-ChildItem -path $FolderPath -Include $Include -Exclude $Exclude -errorAction SilentlyContinue  |
                    Where-Object {$_.psIsContainer -eq $true} |
                    Where-Object {$_.LastWriteTime -le "$LastWrite"}
            }
            else
            {
                $Folders = Get-ChildItem -path $FolderPath -Include $Include -Exclude $Exclude -Recurse -Force -errorAction SilentlyContinue  |
                    Where-Object {$_.psIsContainer -eq $true} |
                    Where-Object {$_.Parent.name -eq $LeafFolder} |
                    Where-Object {$_.LastWriteTime -le "$LastWrite"}
            }
        }

        $Folders = $Folders | Sort-Object @{expression = {$_.LastWriteTime}; Descending = $true}
        return $Folders
    }
}
Set-Alias Folders_ByAge Get-FoldersByAge

Function Get-FolderACL
{
    # ---------------------------------------------------------
    # Return a folder ACL list
    # ---------------------------------------------------------
    Param (
        [Parameter(Mandatory = $false)]
        [Alias('Computer')][String[]]$ComputerName = $Env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [Alias('Path')][String[]]$Path,

        [Parameter(Mandatory = $false)]
        [Alias('Cred')][System.Management.Automation.PsCredential]$Credential
    )

    #test server connectivity
    $PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
    if ($PingResult)
    {
        $Objs = @()

        # WMI path cannot contain \ but only \\
        $WMISharedFolderPath = $Path.Replace('\', '\\')

        # WMI path cannot contain quote character, it must be escaped
        $WMISharedFolderPath = $WMISharedFolderPath.Replace([string]([char]39), [string]"\'")
        if ($Credential)
        {
            $SharedNTFSSecs = Get-WmiObject -Class Win32_LogicalFileSecuritySetting `
                -Filter "Path='$WMISharedFolderPath'" -ComputerName $ComputerName  -Credential $Credential
        }
        else
        {
            $SharedNTFSSecs = Get-WmiObject -Class Win32_LogicalFileSecuritySetting `
                -Filter "Path='$WMISharedFolderPath'" -ComputerName $ComputerName
        }

        $SecDescriptor = $SharedNTFSSecs.GetSecurityDescriptor()
        foreach ($DACL in $SecDescriptor.Descriptor.DACL)
        {
            $DACLDomain = $DACL.Trustee.Domain
            $DACLName = $DACL.Trustee.Name
            if ($DACLDomain -ne $null)
            {
                $UserName = "$DACLDomain\$DACLName"
            }
            else
            {
                $UserName = "$DACLName"
            }

            $DACL.AccessMask

            #customize the property
            $Properties = @{'ComputerName' = [string]$ComputerName
                'ACLPath' = [string]$Path
                'SecurityPrincipal' = $UserName
                'FileSystemRights' = [Security.AccessControl.FileSystemRights]$($DACL.AccessMask -as [Security.AccessControl.FileSystemRights])
                'AccessControlType' = [Security.AccessControl.AceType]$DACL.AceType
                'AccessControlFlags' = [Security.AccessControl.AceFlags]$DACL.AceFlags
            }

            $SharedNTFSACL = New-Object -TypeName PSObject -Property $Properties
            $Objs += $SharedNTFSACL
        }
        $Objs |Select-Object ComputerName, ACLPath, SecurityPrincipal, FileSystemRights, `
            AccessControlType, AccessControlFlags -Unique
    }

    return $Objs
}

function Invoke-ConsoleCommand
# ---------------------------------------------------------
# Execute a console command and return the stdout results
# ---------------------------------------------------------
{

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]# The target of the action.
        $Target,
        [Parameter(Mandatory = $true)]
        [string]# The action/command being performed.
        $Action,
        [Parameter(Mandatory = $true)]
        [scriptblock]# The command to run.
        $ScriptBlock
    )

    Set-StrictMode -Version 'Latest'
    if (-not $PSCmdlet.ShouldProcess($Target, $Action))
    {
        return
    }

    $output = Invoke-Command -ScriptBlock $ScriptBlock
    if ($LASTEXITCODE)
    {
        $output = $output -join [Environment]::NewLine
        Write-Error ('Failed action ''{0}'' on target ''{1}'' (exit code {2}): {3}' -f $Action, $Target, $LASTEXITCODE, $output)
    }
    else
    {
        $output | Where-Object {
            $_ -ne $null
        } | Write-Verbose
    }
}

function Enable-NtfsCompression
{
    # ---------------------------------------------------------
    # Enable NTFS folder and file compression
    # ---------------------------------------------------------
    <#
    .SYNOPSIS
    Turns on NTFS compression on a file/directory.

    .DESCRIPTION
    By default, when enabling compression on a directory, only new files/directories created *after* enabling compression will be compressed.  To compress everything, use the `-Recurse` switch.

    Uses Windows' `compact.exe` command line utility to compress the file/directory.  To see the output from `compact.exe`, set the `Verbose` switch.

    .LINK
    Disable-NtfsCompression

    .LINK
    Test-NtfsCompression

    .EXAMPLE
    Enable-NtfsCompression -Path C:\Projects\Carbon

    Turns on NTFS compression on and compresses the `C:\Projects\Carbon` directory, but not its sub-directories.

    .EXAMPLE
    Enable-NtfsCompression -Path C:\Projects\Carbon -Recurse

    Turns on NTFS compression on and compresses the `C:\Projects\Carbon` directory and all its sub-directories.

    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer } | Enable-NtfsCompression

    Demonstrates that you can pipe the path to compress into `Enable-NtfsCompression`.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]
        [Alias('FullName')]
        # The path where compression should be enabled.
        $Path,

        [Switch]
        # Enables compression on all sub-directories.
        $Recurse
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        $commonParams = @{
            ErrorAction = $ErrorActionPreference;
            Verbose = $VerbosePreference;
            WhatIf = $WhatIfPreference;
        }

        $compactPath = Join-Path $env:SystemRoot 'system32\compact.exe'
        if ( -not (Test-Path -Path $compactPath -PathType Leaf) )
        {
            if ( (Get-Command -Name 'compact.exe' -ErrorAction SilentlyContinue) )
            {
                $compactPath = 'compact.exe'
            }
            else
            {
                Write-Error ("Compact command '{0}' not found." -f $compactPath)
                return
            }
        }
    }

    process
    {
        foreach ( $item in $Path )
        {
            if ( -not (Test-Path -Path $item) )
            {
                Write-Error -Message ('Path {0} not found.' -f $item) -Category ObjectNotFound
                return
            }

            $recurseArg = ''
            $pathArg = $item
            if ( (Test-Path -Path $item -PathType Container) )
            {
                if ( $Recurse )
                {
                    $recurseArg = ('/S:{0}' -f $item)
                    $pathArg = ''
                }
            }

            Invoke-ConsoleCommand -Target $item -Action 'enable NTFS compression' @commonParams -ScriptBlock {
                & $compactPath /C $recurseArg $pathArg
            }
        }
    }
}

function Disable-NtfsCompression
# ---------------------------------------------------------
# Disable folder and file compression
# ---------------------------------------------------------
{
    <#
    .SYNOPSIS
    Turns off NTFS compression on a file/directory.

    .DESCRIPTION
    When disabling compression for a directory, any compressed files/directories in that directory will remain compressed.  To decompress everything, use the `-Recurse` switch.  This could take awhile.

    Uses Windows' `compact.exe` command line utility to compress the file/directory.  To see the output from `compact.exe`, set the `Verbose` switch.

    .LINK
    Enable-NtfsCompression

    .LINK
    Test-NtfsCompression

    .EXAMPLE
    Disable-NtfsCompression -Path C:\Projects\Carbon

    Turns off NTFS compression on and decompresses the `C:\Projects\Carbon` directory, but not its sub-directories/files.  New files/directories will get compressed.

    .EXAMPLE
    Disable-NtfsCompression -Path C:\Projects\Carbon -Recurse

    Turns off NTFS compression on and decompresses the `C:\Projects\Carbon` directory and all its sub-directories/sub-files.

    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer } | Disable-NtfsCompression

    Demonstrates that you can pipe the path to compress into `Disable-NtfsCompression`.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]
        [Alias('FullName')]
        # The path where compression should be disabled.
        $Path,

        [Switch]
        # Disables compression on all sub-directories.
        $Recurse
    )

    begin
    {
        $commonParams = @{
            Verbose = $VerbosePreference;
            WhatIf = $WhatIfPreference;
            ErrorAction = $ErrorActionPreference;
        }

        $compactPath = Join-Path $env:SystemRoot 'system32\compact.exe'
        if ( -not (Test-Path -Path $compactPath -PathType Leaf) )
        {
            if ( (Get-Command -Name 'compact.exe' -ErrorAction SilentlyContinue) )
            {
                $compactPath = 'compact.exe'
            }
            else
            {
                Write-Error ("Compact command '{0}' not found." -f $compactPath)
                return
            }
        }
    }

    process
    {
        foreach ( $item in $Path )
        {
            if ( -not (Test-Path -Path $item) )
            {
                Write-Error -Message ('Path {0} not found.' -f $item) -Category ObjectNotFound
                return
            }

            $recurseArg = ''
            $pathArg = $item
            if ( (Test-Path -Path $item -PathType Container) )
            {
                if ( $Recurse )
                {
                    $recurseArg = ('/S:{0}' -f $item)
                    $pathArg = ''
                }
            }

            Invoke-ConsoleCommand -Target $item -Action 'disable NTFS compression' @commonParams -ScriptBlock {
                & $compactPath /U $recurseArg $pathArg
            }
        }
    }
}

# ---------------------------------------------------------
# Export aliases
# ---------------------------------------------------------
export-modulemember -alias * -function *