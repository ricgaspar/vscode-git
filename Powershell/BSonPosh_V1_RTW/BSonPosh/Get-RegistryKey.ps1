function Get-RegistryKey 
{
        
    <#
        .Synopsis 
            Gets the registry key provide by Path.
            
        .Description
            Gets the registry key provide by Path.
                        
        .Parameter Path 
            Path to the key.
            
        .Parameter ComputerName 
            Computer to get the registry key from.
            
        .Parameter Recurse 
            Recursively returns registry keys starting from the Path.
        
        .Parameter ReadWrite
            Returns the Registry key in Read Write mode.
            
        .Example
            Get-registrykey HKLM\Software\Adobe
            Description
            -----------
            Returns the Registry key for HKLM\Software\Adobe
            
        .Example
            Get-registrykey HKLM\Software\Adobe -ComputerName MyServer1
            Description
            -----------
            Returns the Registry key for HKLM\Software\Adobe on MyServer1
        
        .Example
            Get-registrykey HKLM\Software\Adobe -Recurse
            Description
            -----------
            Returns the Registry key for HKLM\Software\Adobe and all child keys
                    
        .OUTPUTS
            Microsoft.Win32.RegistryKey
            
        .INPUTS
            System.String
            
        .Link
            New-RegistryKey
            Remove-RegistryKey
            Test-RegistryKey
        .Notes
            NAME:      Get-RegistryKey
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
        
    [Cmdletbinding()]
    Param(
    
        [Parameter(mandatory=$true)]
        [string]$Path,
        
        [Alias("Server")]
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:ComputerName,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Alias("RW")]
        [Parameter()]
        [switch]$ReadWrite
        
    )
    
    Begin 
    {
        
        Write-Verbose " [Get-RegistryKey] :: Start Begin"
        Write-Verbose " [Get-RegistryKey] :: `$Path = $Path"
        Write-Verbose " [Get-RegistryKey] :: Getting `$Hive and `$KeyPath from $Path "
        $PathParts = $Path -split "\\|/",0,"RegexMatch"
        $Hive = $PathParts[0]
        $KeyPath = $PathParts[1..$PathParts.count] -join "\"
        Write-Verbose " [Get-RegistryKey] :: `$Hive = $Hive"
        Write-Verbose " [Get-RegistryKey] :: `$KeyPath = $KeyPath"
        
        Write-Verbose " [Get-RegistryKey] :: End Begin"
        
    }
    
    Process 
    {
    
        Write-Verbose " [Get-RegistryKey] :: Start Process"
        Write-Verbose " [Get-RegistryKey] :: `$ComputerName = $ComputerName"
        
        $RegHive = Get-RegistryHive $hive
        
        if($RegHive -eq 1)
        {
            Write-Host "Invalid Path: $Path, Registry Hive [$hive] is invalid!" -ForegroundColor Red
        }
        else
        {
            Write-Verbose " [Get-RegistryKey] :: `$RegHive = $RegHive"
            
            $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
            Write-Verbose " [Get-RegistryKey] :: `$BaseKey = $BaseKey"
    
            if($ReadWrite)
            {
                try
                {
                    $Key = $BaseKey.OpenSubKey($KeyPath,$true)
                    $Key = $Key | Add-Member -Name "ComputerName" -MemberType NoteProperty -Value $ComputerName -PassThru
                    $Key = $Key | Add-Member -Name "Hive" -MemberType NoteProperty -Value $RegHive -PassThru 
                    $Key = $Key | Add-Member -Name "Path" -MemberType NoteProperty -Value $KeyPath -PassThru
                    $Key.PSTypeNames.Clear()
                    $Key.PSTypeNames.Add('BSonPosh.Registry.Key')
                    $Key
                }
                catch
                {
                    Write-Verbose " [Get-RegistryKey] ::  ERROR :: Unable to Open Key:$KeyPath in $KeyPath with RW Access"
                }
                
            }
            else
            {
                try
                {
                    $Key = $BaseKey.OpenSubKey("$KeyPath")
                    if($Key)
                    {
                        $Key = $Key | Add-Member -Name "ComputerName" -MemberType NoteProperty -Value $ComputerName -PassThru
                        $Key = $Key | Add-Member -Name "Hive" -MemberType NoteProperty -Value $RegHive -PassThru 
                        $Key = $Key | Add-Member -Name "Path" -MemberType NoteProperty -Value $KeyPath -PassThru
                        $Key.PSTypeNames.Clear()
                        $Key.PSTypeNames.Add('BSonPosh.Registry.Key')
                        $Key
                    }
                }
                catch
                {
                    Write-Verbose " [Get-RegistryKey] ::  ERROR :: Unable to Open SubKey:$Name in $KeyPath"
                }
            }
            
            if($Recurse)
            {
                Write-Verbose " [Get-RegistryKey] :: Recurse Passed: Processing Subkeys of [$($Key.Name)]"
                $Key
                $SubKeyNames = $Key.GetSubKeyNames()
                foreach($Name in $SubKeyNames)
                {
                    try
                    {
                        $SubKey = $Key.OpenSubKey($Name)
                        if($SubKey.GetSubKeyNames())
                        {
                            Write-Verbose " [Get-RegistryKey] :: Calling [Get-RegistryKey] for [$($SubKey.Name)]"
                            Get-RegistryKey -ComputerName $ComputerName -Path $SubKey.Name -Recurse
                        }
                        else
                        {
                            Get-RegistryKey -ComputerName $ComputerName -Path $SubKey.Name 
                        }
                    }
                    catch
                    {
                        Write-Verbose " [Get-RegistryKey] ::  ERROR :: Write-Host Unable to Open SubKey:$Name in $($Key.Name)"
                    }
                }
            }
            else
            {
                $Key
            }
        }
        Write-Verbose " [Get-RegistryKey] :: End Process"
    
    }
}
    
