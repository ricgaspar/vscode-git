<#
.SYNOPSIS
    VNB Cleanup - cleanup/archive files and folders

.CREATED_BY
	Marcel Jussen

.VERSION
	2.3.0.0

.CHANGE_DATE
	20-11-2017

.DESCRIPTION
    General purpose file system cleanup and archive functions.
#>
#Requires -version 4.0

# ---------------------------------------------------------
# Global Statistics

$Global:CleanupStats = @{
    FoldersScanned         = 0
    FoldersDeleteAttempted = 0
    FoldersDeleteSucceeded = 0
    FilesScanned           = 0
    FilesDeleteAttempted   = 0
    FilesDeleteSucceeded   = 0
    CleanupInit            = $true
}

# Archive application
$Global:ArchiveApplication = "$env:ProgramFiles\Winrar\winrar.exe"

Function Initialize-Cleanup
{
    # ---------------------------------------------------------
    # Initializes Global variables used for cleanup functions
    # ---------------------------------------------------------
    $Global:CleanupStats.FoldersScanned = 0
    $Global:CleanupStats.FoldersDeleteAttempted = 0
    $Global:CleanupStats.FoldersDeleteSucceeded = 0
    $Global:CleanupStats.FilesScanned = 0
    $Global:CleanupStats.FilesDeleteAttempted = 0
    $Global:CleanupStats.FilesDeleteSucceeded = 0
}

Function Show-CleanupInfo
{
    [cmdletbinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        $CleanupCfgFilePath
    )
    Echo-Log ("-" * 80)
    Echo-Log "Folders scanned             : $($Global:CleanupStats.FoldersScanned)"
    Echo-Log "Folders attempted to delete : $($Global:CleanupStats.FoldersDeleteAttempted)"
    Echo-Log "Folders actually deleted    : $($Global:CleanupStats.FoldersDeleteSucceeded)"
    Echo-Log ("-" * 80)
    Echo-Log "Files scanned               : $($Global:CleanupStats.FilesScanned)"
    Echo-Log "Files attempted to delete   : $($Global:CleanupStats.FilesDeleteAttempted)"
    Echo-Log "Files actually deleted      : $($Global:CleanupStats.FilesDeleteSucceeded)"
    Echo-Log ("-" * 80)

    #Use splatting
    $CleanupResults = "" | Select ConfigFile, FoldersScanned, FoldersDeleteAttempted, FoldersDeleteSucceeded, FilesScanned, FilesDeleteAttempted, FilesDeleteSucceeded
    $CleanupResults.ConfigFile = $CleanupCfgFilePath
    $CleanupResults.FoldersScanned = $($Global:CleanupStats.FoldersScanned)
    $CleanupResults.FoldersDeleteAttempted = $($Global:CleanupStats.FoldersDeleteAttempted)
    $CleanupResults.FoldersDeleteSucceeded = $($Global:CleanupStats.FoldersDeleteSucceeded)
    $CleanupResults.FilesScanned = $($Global:CleanupStats.FilesScanned)
    $CleanupResults.FilesDeleteAttempted = $($Global:CleanupStats.FilesDeleteAttempted)
    $CleanupResults.FilesDeleteSucceeded = $($Global:CleanupStats.FilesDeleteSucceeded)

    $Erase = $Global:CleanupStats.CleanupInit

    $UDL = Read-UDLConnectionString $glb_UDL
    $ObjectName = 'VNB_CLEANUP_RESULTS'
    $Computername = $env:COMPUTERNAME

    try
    {
        $new = New-VNBObjectTable -UDLConnection $UDL -ObjectName $ObjectName -ObjectData $CleanupResults
        Send-VNBObject -UDLConnection $UDL -ObjectName $ObjectName -ObjectData $CleanupResults -Computername $Computername -Erase $Erase
        $Global:CleanupStats.CleanupInit = $false
    }
    catch
    {
        throw
        Echo-Log ("ERROR: Updating results to SQL table $ObjectName did not succeed.")
    }
}

