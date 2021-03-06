function Remove-RegistryKey
{
        
    <#
        .Synopsis 
            Removes a new key in the provide by Path.
            
        .Description
            Removes a new key in the provide by Path.
                        
        .Parameter Path 
            Path to remove the registry key from.
            
        .Parameter ComputerName 
            Computer to remove the registry key from.
            
        .Parameter Name 
            Name of the registry key to remove.
            
        .Parameter Recurse 
            Recursively removes registry key and all children from path.
        
        .Example
            Remove-registrykey HKLM\Software\Adobe -Name DeleteMe
            Description
            -----------
            Removes the registry key called DeleteMe under HKLM\Software\Adobe
            
        .Example
            Remove-RegistryKey HKLM\Software\Adobe -Name DeleteMe -ComputerName MyServer1
            Description
            -----------
            Removes the key called DeleteMe under HKLM\Software\Adobe on MyServer1
            
        .Example
            Remove-RegistryKey HKLM\Software\Adobe -Name DeleteMe -ComputerName MyServer1 -Recurse
            Description
            -----------
            Removes the key called DeleteMe under HKLM\Software\Adobe on MyServer1 and all child keys.
                    
        .OUTPUTS
            $null
            
        .INPUTS
            System.String
            
        .Link
            Get-RegistryKey
            New-RegistryKey
            Test-RegistryKey
            
        .Notes
        NAME:      Remove-RegistryKey
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
        
        [Alias("Server")]
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:ComputerName,
        
        [Parameter()]
        [switch]$Recurse
    )
    Begin 
    {
    
        Write-Verbose " [Remove-RegistryKey] :: Start Begin"
        
        Write-Verbose " [Remove-RegistryKey] :: `$Path = $Path"
        Write-Verbose " [Remove-RegistryKey] :: Getting `$Hive and `$KeyPath from $Path "
        $PathParts = $Path -split "\\|/",0,"RegexMatch"
        $Hive = $PathParts[0]
        $KeyPath = $PathParts[1..$PathParts.count] -join "\"
        Write-Verbose " [Remove-RegistryKey] :: `$Hive = $Hive"
        Write-Verbose " [Remove-RegistryKey] :: `$KeyPath = $KeyPath"
        
        Write-Verbose " [Remove-RegistryKey] :: End Begin"
    
    }
    
    Process 
    {
    
        Write-Verbose " [Remove-RegistryKey] :: Start Process"
        Write-Verbose " [Remove-RegistryKey] :: `$ComputerName = $ComputerName"
        
        if(Test-RegistryKey -Path $path\$name -ComputerName $ComputerName)
        {
            $RegHive = Get-RegistryHive $hive
            
            if($RegHive -eq 1)
            {
                Write-Host "Invalid Path: $Path, Registry Hive [$hive] is invalid!" -ForegroundColor Red
            }
            else
            {
                Write-Verbose " [Remove-RegistryKey] :: `$RegHive = $RegHive"
                $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
                Write-Verbose " [Remove-RegistryKey] :: `$BaseKey = $BaseKey"
                
                $Key = $BaseKey.OpenSubKey($KeyPath,$True)
                
                if($PSCmdlet.ShouldProcess($ComputerName,"Deleteing Key [$Name]"))
                {
                    if($Recurse)
                    {
                        Write-Verbose " [Remove-RegistryKey] :: Calling DeleteSubKeyTree($Name)"
                        $Key.DeleteSubKeyTree($Name)
                    }
                    else
                    {
                        Write-Verbose " [Remove-RegistryKey] :: Calling DeleteSubKey($Name)"
                        $Key.DeleteSubKey($Name)
                    }
                }
            }
        }
        else
        {
            "Key [$path\$name] does not exist"
        }
        Write-Verbose " [Remove-RegistryKey] :: End Process"
    
    }
}
    
