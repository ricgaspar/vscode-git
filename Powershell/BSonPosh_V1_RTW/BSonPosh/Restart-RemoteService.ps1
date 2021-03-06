function Restart-RemoteService 
{
        
    <#
        .Synopsis 
            Restarts a Service
            
        .Description
            Restarts a Service and all dependant services (if any)
            
        .Parameter ServiceName
            The name of the service to restart
            
        .Parameter ComputerName
            The Computer you want to restart the service on (default is localhost)
            
        .Parameter WaitTime
            How long to wait before giving up. (Default 5min)
            
        .Example
            Restart-RemoteService -ServiceName dnscache -computername MyServer1
            Description
            -----------
            Restarts dnscache on server MyServer1
            
        .OUTPUTS
            System.ServiceProcess.ServiceController
            
        .Link
            N/A
            
        .Notes
            NAME:      Restart-RemoteService 
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
        #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(mandatory=$true)]
        [string]$ServiceName,
        
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME,
        
        [Parameter()]
        [int]$WaitTime = 300
    )
    
    Begin 
    {
    
        function Get-Dependents
        {
            Param([System.ServiceProcess.ServiceController]$MasterService)
            Write-Verbose " [Get-Dependents] ::          + Getting Dependent Services for $($MasterService.Name)"
            foreach($dependent in $MasterService.DependentServices)
            {
                if($dependent)
                {
                    Write-Verbose " [Get-Dependents] ::            - Found Dependent Service [$($dependent.Name)]"
                    $dependent
                    Get-Dependents $dependent
                }
            }
        }
        
        [system.Reflection.Assembly]::LoadWithPartialName("System.ServiceProcess") | out-Null
        $ErrorActionPreference = "SilentlyContinue"
        Write-Verbose " [Restart-RemoteService] :: ServiceName = $ServiceName"
    
    }
    
    Process
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host $ComputerName -TCPPort 135)
        {
            Write-Verbose " [Restart-RemoteService] :: ComputerName = $ComputerName"
            try
            {
                Write-Verbose " [Restart-RemoteService] :: - Getting Service [$ServiceName]"
                $Service = New-Object System.ServiceProcess.ServiceController($ServiceName,$ComputerName)
        
                Write-Verbose " [Restart-RemoteService] :: - Getting Dependent Services"
                $DependentServices = Get-Dependents $Service
                
                try
                {
                    if($Service.State -ne "Stopped")
                    {
                        Write-Verbose " [Restart-RemoteService] :: + Stopping [$ServiceName] and dependent Services"
                        $Service.Stop()
                    }
                }
                catch
                {
                    Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
                    continue
                }
        
                try
                {
                    Write-Verbose " [Restart-RemoteService] ::   - Waiting for Service to Stop (${WaitTime}sec)"
                    $Service.WaitForStatus("Stopped",(new-object System.TimeSpan(0,0,$WaitTime)))
                }
                catch
                {
                    Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
                    continue
                }
                
                try
                {
                    if($Service.State -ne "Running")
                    {
                        Write-Verbose " [Restart-RemoteService] :: + Starting [$ServiceName]"
                        $Service.Start()
                    }
                }
                catch
                {
                    Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
                    continue
                }
        
                try
                {
                    Write-Verbose " [Restart-RemoteService] ::   - Waiting for Service $($Service.Name) to Start (${WaitTime}sec)"
                    $Service.WaitForStatus("Running",(new-object System.TimeSpan(0,0,$WaitTime)))
                }
                catch
                {
                    Write-Host " Host [$ComputerName] Failed with Error: $($Error[0])" -ForegroundColor Red
                    continue
                }
        
                if($DependentServices)
                {
                    Write-Verbose " [Restart-RemoteService] ::   - Starting Dependant Services"
                    foreach($dependent in $DependentServices)
                    {
                        $dependent.Refresh()
                        if($dependent.status -eq "Stopped")    
                        {
                            $dependent.Start()
                            Write-Verbose " [Restart-RemoteService] ::     - Waiting for Service [$($Dependent.Name)] to Start (${WaitTime}sec)"
                            $dependent.WaitForStatus("Running",(new-object System.TimeSpan(0,0,$WaitTime)))
                        }
                    }
                }
                $Service.Refresh()
                $Service
                $Service.DependentServices
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
    
