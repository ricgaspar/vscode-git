<#
.SYNOPSIS
    VNB Library - Windows Registry

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	28-02-2015
 
.DESCRIPTION
    General purpose functions for Windows Registry
#>

function Get-RegistryHive 
{
    param($HiveName)
    Switch -regex ($HiveName)
    {
        "^(HKCR|ClassesRoot|HKEY_CLASSES_ROOT)$"               {[Microsoft.Win32.RegistryHive]"ClassesRoot";continue}
        "^(HKCU|CurrentUser|HKEY_CURRENTt_USER)$"              {[Microsoft.Win32.RegistryHive]"CurrentUser";continue}
        "^(HKLM|LocalMachine|HKEY_LOCAL_MACHINE)$"          {[Microsoft.Win32.RegistryHive]"LocalMachine";continue} 
        "^(HKU|Users|HKEY_USERS)$"                          {[Microsoft.Win32.RegistryHive]"Users";continue}
        "^(HKCC|CurrentConfig|HKEY_CURRENT_CONFIG)$"          {[Microsoft.Win32.RegistryHive]"CurrentConfig";continue}
        "^(HKPD|PerformanceData|HKEY_PERFORMANCE_DATA)$"    {[Microsoft.Win32.RegistryHive]"PerformanceData";continue}
        Default                                                {1;continue}
    }
}
    
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
    
function New-RegistryKey
{
    
    <#
        .Synopsis 
            Creates a new key in the provide by Path.
            
        .Description
            Creates a new key in the provide by Path.
                        
        .Parameter Path 
            Path to create the key in.
            
        .Parameter ComputerName 
            Computer to the create registry key on.
            
        .Parameter Name 
            Name of the Key to create
        
        .Example
            New-registrykey HKLM\Software\Adobe -Name DeleteMe
            Description
            -----------
            Creates a key called DeleteMe under HKLM\Software\Adobe
            
        .Example
            New-registrykey HKLM\Software\Adobe -Name DeleteMe -ComputerName MyServer1
            Description
            -----------
            Creates a key called DeleteMe under HKLM\Software\Adobe on MyServer1
                    
        .OUTPUTS
            Microsoft.Win32.RegistryKey
            
        .INPUTS
            System.String
            
        .Link
            Get-RegistryKey
            Remove-RegistryKey
            Test-RegistryKey
            
        NAME:      New-RegistryKey
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
        [string]$ComputerName = $Env:ComputerName
    )
    Begin 
    {
    
        Write-Verbose " [New-RegistryKey] :: Start Begin"
        $ReadWrite = [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree
        
        Write-Verbose " [New-RegistryKey] :: `$Path = $Path"
        Write-Verbose " [New-RegistryKey] :: Getting `$Hive and `$KeyPath from $Path "
        $PathParts = $Path -split "\\|/",0,"RegexMatch"
        $Hive = $PathParts[0]
        $KeyPath = $PathParts[1..$PathParts.count] -join "\"
        Write-Verbose " [New-RegistryKey] :: `$Hive = $Hive"
        Write-Verbose " [New-RegistryKey] :: `$KeyPath = $KeyPath"
        
        Write-Verbose " [New-RegistryKey] :: End Begin"
        
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
            $Key = $BaseKey.OpenSubKey($KeyPath,$True)
            if($PSCmdlet.ShouldProcess($ComputerName,"Creating Key [$Name] under $Path"))
            {
                $Key.CreateSubKey($Name,$ReadWrite)
            }
        }
        Write-Verbose " [Get-RegistryKey] :: End Process"
    
    }
}
    
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
    
function Test-RegistryKey 
{
        
    <#
        .Synopsis 
            Test for given the registry key.
            
        .Description
            Test for given the registry key.
                        
        .Parameter Path 
            Path to the key.
            
        .Parameter ComputerName 
            Computer to test the registry key on.
            
        .Example
            Test-registrykey HKLM\Software\Adobe
            Description
            -----------
            Returns $True if the Registry key for HKLM\Software\Adobe
            
        .Example
            Test-registrykey HKLM\Software\Adobe -ComputerName MyServer1
            Description
            -----------
            Returns $True if the Registry key for HKLM\Software\Adobe on MyServer1
                    
        .OUTPUTS
            System.Boolean
            
        .INPUTS
            System.String
            
        .Link
            New-RegistryKey
            Remove-RegistryKey
            Get-RegistryKey
        
        .Notes
            NAME:      Test-RegistryKey
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
    
        [Parameter(ValueFromPipelineByPropertyName=$True,mandatory=$true)]
        [string]$Path,
        
        [alias('dnsHostName')]
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
        
    )
    
    Begin 
    {
    
        Write-Verbose " [Test-RegistryKey] :: Start Begin"
        
        Write-Verbose " [Test-RegistryKey] :: `$Path = $Path"
        Write-Verbose " [Test-RegistryKey] :: Getting `$Hive and `$KeyPath from $Path "
        $PathParts = $Path -split "\\|/",0,"RegexMatch"
        $Hive = $PathParts[0]
        $KeyPath = $PathParts[1..$PathParts.count] -join "\"
        Write-Verbose " [Test-RegistryKey] :: `$Hive = $Hive"
        Write-Verbose " [Test-RegistryKey] :: `$KeyPath = $KeyPath"
        
        Write-Verbose " [Test-RegistryKey] :: End Begin"
    
    }
    
    Process 
    {
    
        Write-Verbose " [Test-RegistryKey] :: Start Process"
        
        Write-Verbose " [Test-RegistryKey] :: `$ComputerName = $ComputerName"
        
        $RegHive = Get-RegistryHive $hive
        
        if($RegHive -eq 1)
        {
            Write-Host "Invalid Path: $Path, Registry Hive [$hive] is invalid!" -ForegroundColor Red
        }
        else
        {
            Write-Verbose " [Test-RegistryKey] :: `$RegHive = $RegHive"
            
            $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegHive,$ComputerName)
            Write-Verbose " [Test-RegistryKey] :: `$BaseKey = $BaseKey"
            
            Try
            {
                $Key = $BaseKey.OpenSubKey($KeyPath) 
                if($Key)
                {
                    $true
                }
                else
                {
                    $false
                }
            }
            catch
            {
                $false
            }
        }
        Write-Verbose " [Test-RegistryKey] :: End Process"
    
    }
}
    


# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *