function Get-FileMD5
{
        
    <#
        .Synopsis 
            Gets the MD5 hash of the file(s).
            
        .Description
            Gets the MD5 hash of the file(s) using the ComputeHash() method of System.Security.Cryptography.MD5CryptoServiceProvider.
            
        .Parameter Path
            Path to the file to caculate hash for.
            
        .Example
            Get-FileMD5 c:\temp\myfile.ps1
            Description
            -----------
            Gets the MD5 hash for the file c:\temp\myfile.ps1
    
        .Example
            dir c:\temp\myscripts | Get-FileMD5 
            Description
            -----------
            Gets the MD5 hash for all the files in c:\temp\myscripts
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
        
        .Notes
            NAME:      Get-FileMD5
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [CmdletBinding()]
    Param(
    
        [alias("FullName")]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Mandatory=$true)]
        [string]$Path
        
    )
    Process 
    {
        Write-Verbose " [Get-FileMD5] :: Start Process"
        $Parent = Split-Path $Path -Parent
        $File = Split-Path $Path -Leaf
        
        if($Parent -and ($Parent -ne "."))
        {
            Write-Verbose " [Get-FileMD5] :: Parent Folder = $Parent"
            $FilePath = $path
        }
        else
        {
            Write-Verbose " [Get-FileMD5] :: No Parent found. Using current Path"
            $FilePath = "$pwd\$File"            
        }
        
        Write-Verbose " [Get-FileMD5] :: Using $FilePath"
    
        try
        {
            Write-Verbose " [Get-FileMD5] :: Getting Handle to file"
            $mode = [System.IO.FileMode]("open")
            $item = Get-Item $FilePath
            
            if($item -is [System.IO.FileInfo])
            {
                $md5 = New-Object System.Security.Cryptography.MD5CryptoServiceProvider
                Write-Verbose " [Get-FileMD5] :: Opening File Stream"
                $fs = $item.Open($mode)
                
                Write-Verbose " [Get-FileMD5] :: Getting MD5"
                $MD5Hash = ($md5.ComputeHash($fs) | %{$_.ToString("x").ToUpper()}) -join ""
                
                Write-Verbose " [Get-FileMD5] :: Closing file"
                $fs.Close()
                
                Write-Verbose " [Get-FileMD5] :: Returning MD5 object"
                $myobjProperties = @{}
                $myobjProperties.Path = $Path
                $myobjProperties.MD5 = $MD5Hash
    
                $obj = New-Object PSObject -Property $myobjProperties
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.MD5Hash')
                $obj
            }
        }
        catch
        {
            $myobjProperties.Hash = "Unable to open file $FilePath"
            Write-Host "Unable to open file $FilePath. Error: $($Error[0])."
            Continue
        }
        
        Write-Verbose " [Get-FileMD5] :: End Process"
    
    }
}
    
