function Test-Service
{
        
    <#
        .Synopsis 
            Test a Service.
    
        .Description
            Test a Service.
    
        .Parameter ServiceName
            The name of the service to test
    
        .Parameter ComputerName
            The Computer you want to test the service on (default is localhost)
    
        .Example
            Test-Service -ServiceName dnscache -computername MyServer1
            Description
            -----------
            Test service to see if it is started
    
        .OUTPUTS
            [bool]
    
        .Link
            N/A
    
        .Notes
            NAME:      Test-Service
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            LASTEDIT:  03/16/2009 18:25:15
        #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(mandatory=$true)]
        [string]$ServiceName,
    
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Begin 
    {
        Write-Verbose " [Test-Service] :: ServiceName = $ServiceName"
    }
    
    Process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            Write-Verbose " [Test-Service] :: ComputerName = $ComputerName"
            try
            {
                $Service = Get-Service -Name $ServiceName -ComputerName $ComputerName 
                Write-Verbose " [Test-Service] :: $Service in State [$($Service.Status)]"
                if($Service -and ($Service.Status -eq "Running"))
                {
                    $True
                }
                else
                {
                    $False
                }
            }
            catch
            {
                Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
            }
        }
        else
        {
            Write-Host " Host [$ComputerName] Failed Connectivity Test " -ForegroundColor Red
        }
    
    }
}
    
