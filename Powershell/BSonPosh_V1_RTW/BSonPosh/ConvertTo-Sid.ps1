function ConvertTo-Sid
{
    <#
        .Synopsis
            Converts the user name to SID.
            
        .Description
            Converts the KMS Return code to a friendly valueConverts the user name to SID
            
        .Parameter UserName
            UserName to convert
            
        .Parameter Domain
            Domain of the User (defaults to current domain.)
    
        .Example
            ConvertTo-SID dev\bshell
            Description
            -----------
            Converts the user name dev\bshell to sid
            
        .Outpus
            System.String
            
        .Notes
            NAME:      ConvertTo-SID
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    param($UserName,$domain = $env:USERDOMAIN)
    switch -regex ($UserName)
    {
        ".*\\.*"   {
                        $ID = New-Object System.Security.Principal.NTAccount($UserName)
                }
        ".*@.*"    {
                        $ID = New-Object System.Security.Principal.NTAccount($UserName)
                }
        Default    {
                        $ID = New-Object System.Security.Principal.NTAccount($domain,$UserName)
                }
    }
    $SID = $ID.Translate([System.Security.Principal.SecurityIdentifier])
    $SID.Value
}
    
