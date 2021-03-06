function Search-Registry 
{
        
    <#
        .Synopsis 
            Searchs the Registry.
            
        .Description
            Searchs the Registry.
                        
        .Parameter Filter 
            The RegEx filter you want to search for.
            
        .Parameter Name 
            Name of the Key or Value you want to search for.
        
        .Parameter Value
            Value to search for (Registry Values only.)
            
        .Parameter Path
            Base of the Search. Should be in this format: "Software\Microsoft\..." See the Examples for specific exampl
    es.
            
        .Parameter Hive
            The Base Hive to search in (Default to LocalMachine.)
            
        .Parameter ComputerName 
            Computer to search.
            
        .Parameter KeyOnly
            Only returns Registry Keys. Not valid with -value parameter.
            
        .Example
            Search-Registry -Hive HKLM -Filter "Powershell" -Path "SOFTWARE\Clients"
            Description
            -----------
            Searchs the Registry for Keys or Values that match 'Powershell" in path "SOFTWARE\Clients"
            
        .Example
            Search-Registry -Hive HKLM -Filter "Powershell" -Path "SOFTWARE\Clients" -computername MyServer1
            Description
            -----------
            Searchs the Registry for Keys or Values that match 'Powershell" in path "SOFTWARE\Clients" on MyServer1
            
        .Example
            Search-Registry -Hive HKLM -Name "Powershell" -Path "SOFTWARE\Clients"
            Description
            -----------
            Searchs the Registry keys and values with name 'Powershell' in "SOFTWARE\Clients"
            
        .Example
            Search-Registry -Hive HKLM -Name "Powershell" -Path "SOFTWARE\Clients" -KeyOnly
            Description
            -----------
            Searchs the Registry keys with name 'Powershell' in "SOFTWARE\Clients"
        
        .Example
            Search-Registry -Hive HKLM -Value "Powershell" -Path "SOFTWARE\Clients"
            Description
            -----------
            Searchs the Registry Values with Value of 'Powershell' in "SOFTWARE\Clients"
            
        .OUTPUTS
            Microsoft.Win32.RegistryKey
            
        .INPUTS
            System.String
            
        .Link
            Get-RegistryKey
            Get-RegistryValue
            Test-RegistryKey
        
        .Notes
            NAME:      Search-Registry
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
        
    [Cmdletbinding(DefaultParameterSetName="ByFilter")]
    Param(
        [Parameter(ParameterSetName="ByFilter",Position=0)]
        [string]$Filter= ".*",
        
        [Parameter(ParameterSetName="ByName",Position=0)]
        [string]$Name,
        
        [Parameter(ParameterSetName="ByValue",Position=0)]
        [string]$Value,
        
        [Parameter()]
        [string]$Path,
        
        [Parameter()]
        [string]$Hive = "LocalMachine",
        
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME,
            
        [Parameter()]
        [switch]$KeyOnly
    )
    Begin 
    {
    
        Write-Verbose " [Search-Registry] :: Start Begin"
        
        Write-Verbose " [Search-Registry] :: Active Parameter Set $($PSCmdlet.ParameterSetName)"
        switch ($PSCmdlet.ParameterSetName)
        {
            "ByFilter"    {Write-Verbose " [Search-Registry] :: `$Filter = $Filter"}
            "ByName"    {Write-Verbose " [Search-Registry] :: `$Name = $Name"}
            "ByValue"    {Write-Verbose " [Search-Registry] :: `$Value = $Value"}
        }
        $RegHive = Get-RegistryHive $Hive
        Write-Verbose " [Search-Registry] :: `$Hive = $RegHive"
        Write-Verbose " [Search-Registry] :: `$KeyOnly = $KeyOnly"
        
        Write-Verbose " [Search-Registry] :: End Begin"
    
    }
    
    Process 
    {
    
        Write-Verbose " [Search-Registry] :: Start Process"
        
        Write-Verbose " [Search-Registry] :: `$ComputerName = $ComputerName"
        switch ($PSCmdlet.ParameterSetName)
        {
            "ByFilter"    {
                            if($KeyOnly)
                            {
                                if($Path -and (Test-RegistryKey "$RegHive\$Path"))
                                {
                                    Get-RegistryKey -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -match "$Filter"}
                                }
                                else
                                {
                                $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
                                foreach($SubKeyName in $BaseKey.GetSubKeyNames())
                                {
                                    try
                                    {
                                        $SubKey = $BaseKey.OpenSubKey($SubKeyName,$true)
                                        Get-RegistryKey -Path $SubKey.Name -ComputerName $ComputerName -Recurse | ?{$_.Name -match "$Filter"}
                                    }
                                    catch
                                    {
                                        Write-Host "Access Error on Key [$SubKeyName]... skipping."
                                    }
                                }
                                }
                            }
                            else
                            {
                                if($Path -and (Test-RegistryKey "$RegHive\$Path"))
                                {
                                    Get-RegistryKey -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -match "$Filter"}
                                    Get-RegistryValue -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -match "$Filter"}
                                }
                                else
                                {
                                    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
                                    foreach($SubKeyName in $BaseKey.GetSubKeyNames())
                                    {
                                        try
                                        {
                                            $SubKey = $BaseKey.OpenSubKey($SubKeyName,$true)
                                            Get-RegistryKey -Path $SubKey.Name -ComputerName $ComputerName -Recurse | ?{$_.Name -match "$Filter"}
                                            Get-RegistryValue -Path $SubKey.Name -ComputerName $ComputerName -Recurse | ?{$_.Name -match "$Filter"}
                                        }
                                        catch
                                        {
                                            Write-Host "Access Error on Key [$SubKeyName]... skipping."
                                        }
                                    }
                                }
                            }
                        }
            "ByName"    {
                            if($KeyOnly)
                            {
                                if($Path -and (Test-RegistryKey "$RegHive\$Path"))
                                {
                                    $NameFilter = "^.*\\{0}$" -f $Name
                                    Get-RegistryKey -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -match $NameFilter}
                                }
                                else
                                {
                                    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
                                    foreach($SubKeyName in $BaseKey.GetSubKeyNames())
                                    {
                                        try
                                        {
                                            $SubKey = $BaseKey.OpenSubKey($SubKeyName,$true)
                                            $NameFilter = "^.*\\{0}$" -f $Name
                                            Get-RegistryKey -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -match $NameFilter}
                                        }
                                        catch
                                        {
                                            Write-Host "Access Error on Key [$SubKeyName]... skipping."
                                        }
                                    }
                                }
                            }
                            else
                            {
                                if($Path -and (Test-RegistryKey "$RegHive\$Path"))
                                {
                                    $NameFilter = "^.*\\{0}$" -f $Name
                                    Get-RegistryKey -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -match $NameFilter}
                                    Get-RegistryValue -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -eq $Name}
                                }
                                else
                                {
                                    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
                                    foreach($SubKeyName in $BaseKey.GetSubKeyNames())
                                    {
                                        try
                                        {
                                            $SubKey = $BaseKey.OpenSubKey($SubKeyName,$true)
                                            $NameFilter = "^.*\\{0}$" -f $Name
                                            Get-RegistryKey -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Name -match $NameFilter}
                                            Get-RegistryValue -Path $SubKey.Name -ComputerName $ComputerName -Recurse | ?{$_.Name -eq $Name}
                                        }
                                        catch
                                        {
                                            Write-Host "Access Error on Key [$SubKeyName]... skipping."
                                        }
                                    }
                                }
                            }
                        }
            "ByValue"    {
                            if($Path -and (Test-RegistryKey "$RegHive\$Path"))
                            {
                                Get-RegistryValue -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Value -eq $Value}
                            }
                            else
                            {
                                $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
                                foreach($SubKeyName in $BaseKey.GetSubKeyNames())
                                {
                                    try
                                    {
                                        $SubKey = $BaseKey.OpenSubKey($SubKeyName,$true)
                                        Get-RegistryValue -Path "$RegHive\$Path" -ComputerName $ComputerName -Recurse | ?{$_.Value -eq $Value}
                                    }
                                    catch
                                    {
                                        Write-Host "Access Error on Key [$SubKeyName]... skipping."
                                    }
                                }
                            }
                        }
        }
        
        Write-Verbose " [Search-Registry] :: End Process"
    
    }
}
    