Function Show-ParamInfo
{
    [cmdletbinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    Process
    {
        $ParamText = "Parameters:"
        if ($CleanupParams.Age -ge 0)
        {
            $ParamText += "[Age:$($CleanupParams.Age) days]"
        }
        else
        {
            $ParamText += "[Age:Not specified]"
        }
        if ($CleanupParams.Include.Length -gt 0)
        {
            $ParamText += "[Include:$($CleanupParams.Include)]"
        }
        else
        {
            $ParamText += "[Include:Not specified]"
        }
        if ($CleanupParams.Exclude.Length -gt 0)
        {
            $ParamText += "[Exclude:$($CleanupParams.Exclude)]"
        }
        else
        {
            $ParamText += "[Exclude:Not specified]"
        }
        if ($CleanupParams.Keep -gt 0)
        {
            $ParamText += "[Keep:$($CleanupParams.Keep)]"
        }
        else
        {
            $ParamText += "[Keep:Not specified]"
        }
        return $ParamText
    }
}

Function Show-DebugInfo
{
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )
    Process
    {
        $ParamText = Show-ParamInfo $CleanupParams
        if ($Global:DEBUG)
        {
            Echo-Log "(DEBUG) $ParamText"
        }
        else
        {
            return "$ParamText"
        }
    }
}

Function Invoke-CleanupFile
{
    # ---------------------------------------------------------
    # Cleanup a single file
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )
    Process
    {
        try
        {
            # Checking for age
            # This check is basically unneeded cause the list of files returned by Get-FilesByAge only has files from a selected age.
            # This additional check makes sure the lag to create the list does not influence the selection criteria.
            # Get-FilesByAge is therefore commonly used NOT to include the age and instead check for it here.
            $Now = Get-Date
            $LastWriteTime = [IO.File]::GetLastWriteTime($($CleanupParams.ObjectPath))
            $Days = ($Now - $LastWriteTime).days
            $Global:CleanupStats.FilesScanned++

            if ($Days -ge $CleanupParams.Age)
            {
                $Global:CleanupStats.FilesDeleteAttempted++
                if ($Global:DEBUG -eq $True)
                {
                    $text = Show-DebugInfo $CleanupParams
                    Echo-Log "$Global:cReq $($CleanupParams.ObjectPath) $text ([$Days] days)"
                }
                else
                {
                    $text = "$Global:cReq Remove file [$($CleanupParams.ObjectPath)]"
                    try
                    {
                        Remove-Item $CleanupParams.ObjectPath -ErrorAction SilentlyContinue -Force
                    }
                    catch
                    {
                        Echo-Log "$Global:cErr an error occurred during the removal of the file."
                    }
                    If (Test-FileExists -Path $CleanupParams.ObjectPath)
                    {
                        Echo-Log $text
                        Echo-Log "$Global:cErr Could remove $($CleanupParams.ObjectPath)"
                    }
                    else
                    {
                        Echo-Log "$text [Delete succeeded]"
                        $Global:CleanupStats.FilesDeleteSucceeded++
                    }
                }
            }
            else
            {
                if ($Global:DEBUG -eq $True)
                {
                    $text = Show-DebugInfo $CleanupParams
                    Echo-Log "$($CleanupParams.ObjectPath) $text ([$Days] days)"
                }
            }
        }
        catch
        {
            Echo-Log "$Global:cErr An error occured while accessing file $($CleanupParams.ObjectPath)"
        }
    }
}

