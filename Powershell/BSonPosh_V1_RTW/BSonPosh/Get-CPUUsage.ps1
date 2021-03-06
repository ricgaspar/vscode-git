function Get-CPUUsage
{
        
    <#
        .Synopsis 
            Gets the CPU usage for specified host.
            
        .Description
            Gets the CPU usage for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the CPU Usage from (Default is localhost.)
            
        .Example
            Get-CPUUsage
            Description
            -----------
            Gets CPU usage from local machine
    
        .Example
            Get-CPUUsage -ComputerName MyServer
            Description
            -----------
            Gets CPU usage from MyServer
            
        .Example
            $Servers | Get-CPUUsage
            Description
            -----------
            Gets CPU usage for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .Notes
            NAME:      Get-CPUUsage
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
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
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            try
            {
                $CPUs = Get-WmiObject Win32_PerfFormattedData_PerfOS_Processor -comp $ComputerName -ea STOP -Filter "Name!='_Total'"
                
                foreach($CPU in $CPUs)
                {
                    $myobj = @{}
                    $myobj.ComputerName   = $ComputerName
                    $myobj.CPU            = $CPU.Name
                    $myobj.Idle           = $CPU.PercentIdleTime
                    $myobj.Interrupt      = $CPU.PercentInterruptTime
                    $myobj.Privileged     = $CPU.PercentPrivilegedTime
                    $myobj.Processor      = $CPU.PercentProcessorTime
                    $myobj.User           = $CPU.PercentUserTime
                
                    $obj = New-Object PSObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.CPUUsage')
                    $obj
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
    
