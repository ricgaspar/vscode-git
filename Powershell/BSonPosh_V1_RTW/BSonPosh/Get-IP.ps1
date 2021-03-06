function Get-IP
{
        
    <#
        .Synopsis 
            Get the IP of the specified host.
            
        .Description
            Get the IP of the specified host.
            
        .Parameter ComputerName
            Name of the Computer to get IP (Default localhost.)
                
        .Example
            Get-IP
            Description
            -----------
            Get IP information the localhost
            
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
        
        .Notes
            NAME:      Get-IP
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
        $NICs = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled='$True'" -ComputerName $ComputerName
        foreach($Nic in $NICs)
        {
            $myobj = @{
                Name          = $Nic.Description
                MacAddress    = $Nic.MACAddress
                IP4           = $Nic.IPAddress | where{$_ -match "\d+\.\d+\.\d+\.\d+"}
                IP6           = $Nic.IPAddress | where{$_ -match "\:\:"}
                IP4Subnet     = $Nic.IPSubnet  | where{$_ -match "\d+\.\d+\.\d+\.\d+"}
                DefaultGWY    = $Nic.DefaultIPGateway | Select -First 1
                DNSServer     = $Nic.DNSServerSearchOrder
                WINSPrimary   = $Nic.WINSPrimaryServer
                WINSSecondary = $Nic.WINSSecondaryServer
            }
            $obj = New-Object PSObject -Property $myobj
            $obj.PSTypeNames.Clear()
            $obj.PSTypeNames.Add('BSonPosh.IPInfo')
            $obj
        }
    }
}
    
