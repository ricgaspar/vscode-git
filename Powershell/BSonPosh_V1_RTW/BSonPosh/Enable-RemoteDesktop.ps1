function Enable-RemoteDesktop
{
    
    <#
        .Synopsis 
            Enables Remote Desktop Setting.
            
        .Description
            Enables Remote Desktop Setting.
            
        .Parameter ComputerName
            Computer to get the setting from (Default to localhost.)
            
        .Example
            Enable-RemoteDesktop 
            Description
            -----------
            Enables local Remote Desktop Setting 
            
        .Example
            Enable-RemoteDesktop -ComputerName MyComputer
            Description
            -----------
            Enables Remote Desktop Setting on MyComputer
            
        .OUTPUTS
            PSCustomObject
            
        .Link
            Get-RemoteDesktop
            Disable-RemoteDesktop
            
        .Notes
            NAME:      Get-RemoteDesktop
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
            if($PSCmdlet.ShouldProcess($ComputerName,"Enabling Remote Desktop"))
            {
                Set-RegistryValue -ComputerName $ComputerName `
                                -Path "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                                -Name fDenyTSConnections    `
                                -Value 0                    `
                                -Type DWord
                Set-RegistryValue -ComputerName $ComputerName `
                                -Path "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                                -Name AllowTSConnections    `
                                -Value 1                    `
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
    
