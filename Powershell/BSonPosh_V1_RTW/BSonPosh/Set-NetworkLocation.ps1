function Set-NetworkLocation
{
        
    <#
        .Synopsis 
            Sets the network(s) on the host.
            
        .Description
            Sets the network(s) on the host.
            
        .Parameter Category
            The Category to set the network(s) to. Valid Value: Public, Private, or Domain.
            
        .Parameter Name
            Name of the Network (default to all.) Uses RegEX.
            
        .Example
            Set-NetworkLocation -category Private
            Description
            -----------
            Sets Network Location to Private for all networks.
        
        .Example
            Set-NetworkLocation -category Private -Name MyNetwork
            Description
            -----------
            Sets Network Location to Private for MyNetwork.
            
        .OUTPUTS
            PSCustomObject
            
        .Link
            Get-NetworkLocation
            
        .Notes
            NAME:      Set-NetworkLocation
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Public", "Private", "Domain")]
        [String]$CATEGORY,
        
        [Parameter()]
        [string]$Name = ".*",
        
        [Parameter()]
        [switch]$Force
    )
    if([environment]::OSVersion.version.Major -lt 6) 
    {
        Write-Host "Network Location is only valid with Vista and above. Exiting" -ForegroundColor Yellow
        return 
    }
    
    # Skip network location setting if local machine is joined to a domain. 
    if(1,3,4,5 -contains (Get-WmiObject win32_computersystem).DomainRole) 
    {
        if(!$Force)
        {
            $yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
            $no  = new-Object System.Management.Automation.Host.ChoiceDescription "&No",""
            $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
            $caption = "Host is in a domain."
            $message = "Are you sure you want to continue?"
            $result = $host.ui.PromptForChoice($caption,$message,$choices,0)
            if($Result -eq 1){return}
        }
    } 
    
    try 
    {
        # Get network connections 
        $networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}")) 
        $connections = $networkListManager.GetNetworkConnections() | ?{$_.GetNetwork().GetName() -match $Name}
        
        # Set network location to Private for all networks 
        foreach($conn in $connections)
        {
            $ConnName = $conn.GetNetwork().GetName()
            if($PSCmdlet.ShouldProcess($CATEGORY,"Setting Network Location on $ConnName"))
            {
                switch ($CATEGORY)
                {
                    "Public"    {$conn.GetNetwork().SetCategory(0)}
                    "Private"    {$conn.GetNetwork().SetCategory(1)}
                    "Domain"    {$conn.GetNetwork().SetCategory(2)}
                }
            }
        }
        Get-NetworkLocation -Name $Name
    }
    catch
    {
        Write-Host "ERROR: $($Error[0])" -ForegroundColor Red
    }
}
    
