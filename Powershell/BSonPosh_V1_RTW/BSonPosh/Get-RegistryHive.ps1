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
    
