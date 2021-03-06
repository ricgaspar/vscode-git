function Get-ADACL
{
        
    <#
        .Synopsis 
            Gets ACL object or SDDL for AD Object
            
        .Description
            Gets ACL object or SDDL for AD Object
            
        .Parameter DistinguishedName
            DistinguishedName of the Object to Get the ACL from
            
        .Parameter SDDL [switch]
            If passed it will return the SDDL string
            
        .Example
            Get ACL for ‘cn=users,dc=corp,dc=lab’
                Get-ADACL ‘cn=users,dc=corp,dc=lab’
            Get SDDL for ‘cn=users,dc=corp,dc=lab’
                Get-ADACL ‘cn=users,dc=corp,dc=lab’ -sddl
                
        .Outputs
            Object
            
        .Link
            N/A
            
        .Notes
            NAME:      Get-ADACL
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [Alias('dn')]
        [ValidatePattern('^((CN|OU)=.*)*(DC=.*)*$')]
        [Parameter(ValueFromPipeline=$true,Mandatory=$True)]
        [string]$DistinguishedName,
        
        [Parameter()]
        [switch]$SDDL
    )
    Write-Verbose " + Processing Object [$DistinguishedName]"
    $DE = [ADSI]"LDAP://$DistinguishedName"
    
    Write-Verbose "   - Getting ACL"
    $acl = $DE.psbase.ObjectSecurity
    if($SDDL)
    {
        Write-Verbose "   - Returning SDDL"
        $acl.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::All)
    }
    else
    {
        Write-Verbose "   - Returning ACL Object [System.DirectoryServices.ActiveDirectoryAccessRule]"
        $acl.GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier])
    }
}
    
