function Select-LargeFile
{
        
    <#
        .Synopsis 
            Returns files that match the size specified.
            
        .Description
            Returns files that match the size specified.
            
        .Parameter Size
            The size to check (default 100mb.)
            
        .Parameter Path
            The Path to the file(s) to check
            
        .Parameter Recurse
            Does recursive search.
            
        .Example
            Select-LargeFile -path c:\data
            Description
            -----------
            Selects all the files larger than 100mb in the root of c:\data
            
        .Example
            Select-LargeFile -path c:\data -recurse
            Description
            -----------
            Selects all the files larger than 100mb contained in c:\data recursively
            
        .Example
            dir c:\data | Select-LargeFile -size 1gb
            Description
            -----------
            Selects all the files larger than 1gb in the root of c:\data
            
        .OUTPUTS
            System.IO.FileInfo
            
        .Notes
            NAME:      Select-LargeFile
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
    
        [Parameter()]
        [int]$size = 100mb,
        
        [alias('FullName')]
        [Parameter(ValueFromPipelineByPropertyName =$true)]
        [string]$Path,
    
        [Parameter()]
        [switch]$recurse
    
    )
    Process 
    {
    
        Write-Verbose "Path : $path"
        if($recurse)
        {
            foreach($file in (get-childitem $path -rec | where-object{(!$_.PSisContainer) -and ($_.Length -ge $size)}))
            {
                $FileSize = ("{0:n2}MB" -f ($file.length/1mb))
                $file | add-member -Name FileSize -MemberType noteproperty -Value $FileSize
                $file
            }
        }
        else
        {
            foreach($file in (get-item $path | where-object{(!$_.PSisContainer) -and ($_.Length -ge $size)}))
            {
                $FileSize = ("{0:n2}MB" -f ($file.length/1mb))
                $file | add-member -Name FileSize -MemberType noteproperty -Value $FileSize
                $file
            }
        }
            
    
    }
}
    
