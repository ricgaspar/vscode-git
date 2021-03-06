function Import-Credential
{
    
    <#
        .Synopsis 
            Imports the PSCredential securely from a file.
            
        .Description
            Imports the PSCredential securely from a file.
            
        .Parameter File
            File to Import from.
            
        .Parameter RequirePassword
            [Switch] :: If passed a password is request to decrypt with.
        
        .Example
            Import-Credential -file c:\temp\mycred.pwf
            Description
            -----------
            Extracts the PSCredential object from c:\temp\mycred.pwf
    
        .OUTPUTS
            PSCredential
            
        .INPUTS
            System.String
            
        .Link
            Export-Credential
    
        .Notes
            NAME:      Import-Credential
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$File,
        [Parameter()]
        [Switch]$RequirePassword
    )
    
    function GetSecurePass ($SecurePassword) 
    {
        $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($SecurePassword)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
        $password
    }
        
    $MyCredentialObject = Import-Clixml -Path $File
    $user = $MyCredentialObject.UserName
    $SecurePassword = $MyCredentialObject.Password
    
    if($RequirePassword)
    {
        $spwd = Read-Host -prompt "Enter Password to decrypt With" -asSecureString
        # Creating the Key for ConvertFrom-SecureString
        $ByteArrayforPassword = [System.Text.Encoding]::Unicode.GetBytes((GetSecurePass $spwd))
        if($ByteArrayforPassword.count -gt 24)
        {
            $key = @()
            [system.Array]::Copy($ByteArrayforPassword,$Key,24)
        }
        else
        {
            $key = $ByteArrayforPassword
            while($key.count -lt 24){$key += [byte]"11"}
        }
        $password = $SecurePassword | convertTo-SecureString -key $key
        $credential = New-Object System.Management.Automation.PsCredential($user,$password)
        $credential
    }
    else
    {
        $password = $SecurePassword | convertTo-SecureString
        $credential = New-Object System.Management.Automation.PsCredential($user,$password)
        $credential
    }
}
    
