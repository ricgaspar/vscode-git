function Get-TraceFile
{
        
    <#
        .Synopsis
            Gets Data from a tracelog.exe using tracerpt.exe
        
        .Description
            Gets Data from a tracelog.exe using tracerpt.exe
            
        .Parameter Source
            The Tracelog file to convert (.etl) Default $pwd\Logfile.etl
        
        .Parameter File
            The name of the CSV file to Export to. Default TraceResults.csv.
        
        .Parameter CSV 
            [SWITCH] :: Returns the file created
            
        .Example
            Get-TraceFile
            Description
            -----------
            Gets a tracefile called $pwd\LogFile.Etl
        
        .Example
            Get-TraceFile -Source C:\temp\MyLogFile.Etl
            Description
            -----------
            Gets a tracefile called C:\temp\MyLogFile.Etl
            
        .OUTPUTS
            PSCustomObject
    
        .Notes
            NAME:      Test-LDAPFilter
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [parameter()]
        $Source="$pwd\LogFile.Etl",
        
        [parameter()]
        $file="$pwd\TraceResults.csv",
        
        [parameter()]
        [switch]$csv
        
    )
    
    if(Test-Path $pwd\tracelog.exe)
    {
        $tracerpt = "$pwd\tracerpt.exe"
    }
    elseif(get-command tracelog.exe)
    {
        $tracerpt = "tracerpt.exe"
    }
    else
    {
        throw "Missing tracerpt.exe"
        return 1
    }
    
    
    $cmd = "$tracerpt $Source -o $file -of CSV"
    
    invoke-Expression $cmd
    
    if($csv)
    {
        Write-Host "CSV File [ $file ] Created!"
        get-chiditem $file
    }
    else
    {
        import-csv $file
    }
}
    
