function Wait-Port
{
        
    <#
        .Synopsis
            Waits for a Port to Open.
            
        .Description
            Waits for a Port to Open.
                        
        .Parameter TCPPort 
            Port to wait for (Default 135.)
            
        .Parameter Timeout 
            How long to wait (in seconds) for the TCP connection (Default 30.)
            
        .Parameter ComputerName 
            Computer to check the port against (Default in localhost.)
            
        .Example
            Wait-Port -tcp 3389
            Description
            -----------
            Waits localhost is listening on 3389
            
        .Example
            Wait-Port -tcp 3389 -ComputerName MyServer1
            Description
            -----------
            Waits until MyServer1 is listening on 3389
                    
        .OUTPUTS
            $Null
            
        .INPUTS
            System.String
            
        .Link
            Test-Host
            Test-Port
        
        .Notes
            NAME:      Wait-Port
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    [cmdletbinding()]
    Param(
    
        [Parameter()]
        [int]$TCPPort,
        
        [Parameter()]
        [int]$Timeout=30,
        
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Begin 
    {
    
        Write-Verbose " [Wait-Port] :: Start Begin"
        Write-Verbose " [Wait-Port] :: Port   : $Port"
        Write-Verbose " [Wait-Port] :: Timeout: $Timeout"
        Write-Verbose " [Wait-Port] :: End Begin"
    
    }
    
    Process 
    {
    
        Write-Verbose " [Wait-Port] :: Start Process" 
        for($i = 0 ; $i -lt $Timeout ; $i++)
        {
            $return = Test-Port -ComputerName $ComputerName -TCPport $TCPPort -TimeOut 1000
            if($return)
            {
                return
            }
            else
            {
                Start-Sleep    1
            }
        }
        Write-Verbose " [Wait-Port] :: TIMEOUT"
        Write-Verbose " [Wait-Port] :: End Process"
    
    }
}
    