Function Invoke-CleanupFiles
{
    # ---------------------------------------------------------
    # Cleanup files in a folder and/or subfolders
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    Process
    {
        Echo-Log "Remove files in folder: $($CleanupParams.ObjectPath)"
        $ParamText = Show-ParamInfo $CleanupParams
        Echo-Log $ParamText

        # Do NOT use -age_in_days!
        # Checking for age of files is done by function Invoke-CleanupFile
        # We overrule FSOAge with a dummy value set to null to create a complete list of all files in the folder.
        $FSOAgeDummy = $null
        $FileObjects = Get-FilesByAge -Path $CleanupParams.ObjectPath `
            -Include $CleanupParams.Include -Exclude $CleanupParams.Exclude `
            -Age $FSOAgeDummy -Recurse $CleanupParams.Recurse

        $count = 0
        If ($FileObjects -ne $null)
        {
            foreach ($FileObjectPath in $FileObjects)
            {
                $count++
                if ( $count -gt $CleanupParams.Keep )
                {
                    $CleanupParams.ObjectPath = [string]$($FileObjectPath.Fullname)
                    Invoke-CleanupFile $CleanupParams
                }
                else
                {
                    $Global:CleanupStats.FilesScanned++
                    if ($Global:DEBUG) { Echo-Log "$Global:cSpacer $count SKIPPED $($FileObjectPath.Fullname)" }
                }
            }
        }
        if (($count -eq 0) -or ($FileObjects -eq $null))
        {
            Echo-Log "No file system objects to process in $($CleanupParams.ObjectPath)"
        }

        # Cleanup memory
        if ($FileObjects) { try { Remove-Variable -Name FileObjects -Scope Global -Force } catch { } }
    }
}

Function Invoke-CleanupFolder
{
    # ---------------------------------------------------------
    # Cleanup a single folder and its contents
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )
    Process
    {
        try
        {
            $Global:CleanupStats.FoldersScanned++

            # Checking for age
            # This check is unneeded cause the list of folders returned by Get-FoldersByAge only has folders from selected age.
            # This additional check makes sure the lag to create the list does not influence the selection criteria.
            $Now = Get-Date
            $LastWriteTime = [IO.Directory]::GetLastWriteTime($($CleanupParams.ObjectPath))
            $Days = ($Now - $LastWriteTime).days

            if ($Days -ge $CleanupParams.Age)
            {
                $Global:CleanupStats.FoldersDeleteAttempted++
                if ($Global:DEBUG -eq $True)
                {
                    $text = Show-DebugInfo $CleanupParams
                    Echo-Log "$Global:cReq $($CleanupParams.ObjectPath) $text ([$Days] days)"
                }
                else
                {
                    $text = "$Global:cReq Delete folder [$($CleanupParams.ObjectPath)]"
                    try
                    {
                        Remove-Item $CleanupParams.ObjectPath -ErrorAction SilentlyContinue -Force -Recurse
                    }
                    catch
                    {
                        Echo-Log "$Global:cErr an error occurred during the removal of the folder."
                    }
                    If (Test-DirExists -Path $CleanupParams.ObjectPath)
                    {
                        Echo-Log $text
                        Echo-Log "$Global:cErr Could remove $($CleanupParams.ObjectPath)"
                    }
                    else
                    {
                        Echo-Log "$text [Delete succeeded]"
                        $Global:CleanupStats.FoldersDeleteSucceeded++
                    }
                }
            }
            else
            {
                if ($Global:DEBUG -eq $True)
                {
                    $text = Show-DebugInfo $CleanupParams
                    Echo-Log "$($CleanupParams.ObjectPath) $text ([$Days] days)"
                }
            }
        }
        catch
        {
            Echo-Log "$Global:cErr An error occured while accessing folder $($CleanupParams.ObjectPath)"
        }
    }
}

