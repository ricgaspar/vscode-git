Import-Module VNB_PSLib -Force -ErrorAction SilentlyContinue


function Get-SysInternals
{
    
    <#
        .Synopsis 
            List or updates sysinternal files from the internet
            
        .Description
            List or updates sysinternal files from the internet
            
        .Parameter Path
            Where you want the files to download to.
            
        .Parameter FileName
            The FileName you want to download
            
        .Parameter All
            Updates all the Files
            
        .Parameter Passthru
            Returns a FileInfo Object for the downloaded file
            
        .Example
            Get-SysInternals
            Description
            -----------
            To see a list of available files from Sysinternals
            
        .Example 
            Get-SysInternals -FileName pslist.exe
            Description
            -----------
            To download a single file
            
        .Example
            Get-SysInternals -All
            Description
            -----------
            To download all the files available
            
        .Example 
            Get-ChildItem C:\tools | Get-SysInternals
            Description
            -----------
            To download only files you already have
            
        .OUTPUTS
            Object
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-SysInternals
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            LASTEDIT:  03/16/2009 18:25:15
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
        [parameter()]
        $Path,
        [parameter(ValueFromPipeLine=$true)]
        $FileName,
        [parameter()]
        [switch]$All,
        [parameter()]
        [switch]$Passthru
    )
    
    Begin 
    {
    
        if(!$Path)
        {
            $CommandPath = (Get-command pslist.exe -ErrorAction 0).Path
            if($CommandPath -and (Test-Path $CommandPath))
            {
                $path = split-path $CommandPath -parent -ErrorAction 0
            }
            else
            {
                $path = Read-Host "Enter Path"
            }
        }
        
        Write-Verbose " Path: $Path"
        Write-Verbose " FileName: $FileName"
        write-verbose " ALL: $ALL"
        $Cont = $true
        
    }
    
    Process 
    {
    
        if($FileName)
        {
            Try
            {
                Write-Verbose " Downloading File [$FileName]"
                $webclient.DownloadFile("http://live.sysinternals.com/$FileName","$path\$FileName")
                Write-Verbose " ==> Downloaded [$FileName]"
                if($passthru){Get-Item "$path\$FileName"}
            }
            catch
            {
                Write-Verbose " Failed to Download File [$FileName]"
            }
            $cont = $false
        }
    
    }
    
    End 
    {
    
        if($Cont)
        {
            # Get file content
            $webclient = New-Object System.Net.WebClient
            $HTML = $webclient.DownloadString("http://live.sysinternals.com/") 
            $links = $HTML -split "<br>"
            $Files = @()
            
            # Building RegEx
            $regex = "^.*y,\s(?<DATE>.*)(AM|PM)"
            $regex += "\s*(?<Length>\d*)\s+\"
            $regex += "<A HREF=\`"/.*\`">(?<filename>.*)\</A\>"
            
            # Creating an Object from the Links
            switch -regex ($links)
            {
                $regex
                { 
                    $myobj = "" | Select FileName,Date,Length
                    $myobj.FileName += $matches.FileName
                    $myobj.Date = get-date $matches.Date
                    $myobj.Length = $matches.Length
                    $files += $myobj         
                }
            }
            
            if($All)
            {
                foreach($file in $files)
                {
                    $FileName = $file.FileName
                    Try
                    {
                        Write-Verbose " Downloading File [$FileName] to [$Path]"
                        $webclient.DownloadFile("http://live.sysinternals.com/$FileName","$path\$FileName")
                        Write-Verbose " ==> Downloaded [$FileName]"
                        if($passthru){Get-Item "$path\$FileName"}
                    }
                    catch
                    {
                        Write-Verbose " Failed to Download File [$File]"
                    }
                }
            }
            else
            {
                $files
            }
        }
    
    }

}


$CurDate = Get-Date -f "yyyy-MM-dd"
$DownloadPath = "C:\Scripts\SysInternals\Download\$Curdate"
New-FolderStructure $DownloadPath

# Get-SysInternals -Path $DownloadPath -All

$Files = Get-FilesByAge -FolderPath $DownloadPath
$CRCLog = $DownloadPath + '\CRC32.log'
$CRCLog
if([IO.File]::Exists($CRCLog)) { 
    Foreach($FilePath in $Files) {
        $CRCFilePath = $DownloadPath + '\' + $FilePath.Name
        $CRC32 = Get-Crc32 $CRCFilePath    
        "$($FilePath.Name) $CRC32" | Out-File -filepath $CRCLog -NoClobber -Append
        "$($FilePath.Name) $CRC32"
    }    
} else {
}