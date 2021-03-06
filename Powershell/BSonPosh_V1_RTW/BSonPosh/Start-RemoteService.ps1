function Start-RemoteService 
{
        
    <#
        .Synopsis 
            Starts a Remote Service
            
        .Description
            Starts a Service and all dependant services (if any)
            
        .Parameter ServiceName
            The name of the service to start
            
        .Parameter ComputerName
            The Computer you want to start the service on (default is localhost)
            
        .Example
            Start-RemoteService -ServiceName dnscache -computername MyServer1
            Description
            -----------
            Starts dnscache on MyServer1
            
        .OUTPUTS
            System.ServiceProcess.ServiceController
            
        .Link
            N/A
            
        .Notes
            NAME:      Start-RemoteService 
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
        [Parameter(mandatory=$true)]
        [string]$ServiceName,
        
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Process 
    {
    
        Write-Verbose " [Start-RemoteService] :: Starting Service [$ServiceName] on Computer [$ComputerName]"
        $ScriptBlock = { Param($name) Start-Service $name }
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $ServiceName
    
    }
}
    
