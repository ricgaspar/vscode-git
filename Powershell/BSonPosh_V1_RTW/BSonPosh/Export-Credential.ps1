function Export-Credential 
{
    <#
        .Synopsis 
            Exports the PSCredential securely to a file.
            
        .Description
            Exports the PSCredential securely to a file.
            
        .Parameter File
            File to export to.
        
        .Parameter Credential
            PSCredential to Export to file
            
        .Parameter RequirePassword
            [Switch] :: If passed a password is request to encrypt with.
        
        .Example
            Export-Credential -file c:\temp\mycred.pwf
            Description
            -----------
            Promps for creds and stores them to c:\temp\mycred.pwf
    
        .OUTPUTS
            FileInfo
            
        .INPUTS
            System.String
            
        .Link
            Import-Credential
            
        .Notes
            NAME:      Export-Credential
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$File,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = (Get-Credential),
        
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
        
    $MyCredentialObject = New-Object PSCustomObject
    
    # Get Password to Encrypt the Creds with
    if($RequirePassword)
    {
        $spwd = Read-Host -prompt "Enter Password to Encrypt With" -asSecureString
        
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
        
        $PasswordString = $credential.Password | ConvertFrom-SecureString -key $key
        Add-Member -InputObject $MyCredentialObject -MemberType NoteProperty -Name UserName -Value $credential.UserName
        Add-Member -InputObject $MyCredentialObject -MemberType NoteProperty -Name Password -Value $PasswordString
        $MyCredentialObject | Export-Clixml -Path $File 
        
        Get-Item $File
        
    }
    else
    {
        
        $PasswordString = ($credential.Password | ConvertFrom-SecureString)
        Add-Member -InputObject $MyCredentialObject -MemberType NoteProperty -Name UserName -Value $credential.UserName
        Add-Member -InputObject $MyCredentialObject -MemberType NoteProperty -Name Password -Value $PasswordString
        
        $MyCredentialObject | Export-Clixml -Path $File 
        
        Get-Item $File
        
    }
}
    