Function Invoke-CleanupFolders
{
    # ---------------------------------------------------------
    # Cleanup subfolders and all their contents in a folder
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    Process
    {
        Echo-Log "Remove folders from $($CleanupParams.ObjectPath)"
        $ParamText = Show-ParamInfo $CleanupParams
        Echo-Log $ParamText

        # Do NOT use -age_in_days!
        # Checking for age of files is done by function Invoke-CleanupFile
        # We overrule FSOAge with a dummy value set to null
        $FSOAgeDummy = $null

        # Create subfolder list of the folder
        $FolderObjects = Get-FoldersByAge -Path $($CleanupParams.ObjectPath) `
            -Recurse $False -Age $FSOAgeDummy -Include $CleanupParams.Include -Exclude $CleanupParams.Exclude

        $count = 0
        If ($FolderObjects -ne $null)
        {
            foreach ($SubFolderName in $FolderObjects)
            {
                $count++
                if ( $count -gt $CleanupParams.Keep )
                {
                    $CleanupParams.ObjectPath = $SubFolderName
                    Invoke-CleanupFolder $CleanupParams
                }
                else
                {
                    $Global:CleanupStats.FoldersScanned++
                    if ($Global:DEBUG) { Echo-Log "$Global:cSpacer $count SKIPPED $($SubFolderName)" }
                }
            }
        }
        if (($count -eq 0) -or ($FolderObjects -eq $null))
        {
            Echo-Log "No file system objects to process in $($CleanupParams.ObjectPath)"
        }

        # Cleanup memory
        if ($FolderObjects) { try { Remove-Variable -Name FolderObjects -Scope Global -Force } catch { } }
    }
}
Set-Alias Remove-Folders Invoke-CleanupFolders

Function Format-Path
{
    # ---------------------------------------------------------
    # Double quote a file path
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$FileObjectPath
    )
    Process
    {
        $FileObjectPath = '"' + $FileObjectPath.Trim() + '"'
        $FileObjectPath = $FileObjectPath.Replace('""', '"')
        return $FileObjectPath
    }
}

Function Format-ArchiveLogPathname
{
    # ---------------------------------------------------------
    # Format Winrar archive log pathname
    # ---------------------------------------------------------
    process
    {
        $ArchiveLogPathName = [string](Get-Date –f "yyyyMMdd-HHmmss")
        $ArchiveLogPathName = "C:\Logboek\Cleanup\CreateArchive-$ArchiveLogPathName.log"
        return $ArchiveLogPathName
    }
}

Function Invoke-ZipFileToArchive
{
    # ---------------------------------------------------------
    # Create single zip archive of a single file per file in a folder
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    Process
    {
        $Exitcode = $null
        Echo-Log "Creating archive per file in folder: $($CleanupParams.ObjectPath)"
        if (Test-Path $($CleanupParams.ObjectPath))
        {
            $FSOFolder = $($CleanupParams.ObjectPath)
            $FileObjects = Get-FilesByAge -Path $FSOFolder -Include $($CleanupParams.Include) -Age $($CleanupParams.Age)

            If ($FileObjects -ne $null)
            {
                $count = 0
                foreach ($FileObjectPath in $FileObjects)
                {
                    $count++
                    # Create file name without extension
                    $Basename = $FileObjectPath.DirectoryName + '\' + $FileObjectPath.Basename
                    if ($Basename)
                    {
                        # Add extension for archive file
                        $ZIPFile = $Basename + '.zip'

                        $FileObjectPath = Format-Path($FileObjectPath)
                        $ZipFile = Format-Path($ZipFile)

                        if ($Global:DEBUG)
                        {
                            Echo-Log "File to compress  : $FileObjectPath to $ZipFile"
                            Echo-Log "              to  : $ZipFile"
                        }

                        $Archlog = Format-ArchiveLogPathname
                        $CommandLineExe = $Global:ArchiveApplication
                        $CommandParams = "M -ep -ilog$Archlog -inul $ZipFile $FileObjectPath"

                        If ($Global:DEBUG -ne $true)
                        {
                            Echo-Log "Executing : $CommandLineExe"
                            Echo-Log "Parameters: $CommandParams"

                            #starts a process, waits for it to finish and then checks the exit code.
                            $p = Start-Process $CommandLineExe -ArgumentList $CommandParams -wait -NoNewWindow -PassThru
                            $HasExited = $p.HasExited
                            $Exitcode = $p.ExitCode

                            # Exit codes: See C:\Program Files\WinRAR\WinRAR.chm
                        }
                        else
                        {
                            Echo-Log "Executing : DEBUG $CommandLineExe"
                            Echo-Log "Parameters: DEBUG $CommandParams"
                        }
                    }
                }
            }
            if (($count -eq 0) -or ($FileObjects -eq $null))
            {
                Echo-Log "No file system objects to process in $($CleanupParams.ObjectPath)"
            }

            # Cleanup memory
            if ($FileObjects) { try { Remove-Variable -Name FileObjects -Scope Global -Force } catch { } }

        }
        else
        {
            Echo-Log "INFO: $($CleanupParams.ObjectPath) does not exist."
        }
        return $Exitcode
    }
}

Function Invoke-ZipSingleFiles
{
    # ---------------------------------------------------------
    # Create archive in history subfolder in a folder
    # and process each individual file into their own archive.
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    Process
    {
        $Exitcode = $null
        Echo-Log "Creating archive per file in folder: $($CleanupParams.ObjectPath)"
        if (Test-Path $($CleanupParams.ObjectPath))
        {
            # Create subfolder history if it does not exist
            $FSOFolder = $($CleanupParams.ObjectPath)

            $FSOHistory = $FSOFolder + '\history'
            if ((Test-Path $FSOHistory) -eq $False)
            {
                $result = [IO.Directory]::CreateDirectory($FSOHistory)
            }
            if (Test-Path $FSOHistory)
            {
                # $FileObjects = Files_ByAge -Path $CleanupParams.ObjectPath -Include $CleanupParams.Include -Exclude $FSOExclude -age_in_days $CleanupParams.Age -Recurse $Recurse
                $FileObjects = Get-FilesByAge -Path $FSOFolder -Include $($CleanupParams.Include) -Age $($CleanupParams.Age)
                If ($FileObjects -ne $null)
                {
                    $count = 0
                    foreach ($FileObjectPath in $FileObjects)
                    {
                        $count++
                        $Basename = $FileObjectPath.Basename
                        if ($Basename)
                        {
                            $ZIPFile = "$FSOHistory\$Basename.zip"

                            $FileObjectPath = Format-Path($FileObjectPath)
                            $ZipFile = Format-Path($ZipFile)

                            if ($Global:DEBUG) { Echo-Log "File to compress  : $FileObjectPath" }
                            if ($Global:DEBUG) { Echo-Log "Archive file      : $ZipFile" }

                            $Archlog = Format-ArchiveLogPathname
                            $CommandLineExe = $Global:ArchiveApplication
                            $CommandParams = "M -ep -ilog$Archlog -inul $ZipFile $FileObjectPath"

                            If ($Global:DEBUG -ne $true)
                            {
                                Echo-Log "Executing : $CommandLineExe"
                                Echo-Log "Parameters: $CommandParams"

                                #starts a process, waits for it to finish and then checks the exit code.
                                $p = Start-Process $CommandLineExe -ArgumentList $CommandParams -wait -NoNewWindow -PassThru
                                $HasExited = $p.HasExited
                                $Exitcode = $p.ExitCode

                                # Exit codes: See C:\Program Files\WinRAR\WinRAR.chm

                            }
                            else
                            {
                                Echo-Log "Executing : DEBUG $CommandLineExe"
                                Echo-Log "Parameters: DEBUG $CommandParams"
                            }
                        }
                    }
                }
                if (($count -eq 0) -or ($FileObjects -eq $null))
                {
                    Echo-Log "No file system objects to process in $($CleanupParams.ObjectPath)"
                }

                # Cleanup memory
                if ($FileObjects) { try { Remove-Variable -Name FileObjects -Scope Global -Force } catch { } }

            }
            else
            {
                Echo-Log "$Global:cErr ERROR: $FSOHistory could not be created."
            }
        }
        else
        {
            Echo-Log "INFO: $($CleanupParams.ObjectPath) does not exist."
        }
        return $Exitcode
    }
}

Function Invoke-ZipFilesAndFolders
{
    # ---------------------------------------------------------
    # Compress contents of a folder into a ZIP archive
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    $Exitcode = $null
    Echo-Log "Create archive from folder: $($CleanupParams.ObjectPath)"
    if (Test-Path $CleanupParams.ObjectPath)
    {
        if ($($CleanupParams.Include).Length -gt 0)
        {
            $CleanupParams.ObjectPath = $CleanupParams.ObjectPath + '\' + $CleanupParams.Include
        }
        else
        {
            $CleanupParams.ObjectPath += '\*.*'
        }

        $CleanupParams.ObjectPath = Format-Path($CleanupParams.ObjectPath)
        $CleanupParams.ZipFile = Format-Path($CleanupParams.ZipFile)

        if ($Global:DEBUG) { Echo-Log "(DEBUG) Archive file   : $($CleanupParams.ZipFile)" }
        if ($Global:DEBUG) { Echo-Log "(DEBUG) Max age        : $($CleanupParams.Age)" }
        if ($Global:DEBUG) { Echo-Log "(DEBUG) Action command : $($CleanupParams.ZipAction)" }

        # create shell and run command in RUNAS environment.
        $strMaxDate = (Get-Date).AddDays(0 - $CleanupParams.Age).ToString('yyyy-MM-dd')

        If ($strMaxDate.Length -gt 0)
        {
            $Archlog = Format-ArchiveLogPathname
            $CommandLineExe = $Global:ArchiveApplication
            $CommandParams = "$($CleanupParams.ZipAction) -tb$strMaxDate -ilog$Archlog -inul $($CleanupParams.ZipFile) $($CleanupParams.ObjectPath)"
        }

        If ($Global:DEBUG -ne $true)
        {
            Echo-Log "Executing : $CommandLineExe"

            #starts a process, waits for it to finish and then checks the exit code.
            $p = Start-Process $CommandLineExe -ArgumentList $CommandParams -wait -NoNewWindow -PassThru
            $HasExited = $p.HasExited
            $Exitcode = $p.ExitCode

            # Exit codes: See C:\Program Files\WinRAR\WinRAR.chm

        }
        else
        {
            Echo-Log "(DEBUG) Executing : $CommandLineExe"
            Echo-Log "(DEBUG) Parameters: $CommandParams"
        }
    }
    else
    {
        Echo-Log "INFO: $($CleanupParams.ObjectPath) does not exist."
    }

    return $Exitcode
}

Function Invoke-ZipSubFoldersOnly
{
    # ---------------------------------------------------------
    # Create archive per subfolder in a folder
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    Process
    {
        $Exitcode = $null
        Echo-Log "Create archive per subfolder in folder: $($CleanupParams.ObjectPath)"
        if (Test-Path $CleanupParams.ObjectPath)
        {
            # Create subfolder list of the folder. Age=null and no recursion.
            $FolderObjects = Get-FoldersByAge -Path $($CleanupParams.ObjectPath) -Recurse $False
            If ($FolderObjects -ne $null)
            {
                foreach ($SubFolderName in $FolderObjects)
                {
                    # Perform cleanup per subfolder.
                    $CleanupParams.ObjectPath = $SubFolderName
                    $SubFolderPath = $($SubFolderName.Fullname)
                    # Archive name
                    $ZIPfile = $SubFolderPath + "\archive.zip"
                    # Move files from a folder into a zip archive with subfolder recursion
                    $ZipParams = @{
                        ObjectPath = $SubFolderPath
                        Age        = $($CleanupParams.Age)
                        Include    = $($CleanupParams.Include)
                        ZipFile    = $ZipFile
                        ZipAction  = $($CleanupParams.ZipAction)
                    }
                    Invoke-ZipFilesAndFolders $ZipParams
                }
            }
            else
            {
                Echo-Log "No folders to process in $($CleanupParams.ObjectPath)"
            }

            # Cleanup memory
            if ($FolderObjects) { try { Remove-Variable -Name FolderObjects -Scope Global -Force } catch { } }
        }
        else
        {
            Echo-Log "INFO: $($CleanupParams.ObjectPath) does not exist."
        }
        return $Exitcode
    }
}

Function Invoke-ZipSAPAuditLogs
{
    # ---------------------------------------------------------
    # Create monthly zip archive of SAP audit logs
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        $CleanupParams
    )

    Process
    {
        $Exitcode = $null
        Echo-Log "Create monthly zip archive of SAP audit logs in folder: $($CleanupParams.ObjectPath)"
        if (Test-Path $CleanupParams.ObjectPath)
        {
            # Create subfolder list of the folder. Age=null and no recursion.
            $FolderObjects = Get-FoldersByAge -Path $($CleanupParams.ObjectPath) -Recurse $True
            # Select folders with folder name end with 'log'

            $FolderObjects = $FolderObjects | Where { $_.PSChildName -eq 'log' }
            If ($FolderObjects -ne $null)
            {
                foreach ($SubFolderName in $FolderObjects)
                {
                    # Perform cleanup per subfolder.
                    $CleanupParams.ObjectPath = $SubFolderName
                    $SubFolderPath = $($SubFolderName.Fullname)
                    # Archive name
                    $ArchiveName = Get-Date –f "yyyyMM"
                    $ZIPfile = $SubFolderPath + '\AUDIT_' + $ArchiveName + '.zip'
                    # Move files from a folder into a zip archive with subfolder recursion

                    $ZipParams = @{
                        ObjectPath = $SubFolderPath
                        Age        = $($CleanupParams.Age)
                        Include    = $($CleanupParams.Include)
                        ZipFile    = $ZipFile
                        ZipAction  = $($CleanupParams.ZipAction)
                    }

                    Invoke-ZipFilesAndFolders $ZipParams
                }
            }
            else
            {
                Echo-Log "No folders to process in $($CleanupParams.ObjectPath)"
            }

            # Cleanup memory
            if ($FolderObjects) { try { Remove-Variable -Name FolderObjects -Scope Global -Force } catch { } }
        }
        else
        {
            Echo-Log "INFO: $($CleanupParams.ObjectPath) does not exist."
        }
        return $Exitcode
    }
}

Function Invoke-CompressFolder
{
    # ---------------------------------------------------------
    # Create archive in history subfolder in a folder
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$ObjectPath
    )

    Process
    {
        $Exitcode = $null
        Echo-Log "Activating NTFS compression of folder: $ObjectPath"

        try
        {
            # Check if compression is already switched on
            $Compressed = Get-Item $ObjectPath | Where-Object { $_.Attributes -match 'Compressed' }
            if ($Compressed)
            {
                Echo-Log "Folder compression is already switched on."
            }
            else
            {
                Enable-NtfsCompression -Path $ObjectPath -Recurse
            }
        }
        catch
        {
            Echo-Log "$Global:cErr An error occured during NTFS compression on folder and files in $($ObjectPath)"
            Echo-Log "$Global:cErr Some files may have been in use while attempting to compress them."
            Echo-Log "$Global:cErr NTFS compression for this drive may be switched off."
        }
        return $Exitcode
    }
}

Function Invoke-DecompressFolder
{
    # ---------------------------------------------------------
    # Create archive in history subfolder in a folder
    # ---------------------------------------------------------
    [cmdletbinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$ObjectPath
    )

    Process
    {
        $Exitcode = $null
        Echo-Log "Removing NTFS compression of folder: $ObjectPath"

        try
        {
            # Check if compression is already switched on
            $Compressed = Get-Item $ObjectPath | Where-Object { $_.Attributes -match 'Compressed' }
            if ($Compressed)
            {
                Disable-NtfsCompression -Path $ObjectPath -Recurse
            }
            else
            {
                Echo-Log "Folder compression is already switched off."
            }
        }
        catch
        {
            Echo-Log "$Global:cErr Could not deactivate NTFS compression on folder $($ObjectPath)"
            Echo-Log "$Global:cErr Some files may have been in use while attempting to decompress them."
        }
        return $Exitcode
    }
}

# ---------------------------------------------------------
Initialize-Cleanup
# ---------------------------------------------------------

# ---------------------------------------------------------
# Export aliases
# ---------------------------------------------------------
export-modulemember -alias * -function *
