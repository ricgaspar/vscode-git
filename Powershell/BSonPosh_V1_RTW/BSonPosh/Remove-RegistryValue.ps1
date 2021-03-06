function Remove-RegistryValue 
{
        
    <#
        .Synopsis 
            Removes the value.
            
        .Description
            Removes the value.
                        
        .Parameter Path 
            Path to the key that contains the value.
            
        .Parameter Name 
            Name of the Value to Remove.
    
        .Parameter ComputerName 
            Computer to remove value from.
            
        .Example
            Remove-RegistryValue HKLM\SOFTWARE\Adobe\MyKey -Name State
            Description
            -----------
            Removes the value STATE under HKLM\SOFTWARE\Adobe\MyKey.
            
        .Example
            Remove-RegistryValue HKLM\Software\Adobe\MyKey -Name State -ComputerName MyServer1
            Description
            -----------
            Removes the value STATE under HKLM\SOFTWARE\Adobe\MyKey on MyServer1.
                    
        .OUTPUTS
            $null
            
        .INPUTS
            System.String
            
        .Link
            New-RegistryValue
            Test-RegistryValue
            Get-RegistryValue
            Set-RegistryValue
            
        NAME:      Remove-RegistryValue
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
        
        [Alias("dnsHostName")]
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:ComputerName
    )
    Begin 
    {
    
        Write-Verbose " [Remove-RegistryValue] :: Start Begin"
        
        Write-Verbose " [Remove-RegistryValue] :: `$Path = $Path"
        Write-Verbose " [Remove-RegistryValue] :: `$Name = $Name"
        
        Write-Verbose " [Remove-RegistryValue] :: End Begin"
        
    }
    
    Process 
    {
    
        if(Test-RegistryValue -Path $path -Name $Name -ComputerName $ComputerName)
        {
            Write-Verbose " [Remove-RegistryValue] :: Start Process"
            Write-Verbose " [Remove-RegistryValue] :: Calling Get-RegistryKey -Path $path -ComputerName $ComputerName"
            $Key = Get-RegistryKey -Path $path -ComputerName $ComputerName -ReadWrite
            Write-Verbose " [Remove-RegistryValue] :: Get-RegistryKey returned $Key"
            Write-Verbose " [Remove-RegistryValue] :: Setting Value for [$Name]"
            if($PSCmdlet.ShouldProcess($ComputerName,"Deleting Value [$Name] under $Path"))
            {
                $Key.DeleteValue($Name)
            }
        }
        else
        {
            "Registry Value is already gone"
        }
        
        Write-Verbose " [Remove-RegistryValue] :: End Process"
    
    }
}
    
