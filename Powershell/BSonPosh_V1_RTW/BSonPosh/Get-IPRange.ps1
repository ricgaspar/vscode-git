function Get-IPRange
{
        
    <#
        .Synopsis 
            Given an IP and Subnet Mask it return all  IP in the same IP network.
            
        .Description
            Given an IP and Subnet Mask it return all  IP in the same IP network.
                        
        .Parameter IP 
            IP of a host on the Network.
            
        .Parameter Network 
            Network Address.
        
        .Example
            Get-IPRange -IP 192.168.1.0 -Mask 255.255.255.0
            Description
            -----------
            Returns all host on 192.168.1.0 network using mask 255.255.255.0
            
        .Example
            Get-IPRange -IP 192.168.1.0 -Mask /24
            Description
            -----------
            Returns all host on 192.168.1.0 network using CIDR notation
            
        .OUTPUTS
            System.String
            
        .INPUTS
            System.String
            
        .Link
            Ping-Subnet
            Invoke-Pingmonitor
            Get-NetworkAddress
            ConvertTo-BinaryIP 
            ConvertFrom-BinaryIP 
            ConvertTo-MaskLength 
            ConvertFrom-MaskLength 
            
        .Notes    
            NAME:      Get-IPRange
            AUTHOR:    Glenn Sizemore
            Website:   http://get-admin.com
            Version:   1
            #Requires -Version 2.0
    #>
        
    [Cmdletbinding()]
    Param (
        [Parameter()]
        [string]$IP,
        
        [Alias("mask")]
        [Parameter()]
        [string]$netmask
    )
    Process 
    {
    
        Write-Verbose  " [Get-IPRange] :: Process start"
        
        if ($netMask -match "(^\d\d$)|(^/\d\d$)") 
        {
            Write-Verbose  " [Get-IPRange] :: Converting $netmask to $($netmask.replace('/',''))"
            $masklength = $netmask.replace('/','')
            $Subnet = ConvertFrom-MaskLength $masklength
            Write-Verbose  " [Get-IPRange] :: Subnet :: $Subnet"
        } 
        else 
        {
            Write-Verbose " [Get-IPRange] :: Using $netmask"
            $Subnet = $netmask
            $masklength = ConvertTo-MaskLength -Mask $netmask
            Write-Verbose " [Get-IPRange] :: Subnet :: $Subnet"
        }
        
        Write-Verbose " [Get-IPRange] :: Getting Network Address - Get-NetworkAddress -IP $IP -Mask $Subnet "
        $network = Get-NetworkAddress -IP $IP -Mask $Subnet 
        Write-Verbose " [Get-IPRange] :: returned $Network"
        
        [int]$FirstOctet,[int]$SecondOctet,[int]$ThirdOctet,[int]$FourthOctet = $network.split('.')
        
        Write-Verbose " [Get-IPRange] :: Getting Total number of IPs"
        $TotalIPs = ([math]::pow(2,(32-$masklength)) -2)
        Write-Verbose " [Get-IPRange] :: Result = $TotalIPs"
        
        Write-Verbose " [Get-IPRange] :: Getting IPs"
        
        $blocks = ($TotalIPs - ($TotalIPs % 256))/256
        if ($Blocks -gt 0) 
        {
            1..$blocks | %{
                0..255 |%{
                    if ($FourthOctet -eq 255) 
                    {
                        if ($ThirdOctet -eq 255) 
                        {
                            if ($SecondOctet -eq 255) 
                            {
                                $FirstOctet++
                                $secondOctet = 0
                            } 
                            else 
                            {
                                $SecondOctet++
                                $ThirdOctet = 0
                            }
                        } 
                        else 
                        {
                            $FourthOctet = 0
                            $ThirdOctet++
                        }  
                    } 
                    else 
                    {
                        $FourthOctet++
                    }
                    Write-Output ("{0}.{1}.{2}.{3}" -f `
                    $FirstOctet,$SecondOctet,$ThirdOctet,$FourthOctet)
                }
            }
        }
        
        $sBlock = $TotalIPs - ($blocks * 256)
        
        if ($sBlock -gt 0) 
        {
            1..$SBlock | %{
                if ($FourthOctet -eq 255)
                {
                    if ($ThirdOctet -eq 255) 
                    {
                        if ($SecondOctet -eq 255) 
                        {
                            $FirstOctet++
                            $secondOctet = 0
                        } 
                        else 
                        {
                            $SecondOctet++
                            $ThirdOctet = 0
                        }
                    } 
                    else 
                    {
                        $FourthOctet = 0
                        $ThirdOctet++
                    }  
                } 
                else 
                {
                    $FourthOctet++
                }
                Write-Output ("{0}.{1}.{2}.{3}" -f `
                $FirstOctet,$SecondOctet,$ThirdOctet,$FourthOctet)
            }
        }
        
        Write-Verbose  " [Get-IPRange] :: Process End"
    
    }
}
    
