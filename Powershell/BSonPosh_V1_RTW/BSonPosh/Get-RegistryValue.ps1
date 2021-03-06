function Get-RegistryValue
{
    
    <#
        .Synopsis 
            Get the value for given the registry value.
            
        .Description
            Get the value for given the registry value.
                        
        .Parameter Path 
            Path to the key that contains the value.
            
        .Parameter Name 
            Name of the Value to check.
            
        .Parameter ComputerName 
            Computer to get value.
            
        .Parameter Recurse 
            Recursively gets the Values on the given key.
            
        .Parameter Default 
            Returns the default value for the Value.
        
        .Example
            Get-RegistryValue HKLM\SOFTWARE\Adobe\SwInstall -Name State 
            Description
            -----------
            Returns value of State under HKLM\SOFTWARE\Adobe\SwInstall.
            
        .Example
            Get-RegistryValue HKLM\Software\Adobe -Name State -ComputerName MyServer1
            Description
            -----------
            Returns value of State under HKLM\SOFTWARE\Adobe\SwInstall on MyServer1
            
        .Example
            Get-RegistryValue HKLM\Software\Adobe -Recurse
            Description
            -----------
            Returns all the values under HKLM\SOFTWARE\Adobe.
    
        .Example
            Get-RegistryValue HKLM\Software\Adobe -ComputerName MyServer1 -Recurse
            Description
            -----------
            Returns all the values under HKLM\SOFTWARE\Adobe on MyServer1
            
        .Example
            Get-RegistryValue HKLM\Software\Adobe -Default
            Description
            -----------
            Returns the default value for HKLM\SOFTWARE\Adobe.
                    
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            New-RegistryValue
            Remove-RegistryValue
            Test-RegistryValue
            
        .Notes    
            NAME:      Get-RegistryValue
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(mandatory=$true)]
        [string]$Path,
    
        [Parameter()]
        [string]$Name,
        
        [Alias("dnsHostName")]
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:ComputerName,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [switch]$Default
    )
    
    Process
    {
    
        Write-Verbose " [Get-RegistryValue] :: Begin Process"
        Write-Verbose " [Get-RegistryValue] :: Calling Get-RegistryKey -Path $path -ComputerName $ComputerName"
        
        if($Recurse)
        {
            $Keys = Get-RegistryKey -Path $path -ComputerName $ComputerName -Recurse
            foreach($Key in $Keys)
            {
                if($Name)
                {
                    try
                    {
                        Write-Verbose " [Get-RegistryValue] :: Getting Value for [$Name]"
                        $myobj = @{} #| Select ComputerName,Name,Value,Type,Path
                        $myobj.ComputerName = $ComputerName
                        $myobj.Name = $Name
                        $myobj.value = $Key.GetValue($Name)
                        $myobj.Type = $Key.GetValueKind($Name)
                        $myobj.path = $Key
                        
                        $obj = New-Object PSCustomObject -Property $myobj
                        $obj.PSTypeNames.Clear()
                        $obj.PSTypeNames.Add('BSonPosh.Registry.Value')
                        $obj
                    }
                    catch
                    {
                        Write-Verbose " [Get-RegistryValue] ::  ERROR :: Unable to Get Value for:$Name in $($Key.Name)"
                    }
                
                }
                elseif($Default)
                {
                    try
                    {
                        Write-Verbose " [Get-RegistryValue] :: Getting Value for [(Default)]"
                        $myobj = @{} #"" | Select ComputerName,Name,Value,Type,Path
                        $myobj.ComputerName = $ComputerName
                        $myobj.Name = "(Default)"
                        $myobj.value = if($Key.GetValue("")){$Key.GetValue("")}else{"EMPTY"}
                        $myobj.Type = if($Key.GetValue("")){$Key.GetValueKind("")}else{"N/A"}
                        $myobj.path = $Key
                        
                        $obj = New-Object PSCustomObject -Property $myobj
                        $obj.PSTypeNames.Clear()
                        $obj.PSTypeNames.Add('BSonPosh.Registry.Value')
                        $obj
                    }
                    catch
                    {
                        Write-Verbose " [Get-RegistryValue] ::  ERROR :: Unable to Get Value for:(Default) in $($Key.Name)"
                    }
                }
                else
                {
                    try
                    {
                        Write-Verbose " [Get-RegistryValue] :: Getting all Values for [$Key]"
                        foreach($ValueName in $Key.GetValueNames())
                        {
                            Write-Verbose " [Get-RegistryValue] :: Getting all Value for [$ValueName]"
                            $myobj = @{} #"" | Select ComputerName,Name,Value,Type,Path
                            $myobj.ComputerName = $ComputerName
                            $myobj.Name = if($ValueName -match "^$"){"(Default)"}else{$ValueName}
                            $myobj.value = $Key.GetValue($ValueName)
                            $myobj.Type = $Key.GetValueKind($ValueName)
                            $myobj.path = $Key
                            
                            $obj = New-Object PSCustomObject -Property $myobj
                            $obj.PSTypeNames.Clear()
                            $obj.PSTypeNames.Add('BSonPosh.Registry.Value')
                            $obj
                        }
                    }
                    catch
                    {
                        Write-Verbose " [Get-RegistryValue] ::  ERROR :: Unable to Get Value for:$ValueName in $($Key.Name)"
                    }
                }
            }
        }
        else
        {
            $Key = Get-RegistryKey -Path $path -ComputerName $ComputerName 
            Write-Verbose " [Get-RegistryValue] :: Get-RegistryKey returned $Key"
            if($Name)
            {
                try
                {
                    Write-Verbose " [Get-RegistryValue] :: Getting Value for [$Name]"
                    $myobj = @{} # | Select ComputerName,Name,Value,Type,Path
                    $myobj.ComputerName = $ComputerName
                    $myobj.Name = $Name
                    $myobj.value = $Key.GetValue($Name)
                    $myobj.Type = $Key.GetValueKind($Name)
                    $myobj.path = $Key
                    
                    $obj = New-Object PSCustomObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.Registry.Value')
                    $obj
                }
                catch
                {
                    Write-Verbose " [Get-RegistryValue] ::  ERROR :: Unable to Get Value for:$Name in $($Key.Name)"
                }
            }
            elseif($Default)
            {
                try
                {
                    Write-Verbose " [Get-RegistryValue] :: Getting Value for [(Default)]"
                    $myobj = @{} #"" | Select ComputerName,Name,Value,Type,Path
                    $myobj.ComputerName = $ComputerName
                    $myobj.Name = "(Default)"
                    $myobj.value = if($Key.GetValue("")){$Key.GetValue("")}else{"EMPTY"}
                    $myobj.Type = if($Key.GetValue("")){$Key.GetValueKind("")}else{"N/A"}
                    $myobj.path = $Key
                    
                    $obj = New-Object PSCustomObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.Registry.Value')
                    $obj
                }
                catch
                {
                    Write-Verbose " [Get-RegistryValue] ::  ERROR :: Unable to Get Value for:$Name in $($Key.Name)"
                }
            }
            else
            {
                Write-Verbose " [Get-RegistryValue] :: Getting all Values for [$Key]"
                foreach($ValueName in $Key.GetValueNames())
                {
                    Write-Verbose " [Get-RegistryValue] :: Getting all Value for [$ValueName]"
                    $myobj = @{} #"" | Select ComputerName,Name,Value,Type,Path
                    $myobj.ComputerName = $ComputerName
                    $myobj.Name = if($ValueName -match "^$"){"(Default)"}else{$ValueName}
                    $myobj.value = $Key.GetValue($ValueName)
                    $myobj.Type = $Key.GetValueKind($ValueName)
                    $myobj.path = $Key
                    
                    $obj = New-Object PSCustomObject -Property $myobj
                    $obj.PSTypeNames.Clear()
                    $obj.PSTypeNames.Add('BSonPosh.Registry.Value')
                    $obj
                }
            }
        }
        
        Write-Verbose " [Get-RegistryValue] :: End Process"
    
    }
}
    
