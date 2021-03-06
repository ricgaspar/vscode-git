function Test-Is64Bit 
{
        
    <#
        .Synopsis 
            Tests the OS for x64 support on the specified host.
            
        .Description
            Tests the OS for x64 support on the specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the OS Version from (Default is localhost.)
            
        .Parameter PassThru
            If test is passed the object is passed on.
            
        .Example
            Test-Is64Bit
            Description
            -----------
            Returns $True if the local host is 64bit
    
        .Example
            Test-Is64Bit -ComputerName MyServer
            Description
            -----------
            Returns $True if MyServer is 64bit
            
        .Example
            $Servers | Test-Is64Bit -passthru
            Description
            -----------
            Passes on Objects that pass the 64 bit test.
            
        .OUTPUTS
            Boolean
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Test-Is64Bit
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME,
        
        [Parameter()]
        [switch]$passthru
    )
    Process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        $Query = "Select AddressWidth from Win32_Processor WHERE AddressWidth=64"
        if(Test-Connection $ComputerName -ea 0)
        {
            $result = Get-WmiObject -Query $Query -ComputerName $ComputerName
            if($result)
            {
                if($passthru){$_}else{$true}
            }
            else
            {
                $false
            }
        }
        else
        {
            Write-Host "Unable to ping [$ComputerName]" -ForegroundColor Red -BackgroundColor Black
        }
    
    }
}
    
