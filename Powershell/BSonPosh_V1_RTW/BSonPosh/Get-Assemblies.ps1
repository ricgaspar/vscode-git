function Get-Assemblies
{
    [AppDomain]::CurrentDomain.GetAssemblies()
}
    
