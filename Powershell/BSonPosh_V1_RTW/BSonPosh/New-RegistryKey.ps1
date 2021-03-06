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
    
