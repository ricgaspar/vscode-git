function Get-NetworkLocation
{
        
    <#
        .Synopsis 
            Gets the network(s) on the host.
            
        .Description
            Gets the network(s) on the host.
            
        .Parameter Name
            Name of the Network (default to all.) Uses RegEX.
            
        .Example
            Get-NetworkLocation
            Description
            -----------
            Gets Network Location for all networks
        
        .Example
            Get-NetworkLocation -Name MyNetwork
            Description
            -----------
            Gets Network Location for MyNetwork
            
        .OUTPUTS
            PSCustomObject
            
        .Link
            Set-NetworkLocation
            
        .Notes
            NAME:      Get-NetworkLocation
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            LASTEDIT:  11/03/2009 
            #Requires -Version 2.0
    #>
        
    [Cmdletbinding()]
    Param(
        [Parameter()]
        [string]$Name = ".*"
    )
    
    function ConvertTo-NetworkLocation($CATEGORY)
        {
            switch ($CATEGORY)
            {
                0    {"Public"}
                1    {"Private"}
                2    {"Domain"}
            }
        }
        
    # Skip network location setting for pre-Vista operating systems 
    if([environment]::OSVersion.version.Major -lt 6) { return } 
    try
    {
        # Get network connections 
        $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}")) 
        $connections = $networkListManager.GetNetworkConnections() | ?{$_.GetNetwork().GetName() -match $Name}
        
        # Get network location to Private for all networks 
        foreach($conn in $connections)
        {
            $myobj = @{}
            $myobj.Network = ($conn.GetNetwork().GetName()) 
            $myobj.Category = (ConvertTo-NetworkLocation ($conn.GetNetwork().GetCategory()))
    
            $obj = New-Object PSObject -Property $myobj
            $obj.PSTypeNames.Clear()
            $obj.PSTypeNames.Add('BSonPosh.NetworkLocation')
            $obj
        }
    }
    catch
    {
        Write-Host "ERROR: $($Error[0])" -ForegroundColor Red
    }
}
    
