function New-TempFile
{
    
    <#
        .Synopsis 
            Creates a temp file to store data.
            
        .Description
            Creates a temp file to store data.
            
        .Parameter Server
            Name of the Server to Process.
            
        .Example
            New-Tempfile
            Description
            -----------
            Creates a Temp in the default temp folder
            
        .Example
            New-Tempfile c:\temp
            Description
            -----------
            Creates Temp file in C:\temp
            
    .OUTPUTS
            System.IO.FileInfo
            
        .INPUTS
            System.String
        
        NAME:      New-TempFile
        AUTHOR:    YetiCentral\bshell
        Website:   www.bsonposh.com
        #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    param (
        [Parameter()]
        [string]$Path = [environment]::GetEnvironmentVariable("TEMP")
    )
    if(!(Test-Path -Path $path)){New-Item -ItemType Directory -Path $Path}
    
    $FileName = [System.IO.Path]::GetRandomFileName()
    
    $file = Join-Path -Path $Path -ChildPath $FileName
    
    New-Item -ItemType File -Path $file
}
    
