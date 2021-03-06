function New-RegistryValue
{
    
    <#
        .Synopsis 
            Create a value under the registry key.
            
        .Description
            Create a value under the registry key.
                        
        .Parameter Path 
            Path to the key.
            
        .Parameter Name 
            Name of the Value to create.
            
        .Parameter Value 
            Value to for the new Value.
            
        .Parameter Type
            Type for the new Value. Valid Types: Unknown, String (default,) ExpandString, Binary, DWord, MultiString, a
    nd Qword
            
        .Parameter ComputerName 
            Computer to create the Value on.
            
        .Example
            New-RegistryValue HKLM\SOFTWARE\Adobe\MyKey -Name State -Value "Hi There"
            Description
            -----------
            Creates the Value State and sets the value to "Hi There" under HKLM\SOFTWARE\Adobe\MyKey.
            
        .Example
            New-RegistryValue HKLM\SOFTWARE\Adobe\MyKey -Name State -Value 0 -ComputerName MyServer1
            Description
            -----------
            Creates the Value State and sets the value to "Hi There" under HKLM\SOFTWARE\Adobe\MyKey on MyServer1.
            
        .Example
            New-RegistryValue HKLM\SOFTWARE\Adobe\MyKey -Name MyDWord -Value 0 -Type DWord
            Description
            -----------
            Creates the DWORD Value MyDWord and sets the value to 0 under HKLM\SOFTWARE\Adobe\MyKey.
                    
        .OUTPUTS
            System.Boolean
            
        .INPUTS
            System.String
            
        .Link
            New-RegistryValue
            Remove-RegistryValue
            Get-RegistryValue
            
        NAME:      Test-RegistryValue
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
    
        Write-Verbose " [New-RegistryValue] :: Start Begin"
        Write-Verbose " [New-RegistryValue] :: `$Path = $Path"
        Write-Verbose " [New-RegistryValue] :: `$Name = $Name"
        Write-Verbose " [New-RegistryValue] :: `$Value = $Value"
        
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
        Write-Verbose " [New-RegistryValue] :: `$Type = $Type"
        Write-Verbose " [New-RegistryValue] :: End Begin"
        
    }
    
    Process 
    {
    
        if(Test-RegistryValue -Path $path -Name $Name -ComputerName $ComputerName)
        {
            "Registry value already exist"     
        }
        else
        {
            Write-Verbose " [New-RegistryValue] :: Start Process"
            Write-Verbose " [New-RegistryValue] :: Calling Get-RegistryKey -Path $path -ComputerName $ComputerName"
            $Key = Get-RegistryKey -Path $path -ComputerName $ComputerName -ReadWrite
            Write-Verbose " [New-RegistryValue] :: Get-RegistryKey returned $Key"
            Write-Verbose " [New-RegistryValue] :: Setting Value for [$Name]"
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
                Write-Verbose " [New-RegistryValue] :: Returning New Key: Get-RegistryValue -Path $path -Name $Name -ComputerName $ComputerName"
                Get-RegistryValue -Path $path -Name $Name -ComputerName $ComputerName
            }
        }
        Write-Verbose " [New-RegistryValue] :: End Process"
    
    }
}
    
