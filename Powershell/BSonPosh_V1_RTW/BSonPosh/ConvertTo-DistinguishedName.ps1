function ConvertTo-DistinguishedName
{
    
    <#
        .Synopsis 
            Converts the Netbios or dnsname to DistinguishedName name
            
        .Description
            Converts the Netbios or dnsname to DistinguishedName name
            
        .Parameter dnsname
            dnsname to convert
            
        .Parameter Netbios
            Netbios name to convert
            
        .Example
            # Using DNS
            ConvertTo-DistinguishedName Dev.Lab
            
            # Using Netbios
            ConvertTo-DistinguishedName Dev
            
        .Output
            System.String
            
        .Link
            ConvertTo-DNSName
            ConvertTo-NetbiosName
            
        .Notes
            NAME:      ConvertTo-DistinguishedName
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [ValidatePattern('^(\w|\d)+\.*')]
        [Parameter()]
        $DNSName,
        
        [Parameter()]
        $Netbios
    )
    if($DNSName)
    {
        ([ADSI]"LDAP://$DNSName").distinguishedName[0]
    }
    if($NetBios)
    {
        ([ADSI]"LDAP://$NetBios").distinguishedName[0]
    }
}
    
