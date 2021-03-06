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
    
