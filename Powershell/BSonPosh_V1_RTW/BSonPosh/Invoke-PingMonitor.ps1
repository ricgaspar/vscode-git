function Invoke-PingMonitor
{
    
    <#
        .Synopsis
            Starts ping monitor for a Computer(s) or by network.
            
        .Description
            Starts ping monitor for a Computer(s) or by network.
                        
        .Parameter ComputerName 
            Name of the Computer.
            
        .Parameter Network 
            Network Address.
        
        .Example
            Invoke-Pingmonitor -ComputerName MyComputer
            Description
            -----------
            Starts Ping Monitor for MyComputer
            
        .Example
            Invoke-Pingmonitor -network 192.168.1.0
            Description
            -----------
            Starts Ping Monitor for network 192.168.1.0
            
        .Example
            $Servers | Invoke-Pingmonitor 
            Description
            -----------
            Starts Ping Monitor for all Computers in $Servers
                    
        .OUTPUTS
            System.String
            
        .INPUTS
            System.String
            
        .Link
            Get-IPRange
            Ping-Subnet
            Get-NetworkAddress
            ConvertTo-BinaryIP 
            ConvertFrom-BinaryIP 
            ConvertTo-MaskLength 
            ConvertFrom-MaskLength 
        
        .Notes
            NAME:      Invoke-PingMonitor
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding(DefaultParameterSetName="byName")]
    Param(
        [Alias('dnsHostName')]
        [Parameter(ValueFromPipeline=$true,ParameterSetName="byName")]
        [string]$ComputerName,
        [Parameter(ParameterSetName="byNetwork")]
        [string]$Network,
        [Parameter()]
        [switch]$TitleBar
    )
    Begin 
    {
    
        function Start-IPMonitor
        {
            Param($IPAddresses)
            Write-Verbose " [Start-IPMonitor] :: Called"
            function pServer 
            {
                Param([string]$srv)
                $pingresult = Get-WmiObject win32_pingstatus -f "address='$srv' and Timeout=1000"
                if($pingresult.statuscode -eq 0) {$true} else {$false}
            }
            $rows = [math]::Floor($host.UI.RawUI.BufferSize.Width/16)
            $i = 1
            while($true)
            {
                $oldpos = $host.UI.RawUI.CursorPosition
                foreach($IP in $IPAddresses)
                {
                    if($TitleBar){$host.UI.Rawui.WindowTitle = " == Processing $IP == "}
                    if(($i -lt $rows) -and ($i -lt $IPAddresses.count))
                    {
                        if(pServer $IP){Write-Host $IP.padright(15) -noNewLine -foregroundcolor green }
                        else{Write-Host $IP.padright(15) -noNewLine -foregroundcolor red}
                        $i = $i+1
                    }
                    else 
                    {
                        if(pServer $IP){Write-Host $IP.padright(15) -foregroundcolor green }
                        else{Write-Host $IP.padright(15) -foregroundcolor red}
                        $i = 1
                    }
                }
                start-sleep 5
                $host.UI.RawUI.CursorPosition = $oldpos
            }
        }
        Write-Verbose " [Invoke-PingMonitor] :: Start Begin"
        Write-Verbose " [Invoke-PingMonitor] :: ParameterSet = $($pscmdlet.ParameterSetName)"
        switch ($pscmdlet.ParameterSetName)
        {
            "byName"        {$Servers = @()}
            "byNetwork"        {
                                Write-Verbose " [Invoke-PingMonitor] :: Network = $Network"
                                $Net,$Mask = $network -split "/"
                                $Mask = ConvertFrom-MaskLength -mask $Mask
                                Write-Verbose " [Invoke-PingMonitor] :: Net = $Net"
                                Write-Verbose " [Invoke-PingMonitor] :: Mask = $Mask"
                                Write-Verbose " [Invoke-PingMonitor] :: Calling et-IPRange -IP $Net -netmask $Mask"
                                $IPs = Get-IPRange -IP $Net -netmask $Mask
                                Start-IPMonitor $IPs
                            }
        }
        
        Write-Verbose " [Invoke-PingMonitor] :: End Begin"
    
    }
    Process 
    {
    
        $Servers += $Computername
    
    }
    End 
    {
    
        if($Servers.Count -gt 0)
        {
            Start-IPMonitor $Servers
        }
    
    }
}
    
