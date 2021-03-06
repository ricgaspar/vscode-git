function ConvertFrom-MaskLength
{
        
    #.Synopsis 
    # Convert from masklength to a netmask
    #.Example 
    # ConvertFrom-MaskLength -Mask /24
    #.Example 
    # ConvertFrom-MaskLength -Mask 24
    # AUTHOR:    Glenn Sizemore
    # Website:   http://get-admin.com
    
    Param (
        [string]
        $mask
    )
    process {
    
        $out = @()
        if($mask -match "^/")
        {
            [int]$myMask = $mask -replace "/",""
        }
        else
        {
            [int]$myMask = $mask
        }
        [int]$wholeOctet = ($myMask - ($myMask % 8))/8
        if ($wholeOctet -gt 0) 
        {
            1..$($wholeOctet) |%{
                $out += "255"
            }
        }
        $subnet = ($myMask - ($wholeOctet * 8))
        if ($subnet -gt 0) 
        {
            $octet = 0
            0..($subnet - 1) | %{
                $octet = $octet + [math]::pow(2,(7-$_))
            }
            $out += $octet
        }
        for ($i=$out.count;$i -lt 4; $I++) 
        {
            $out += 0
        }
        return [string]::join('.',$out)
    
    }
}
    
