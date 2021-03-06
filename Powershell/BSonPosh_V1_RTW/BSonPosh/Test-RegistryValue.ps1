function Test-RegistryValue
{
        
    <#
        .Synopsis 
            Test the value for given the registry value.
            
        .Description
            Test the value for given the registry value.
                        
        .Parameter Path 
            Path to the key that contains the value.
            
        .Parameter Name 
            Name of the Value to check.
            
        .Parameter Value 
            Value to check for.
            
        .Parameter ComputerName 
            Computer to test.
            
        .Example
            Test-RegistryValue HKLM\SOFTWARE\Adobe\SwInstall -Name State -Value 0
            Description
            -----------
            Returns $True if the value of State under HKLM\SOFTWARE\Adobe\SwInstall is 0
            
        .Example
            Test-RegistryValue HKLM\Software\Adobe -ComputerName MyServer1
            Description
            -----------
            Returns $True if the value of State under HKLM\SOFTWARE\Adobe\SwInstall is 0 on MyServer1
                    
        .OUTPUTS
            System.Boolean
            
        .INPUTS
            System.String
            
        .Link
            New-RegistryValue
            Remove-RegistryValue
            Get-RegistryValue
        
        .Notes    
            NAME:      Test-RegistryValue
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [Parameter(mandatory=$true)]
        [string]$Path,
    
        [Parameter(mandatory=$true)]
        [string]$Name,
        
        [Parameter()]
        [string]$Value,
        
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
        
    )
    
    Process 
    {
    
        Write-Verbose " [Test-RegistryValue] :: Begin Process"
        Write-Verbose " [Test-RegistryValue] :: Calling Get-RegistryKey -Path $path -ComputerName $ComputerName"
        $Key = Get-RegistryKey -Path $path -ComputerName $ComputerName 
        Write-Verbose " [Test-RegistryValue] :: Get-RegistryKey returned $Key"
        if($Value)
        {
            try
            {
                $CurrentValue = $Key.GetValue($Name)
                $Value -eq $CurrentValue
            }
            catch
            {
                $false
            }
        }
        else
        {
            try
            {
                $CurrentValue = $Key.GetValue($Name)
                if($CurrentValue){$True}else{$false}
            }
            catch
            {
                $false
            }
        }
        Write-Verbose " [Test-RegistryValue] :: End Process"
    
    }
}
    
