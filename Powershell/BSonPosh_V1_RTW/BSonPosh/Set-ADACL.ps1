function Set-ADACL
{
        
    <#
        .Synopsis 
            Sets the AD Object ACL to ‘ACL Object’ or ‘SDDL’ String"
            
        .Description
            Sets the AD Object ACL to ‘ACL Object’ or ‘SDDL’ String"
            
        .Parameter DistinguishedName
            DistinguishedName of the Object to Get the ACL from
            
        .Parameter ACL
            ACL Object to Apply
            
        .Parameter SDDL
            SDDL string to Apply
            
        .Example
            Set-ADACL ‘cn=users,dc=corp,dc=lab’ -ACL $acl
            Description
            -----------
            Set ACL on ‘cn=users,dc=corp,dc=lab’ using ACL Object
            
        .Example
            Set-ADACL ‘cn=users,dc=corp,dc=lab’ -sddl $mysddl
            Description
            -----------
            Set ACL on ‘cn=users,dc=corp,dc=lab’ using SDDL
                
        .OUTPUTS
            Object
            
        .Link
            N/A
            
        .Notes
            NAME:      Set-ADACL
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
        [cmdletbinding()]
        Param(
    
            [Alias('dn')]
            [ValidatePattern('^((CN|OU)=.*)*(DC=.*)*$')]
            [Parameter(ValueFromPipeline=$true,Mandatory=$True)]
            [string]$DistinguishedName,
            
            [Parameter()]
            [System.DirectoryServices.ActiveDirectoryAccessRule]$ACL,
            
            [Parameter()]
            [String]$SDDL,
    
        [Parameter()]
        [switch]$Replace
        )
    Write-Verbose " + Processing Object [$DistinguishedName]"
    
    $DE = [ADSI]"LDAP://$DistinguishedName"
    if($sddl)
    {
        Write-Verbose "   - Setting ACL using SDDL [$sddl]"
        $DE.psbase.ObjectSecurity.SetSecurityDescriptorSddlForm($sddl)
    }
    else
    {
        foreach($ace in $acl)
        {
            Write-Verbose "   - Adding Permission [$($ace.ActiveDirectoryRights)] to [$($ace.IdentityReference)]"
        if($Replace)
        {
            $DE.psbase.ObjectSecurity.SetAccessRule($ace)
            }
            else
            {
            $DE.psbase.ObjectSecurity.AddAccessRule($ace)             
            }
        }
    }
    $DE.psbase.commitchanges()
}
    
