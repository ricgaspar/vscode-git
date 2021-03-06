function ConvertTo-BinaryIP
{
        
    #.Synopsis
    # Convert an IP address to binary
    #.Example 
    # ConvertTo-BinaryIP -IP 192.168.1.1
    # AUTHOR:    Glenn Sizemore
    # Website:   http://get-admin.com
    Param (
        [string]$IP
    )
    begin {
    
        if($IP -match "(^/\d\d$|^\d\d$)")
        {
            $Address = ConvertFrom-MaskLength $IP
        }
        else
        {
            $Address = $IP
        }
        $out = @()
        foreach ($octet in $Address.split('.'))
        {
            $strout = $null
            0..7|% {
                if (($octet - [math]::pow(2,(7-$_)))-ge 0) 
                { 
                    $octet = $octet - [math]::pow(2,(7-$_))
                    [string]$strout = $strout + "1"
                }
                else 
                {
                    [string]$strout = $strout + "0"
                }   
            }
            $out += $strout
        }
        return [string]::join('.',$out)
        
    }
}
    
