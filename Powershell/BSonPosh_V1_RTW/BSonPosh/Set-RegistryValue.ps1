function Set-RegistryValue
{
        
    <#
        .Synopsis 
            Sets a value under the registry key.
            
        .Description
            Sets a value under the registry key.
                        
        .Parameter Path 
            Path to the key.
            
        .Parameter Name 
            Name of the Value to Set.
            
        .Parameter Value 
            New Value.
            
        .Parameter Type
            Type for the Value. Valid Types: Unknown, String (default,) ExpandString, Binary, DWord, MultiString, and Q
    word
            
        .Parameter ComputerName 
            Computer to set the Value on.
            
        .Example
            Set-RegistryValue HKLM\SOFTWARE\Adobe\MyKey -Name State -Value "Hi There"
            Description
            -----------
            Sets the Value State and sets the value to "Hi There" under HKLM\SOFTWARE\Adobe\MyKey.
            
        .Example
            Set-RegistryValue HKLM\SOFTWARE\Adobe\MyKey -Name State -Value 0 -ComputerName MyServer1
            Description
            -----------
            Sets the Value State and sets the value to "Hi There" under HKLM\SOFTWARE\Adobe\MyKey on MyServer1.
            
        .Example
            Set-RegistryValue HKLM\SOFTWARE\Adobe\MyKey -Name MyDWord -Value 0 -Type DWord
            Description
            -----------
            Sets the DWORD Value MyDWord and sets the value to 0 under HKLM\SOFTWARE\Adobe\MyKey.
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            New-RegistryValue
            Remove-RegistryValue
            Get-RegistryValue
            Test-RegistryValue
        
        .Notes
            NAME:      Set-RegistryValue
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(mandatory=$true)]
        [string]$Path,
        
        [Parameter(mandatory=$true)]
        [string]$Name,
        
        [Parameter()]
        [string]$Value,
        
        [Parameter()]
        [string]$Type,
        
        [Alias("dnsHostName")]
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:ComputerName
    )
    
    Begin 
    {
    
        Write-Verbose " [Set-RegistryValue] :: Start Begin"
        
        Write-Verbose " [Set-RegistryValue] :: `$Path = $Path"
        Write-Verbose " [Set-RegistryValue] :: `$Name = $Name"
        Write-Verbose " [Set-RegistryValue] :: `$Value = $Value"
        
        Switch ($Type)
        {
            "Unknown"       {$ValueType = [Microsoft.Win32.RegistryValueKind]::Unknown;continue}
            "String"        {$ValueType = [Microsoft.Win32.RegistryValueKind]::String;continue}
            "ExpandString"  {$ValueType = [Microsoft.Win32.RegistryValueKind]::ExpandString;continue}
            "Binary"        {$ValueType = [Microsoft.Win32.RegistryValueKind]::Binary;continue}
            "DWord"         {$ValueType = [Microsoft.Win32.RegistryValueKind]::DWord;continue}
            "MultiString"   {$ValueType = [Microsoft.Win32.RegistryValueKind]::MultiString;continue}
            "QWord"         {$ValueType = [Microsoft.Win32.RegistryValueKind]::QWord;continue}
            default         {$ValueType = [Microsoft.Win32.RegistryValueKind]::String;continue}
        }
        Write-Verbose " [Set-RegistryValue] :: `$Type = $Type"
        
        Write-Verbose " [Set-RegistryValue] :: End Begin"
    
    }
    
    Process 
    {
    
        Write-Verbose " [Set-RegistryValue] :: Start Process"
        
        Write-Verbose " [Set-RegistryValue] :: Calling Get-RegistryKey -Path $path -ComputerName $ComputerName"
        $Key = Get-RegistryKey -Path $path -ComputerName $ComputerName -ReadWrite
        Write-Verbose " [Set-RegistryValue] :: Get-RegistryKey returned $Key"
        Write-Verbose " [Set-RegistryValue] :: Setting Value for [$Name]"
        if($PSCmdlet.ShouldProcess($ComputerName,"Creating Value [$Name] under $Path with value [$Value]"))
        {
            if($Value)
            {
                $Key.SetValue($Name,$Value,$ValueType)
            }
            else
            {
                $Key.SetValue($Name,$ValueType)
            }
            Write-Verbose " [Set-RegistryValue] :: Returning New Key: Get-RegistryValue -Path $path -Name $Name -ComputerName $ComputerName"
            Get-RegistryValue -Path $path -Name $Name -ComputerName $ComputerName
        }
        Write-Verbose " [Set-RegistryValue] :: End Process"
    
    }
}
    
