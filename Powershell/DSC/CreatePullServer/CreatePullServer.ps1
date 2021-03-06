configuration CreatePullServer
{
  param
  (
    [string[]]$ComputerName = $env:COMPUTERNAME
  )

  Import-DSCResource -ModuleName PSDesiredStateConfiguration
  Import-DSCResource -ModuleName xPSDesiredStateConfiguration

  Node $ComputerName
  {
    WindowsFeature DSCServiceFeature
    {
      Ensure = "Present"
      Name  = "DSC-Service"
    }

    xDscWebService PSDSCPullServer
    {
      Ensure				= "Present"
      EndpointName			= "PSDSCPullServer"
      Port					= 8080
      PhysicalPath			= "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
      CertificateThumbPrint = "AllowUnencryptedTraffic"
      ModulePath			= "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"

      # This is the location where your LCM mof configurations must be stored.
      ConfigurationPath		= "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"

      State					= "Started"
      DependsOn				= "[WindowsFeature]DSCServiceFeature"
      UseSecurityBestPractices = $false
    }

    xDscWebService PSDSCComplianceServer
    {
      Ensure				= "Present"
      EndpointName			= "PSDSCComplianceServer"
      Port					= 9080
      PhysicalPath			= "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
      CertificateThumbPrint = "AllowUnencryptedTraffic"
      State					= "Started"     
      DependsOn				= ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
      UseSecurityBestPractices = $false
    }
  }
}

# Create a DCS Pull Server mof on the localhost 
CreatePullServer -Verbose -Output "."