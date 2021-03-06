function Stop-RemoteService
{
        
    <#
        .Synopsis 
            Stops a Remote Service
            
        .Description
            Stops a Service and all dependant services (if any)
            
        .Parameter ServiceName
            The name of the service to stop
            
        .Parameter ComputerName
            The Computer you want to stop the service on (default is localhost)
            
        .Example
            Stop-RemoteService -ServiceName dnscache -computername MyServer1
            Description
            -----------
            Stops dnscache on MyServer1
            
            
        .OUTPUTS
            System.ServiceProcess.ServiceController
            
        .Link
            N/A
            
        .Notes
            NAME:      Stop-RemoteService 
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            LASTEDIT:  04/20/2010 18:25:15
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
        [switch]$Force
    )
    Process 
    {
    
        Write-Verbose " [Stop-RemoteService] :: Stopping Service [$ServiceName] on Computer [$ComputerName]"
        $ScriptBlock =  { Param($name,$Force) Stop-Service $name -Force:$Force }
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $ServiceName,$Force
    
    }
}
    
