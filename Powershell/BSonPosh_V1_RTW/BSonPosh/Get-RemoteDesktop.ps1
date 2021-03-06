function Get-RemoteDesktop
{
    
    <#
        .Synopsis 
            Gets the value of Remote Desktop Setting.
            
        .Description
            Gets the value of Remote Desktop Setting.
            
        .Parameter ComputerName
            Computer to get the setting from (Default to localhost.)
            
        .Example
            Get-RemoteDesktop 
            Description
            -----------
            Gets local Remote Desktop Setting 
            
        .Example
            Get-RemoteDesktop -ComputerName MyComputer
            Description
            -----------
            Gets Remote Desktop Setting on MyComputer
        
        .OUTPUTS
            PSCustomObject
            
        .Link
            Enable-RemoteDesktop
            Disable-RemoteDesktop
            
        .Notes
            NAME:      Get-RemoteDesktop
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            LASTEDIT:  11/03/2009 
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Alias("Server")]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:ComputerName
    )
    
    Begin
    {
        $TSKey = "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server"
    }
    
    Process
    {
    
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        if(Test-Host -ComputerName $ComputerName)
        {
            $DenyKey = Get-RegistryValue -ComputerName $ComputerName -Path $TSKey -Name fDenyTSConnections
            $AllowKey = Get-RegistryValue -ComputerName $ComputerName -Path $TSKey -Name AllowTSConnections
            if(($DenyKey.Value -eq 0) -or ($AllowKey.Value -eq 1))
            {
                $Enabled = $true
            }
            else
            {
                $Enabled = $false
            }
            
            $myobj = @{
                ComputerName         = $ComputerName
                DenyTSConnections    = $DenyKey.Value
                AllowTSConnections   = $AllowKey.Value
                RemoteDesktopEnabled = $Enabled
            }
            
            $obj = New-Object PSObject -Property $myobj
            $obj.PSTypeNames.Clear()
            $obj.PSTypeNames.Add('BSonPosh.RemoteDesktop.State')
            $obj
        }
        else
        {
            Write-Host "Unable to Ping $ComputerName"
        }
    
    }
}
    
