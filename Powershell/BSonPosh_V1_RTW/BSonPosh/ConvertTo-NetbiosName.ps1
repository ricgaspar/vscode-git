function ConvertTo-NetbiosName
{
    
    <#
        .Synopsis
            Converts the DNS or DistinguishedName to netbios name
            
        .Description
            Converts the DNS or DistinguishedName to netbios name
            
        .Parameter DistinguishedName
            DistinguishedName to Convert
            
        .Parameter DNSName
            DNSName to Convert
    
        .Example
            # Using DistinguishedName
            ConvertTo-NetbiosName "dc=Dev,dc=Lab"
            
            # Using DNSName
            ConvertTo-NetbiosName Dev.Lab
            
        .Outpus
            System.String
            
        .Link
            ConvertTo-DNSName
            ConvertTo-DistinguishedName
            
        .Notes
            NAME:      ConvertTo-NetbiosName
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [Alias('dn')]
        [ValidatePattern('^((CN|OU)=.*)*(DC=.*)*$')]
        [Parameter()]
        [string]$DistinguishedName,
        
        [ValidatePattern('^(\w|\d)+\.*')]
        [Parameter()]
        [string]$DNSName
    )
    if($DistinguishedName)
    {
        ([ADSI]"LDAP://$DistinguishedName").Name
    }
    if($DNSName)
    {
        ([ADSI]"LDAP://$DNSName").Name
    }
}
    
