function ConvertTo-UACFLag 
{
    <#
        .Synopsis
            Converts the User Account Control flag to an array of strings.
            
        .Description
            Converts the User Account Control flag to an array of strings.
            
        .Parameter UAC
            User Account control flag to convert
            
        .Parameter ToString
            [Switch] :: Returns a string instead of array.
    
        .Example
            ConvertTo-UACFlag 514
            Description
            -----------
            Converts the UAC flag 514 to Array of strings
            ACCOUNTDISABLE
            NORMAL_ACCOUNT
            
        .Example
            ConvertTo-UACFlag 514 -ToString
            Description
            -----------
            Converts the UAC flag 514 to a string
            ACCOUNTDISABLE,NORMAL_ACCOUNT
            
        .Outpus
            System.Array
            
        .Notes
            NAME:      ConvertTo-UACFlag
            AUTHOR:    YetiCentral\bshell
            Website:   www.bsonposh.com
            #Requires -Version 2.0
    #>
    Param(
        [int]$uac,
        [switch]$ToString
    )
    $flags = @()
    switch ($uac)
    {
        {($uac -bor 0x0002) -eq $uac}    {$flags += "ACCOUNTDISABLE"}
        {($uac -bor 0x0008) -eq $uac}    {$flags += "HOMEDIR_REQUIRED"}
        {($uac -bor 0x0010) -eq $uac}    {$flags += "LOCKOUT"}
        {($uac -bor 0x0020) -eq $uac}    {$flags += "PASSWD_NOTREQD"}
        {($uac -bor 0x0040) -eq $uac}    {$flags += "PASSWD_CANT_CHANGE"}
        {($uac -bor 0x0080) -eq $uac}    {$flags += "ENCRYPTED_TEXT_PWD_ALLOWED"}
        {($uac -bor 0x0100) -eq $uac}    {$flags += "TEMP_DUPLICATE_ACCOUNT"}
        {($uac -bor 0x0200) -eq $uac}    {$flags += "NORMAL_ACCOUNT"}
        {($uac -bor 0x0800) -eq $uac}    {$flags += "INTERDOMAIN_TRUST_ACCOUNT"}
        {($uac -bor 0x1000) -eq $uac}    {$flags += "WORKSTATION_TRUST_ACCOUNT"}
        {($uac -bor 0x2000) -eq $uac}    {$flags += "SERVER_TRUST_ACCOUNT"}
        {($uac -bor 0x10000) -eq $uac}   {$flags += "DONT_EXPIRE_PASSWORD"}
        {($uac -bor 0x20000) -eq $uac}   {$flags += "MNS_LOGON_ACCOUNT"}
        {($uac -bor 0x40000) -eq $uac}   {$flags += "SMARTCARD_REQUIRED"}
        {($uac -bor 0x80000) -eq $uac}   {$flags += "TRUSTED_FOR_DELEGATION"}
        {($uac -bor 0x100000) -eq $uac}  {$flags += "NOT_DELEGATED"}
        {($uac -bor 0x200000) -eq $uac}  {$flags += "USE_DES_KEY_ONLY"}
        {($uac -bor 0x400000) -eq $uac}  {$flags += "DONT_REQ_PREAUTH"}
        {($uac -bor 0x800000) -eq $uac}  {$flags += "PASSWORD_EXPIRED"}
        {($uac -bor 0x1000000) -eq $uac} {$flags += "TRUSTED_TO_AUTH_FOR_DELEGATION"}
    }
    if($toString)
    {
        $flags | %{if($mystring){$mystring += ",$_"}else{$mystring = $_}};$mystring}else{$flags
    }
}
    
