function ConvertFrom-BinaryIP
{
        
    #.Synopsis 
    # Convert from Binary to an IP address
    #.Example 
    # Convertfrom-BinaryIP -IP 11000000.10101000.00000001.00000001
    # AUTHOR:    Glenn Sizemore
    # Website:   http://get-admin.com
    Param (
        [string]
        $IP
    )
    process 
    {
    
        $out = @()
        foreach ($octet in $IP.split('.')) 
        {
            $strout = 0
            0..7|% {
                $bit = $octet.Substring(($_),1)
                if ($bit -eq 1) 
                { 
                    $strout = $strout + [math]::pow(2,(7-$_))
                } 
            }
            $out += $strout
        }
        return [string]::join('.',$out)
        
    }
}
    
