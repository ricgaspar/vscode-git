function ConvertTo-DNSName
{
    <#
        .Synopsis
            Converts the Netbios or DistinguishedName to DNSName name
            
        .Description
            Converts the Netbios or DistinguishedName to DNSName name
            
        .Parameter DistinguishedName
            DistinguishedName to convert
            
        .Parameter Netbios
            Netbios name to convert
            
        .Example
            # Using DistinguishedName
            ConvertTo-DNSName "dc=corp,dc=lab"
            
            # Using Netbios
            ConvertTo-DNSName Dev
            
        .Outputs
            System.String
            
        .Link
            ConvertTo-NetBiosName
            ConvertTo-DistinguishedName
            
        .Notes
            NAME:      ConvertTo-DNSName
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
        Param(
    
        [Alias('dn')]
        [ValidatePattern('^((CN|OU)=.*)*(DC=.*)*$')]
        [Parameter()]
        $DistinguishedName,
        
        [Parameter()]
        $Netbios
    )
    if($DistinguishedName)
    {
        $SplitName = $DistinguishedName -split "DC=" -replace ",",""
        $SplitName[1..$SplitName.count] -join "."
    }
    if($Netbios)
    {
        $rootDSE = [ADSI]"LDAP://$Netbios/rootDSE"
        $SplitName = $rootDSE.dnsHostName[0].Split(".")
        $SplitName[1..$SplitName.count] -join "."
    }
}
    
