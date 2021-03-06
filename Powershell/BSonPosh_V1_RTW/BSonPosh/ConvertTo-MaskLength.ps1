function ConvertTo-MaskLength
{
        
    #.Synopsis 
    # Convert from a netmask to the masklength
    #.Example 
    # ConvertTo-MaskLength -Mask 255.255.255.0
    # AUTHOR:    Glenn Sizemore
    # Website:   http://get-admin.com
    Param (
        [string]$mask
    )
    process {
    
        $out = 0
        foreach ($octet in $Mask.split('.')) 
        {
            $strout = 0
            0..7|% {
                if (($octet - [math]::pow(2,(7-$_)))-ge 0) 
                { 
                    $octet = $octet - [math]::pow(2,(7-$_))
                    $out++
                }
            }
        }
        return $out
        
    }
}
    
