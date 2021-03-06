function Test-KMSSupport 
{
        
    <#
        .Synopsis 
            Test machine for KMS Support.
            
        .Description
            Test machine for KMS Support.
            
        .Parameter ComputerName
            Name of the Computer to test KMS Support on (Default is localhost.)
            
        .Example
            Test-KMSSupport
            Description
            -----------
            Test KMS Support on local machine
    
        .Example
            Test-KMSSupport -ComputerName MyServer
            Description
            -----------
            Test KMS Support on MyServer
            
        .Example
            $Servers | Test-KMSSupport
            Description
            -----------
            Test KMS Support for each machine in the pipeline
            
        .OUTPUTS
            Object
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Test-KMSSupport
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
        
    )
    
    Process 
    {
        Write-Verbose " [Test-KMSSupport] :: Process start"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        Write-Verbose " [Test-KMSSupport] :: Testing Connectivity"
        if(Test-Host -ComputerName $ComputerName -TCPPort 135)
        {
            $Query = "Select __CLASS FROM SoftwareLicensingProduct"
            try
            {
                Write-Verbose " [Test-KMSSupport] :: Running WMI Query"
                $Result = Get-WmiObject -Query $Query -ComputerName $ComputerName
                Write-Verbose " [Test-KMSSupport] :: Result = $($Result.__CLASS)"
                if($Result)
                {
                    Write-Verbose " [Test-KMSSupport] :: Return $_"
                    $_
                }
            }
            catch
            {
                Write-Verbose " [Test-KMSSupport] :: Error: $($Error[0])"
            }
        }
        else
        {
            Write-Verbose " [Test-KMSSupport] :: Failed Connectivity Test"
        }
    
    }
}
    
