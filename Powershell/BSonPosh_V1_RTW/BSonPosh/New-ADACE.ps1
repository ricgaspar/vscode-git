function New-ADACE
{
    
    <#
        .Synopsis 
            Creates a Access Control Entry to add to an AD Object
            
        .Description
            Creates a Access Control Entry to add to an AD Object
            
        .Parameter identity
            System.Security.Principal.IdentityReference
            http://msdn.microsoft.com/en-us/library/system.security.principal.ntaccount.aspx
            
        .Parameter adRights
            System.DirectoryServices.ActiveDirectoryRights
            http://msdn.microsoft.com/en-us/library/system.directoryservices.activedirectoryrights.aspx
            
        .Parameter type
            System.Security.AccessControl.AccessControlType
            http://msdn.microsoft.com/en-us/library/w4ds5h86(VS.80).aspx
            
        .Parameter GUID
        Object Type of the property
            The schema GUID of the object to which the access rule applies.
            
        .Example
            New-ADACE -id $NTIdentity -ADRights $Rights -type $type -guid "bf9679c0-0de6-11d0-a285-00aa003049e2"
            Description
            -----------
            Creates an ACE Local user with the specified permissions.
        
        .OUTPUTS
            Object
            
        .Link
            N/A
            
        .Notes
            NAME:      New-ADAce
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [System.Security.Principal.IdentityReference]$identity,
        
        [Parameter(Mandatory=$True)]
        [System.DirectoryServices.ActiveDirectoryRights]$adRights,
        
        [Parameter(Mandatory=$True)]
        [System.Security.AccessControl.AccessControlType]$type,
        
        [Parameter(Mandatory=$True)]
        [string]$Guid
    )
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type,$guid)
    $ACE
}
    
