function Resolve-Host
{
        
    <#
        .Synopsis 
            Gets the DNS info for specified host.
            
        .Description
            Gets the DNS info for specified host.
            
        .Parameter ComputerName
            Name of the Computer to get the OS Version from (Default is localhost.)
    
        .Example
            Resolve-Host -Target MyServer
            Description
            -----------
            Gets DNS info from MyServer
            
        .Example
            $Servers | Resolve-Host
            Description
            -----------
            Gets DNS info for each machine in the pipeline
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            N/A
            
        .Notes
            NAME:      Resolve-Host
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    
    Begin 
    {
    
        $IPs = @{n="IP";e={$_.addresslist | %{$_.IPAddressToString}}}
        $IsUp = @{n="IsPingable";e={if($_.addresslist[0].IPAddressToString | Test-Host){$true}else{$false}}}
    
    }
    
    Process 
    {
    
        $IPHostEntry = [system.net.dns]::GetHostEntry($ComputerName)
        $IPHostEntry | select HostName,$IPs,$IsUp
    
    }
}
    
