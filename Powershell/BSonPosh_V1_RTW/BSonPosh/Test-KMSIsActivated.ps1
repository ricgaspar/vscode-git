function Test-KMSIsActivated 
{
        
    <#
        .Synopsis 
            Test machine for activation.
            
        .Description
            Test machine for activation.
            
        .Parameter ComputerName
            Name of the Computer to test activation on (Default is localhost.)
            
        .Example
            Test-KMSIsActivated
            Description
            -----------
            Test activation on local machine
    
        .Example
            Test-KMSIsActivated -ComputerName MyServer
            Description
            -----------
            Test activation on MyServer
            
        .Example
            $Servers | Test-KMSIsActivated
            Description
            -----------
            Test activation for each machine in the pipeline
            
        .OUTPUTS
            Object
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Test-KMSIsActivated
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
    
        Write-Verbose " [Test-KMSActivation] :: Process start"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        Write-Verbose " [Test-KMSActivation] :: ComputerName = $ComputerName"
        if(Test-Host $ComputerName -TCP 135)
        {
            Write-Verbose " [Test-KMSActivation] :: Process start"
            $status = Get-KMSStatus -ComputerName $ComputerName
            if($status.Status -eq "Licensed")
            {
                $_
            }
        }
    
    }
}
    
