function Get-NetworkAddress
{
        
    <#
        .Synopsis 
            Get the network address of a given lan segment.
            
        .Description
            Get the network address of a given lan segment.
                        
        .Parameter IP 
            IP address.
            
        .Parameter Mask 
            Subnet Mask for Network.
            
        .Parameter Binary 
            Switch to Return Binary
        
        .Example
            Get-NetworkAddress -IP 192.168.1.36 -mask 255.255.255.0
            Description
            -----------
            Returns the Network Address for given IP and Mask
                    
        .OUTPUTS
            System.String
            
        .INPUTS
            System.String
            
        .Link
            Get-IPRange
            Ping-Subnet
            Invoke-PingMonitor
            ConvertTo-BinaryIP 
            ConvertFrom-BinaryIP 
            ConvertTo-MaskLength 
            ConvertFrom-MaskLength 
            
        .Notes
            NAME:      Get-NetworkAddress
            AUTHOR:    Glenn Sizemore
            Website:   http://get-admin.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$IP, 
        
        [Parameter(Mandatory=$true)]
        [string]$Mask, 
        
        [Parameter()]
        [switch]$Binary
    )
    Begin 
    {
    
        Write-Verbose " [Get-NetworkAddress] :: Begin "
        $NetAdd = $null
    
        $BinaryIP = ConvertTo-BinaryIP $IP
        $BinaryMask = ConvertTo-BinaryIP $Mask
    
        0..34 | %{
            $IPBit = $BinaryIP.Substring($_,1)
            $MaskBit = $BinaryMask.Substring($_,1)
            if ($IPBit -eq '1' -and $MaskBit -eq '1') 
            {
                $NetAdd = $NetAdd + "1"
            } 
            elseif ($IPBit -eq ".") 
            {
                $NetAdd = $NetAdd + '.'
            } 
            else 
            {
                $NetAdd = $NetAdd + "0"
            }
        }
        if ($Binary) 
        {
            return $NetAdd
        } 
        else 
        {
            return ConvertFrom-BinaryIP $NetAdd
        }
    
    }
}
    
