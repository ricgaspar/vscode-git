function Disable-RemoteDesktop
{
        
    <#
        .Synopsis 
            Disables Remote Desktop Setting.
            
        .Description
            Disables Remote Desktop Setting.
            
        .Parameter ComputerName
            Computer to get the setting from (Default to localhost.)
            
        .Example
            Disable-RemoteDesktop 
            Description
            -----------
            Disables local Remote Desktop Setting 
            
        .Example
            Disable-RemoteDesktop -ComputerName MyComputer
            Description
            -----------
            Disables Remote Desktop Setting on MyComputer
            
        .OUTPUTS
            PSCustomObject
            
        .Link
            Get-RemoteDesktop
            Enable-RemoteDesktop
            
        .Notes
            NAME:      Disable-RemoteDesktop
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
        [Alias("Server")]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:ComputerName
    )
    
    Process 
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host -ComputerName $ComputerName)
        {
            if($PSCmdlet.ShouldProcess($ComputerName,"Disabling Remote Desktop"))
            {
                Set-RegistryValue -ComputerName $ComputerName `
                                -Path "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                                -Name fDenyTSConnections    `
                                -Value 1                    `
                                -Type DWord
                Set-RegistryValue -ComputerName $ComputerName `
                                -Path "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                                -Name AllowTSConnections    `
                                -Value 0                    `
                                -Type DWord
            }
            Get-RemoteDesktop -ComputerName $ComputerName
        }
        else
        {
            Write-Host "Unable to Ping $ComputerName"
        }
        
    }
}
    
