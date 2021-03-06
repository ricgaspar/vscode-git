Configuration SimpleMetaConfigurationForPull 
{ 
    Param(
        [Parameter(Mandatory=$True)]
        [String]$NodeGUID
    )

	LocalConfigurationManager 
    { 
		ConfigurationID = $NodeGUID;
		RefreshMode = "PULL";
		DownloadManagerName = "WebDownloadManager";
		RebootNodeIfNeeded = $true;
		RefreshFrequencyMins = 30;
		ConfigurationModeFrequencyMins = 30; 
		ConfigurationMode = "ApplyAndAutoCorrect";
		DownloadManagerCustomData = @{ServerUrl = "http://s031.nedcar.nl:8080/PSDSCPullServer.svc"; AllowUnsecureConnection = “TRUE”}
    } 
}  

# Read DSC GUID information
$ConfigTable = "\\S031.nedcar.nl\NCSTD$\DSC\DSCNodeConfigs.csv"
$data = import-csv $ConfigTable -header("NodeName","NodeGUID")

# Configure Pull configuration on local computer
SimpleMetaConfigurationForPull -NodeGUID ($data | where-object {$_."NodeName" -eq $env:COMPUTERNAME}).NodeGUID -Output "." 

$FilePath = (Get-Location -PSProvider FileSystem).Path + "\SimpleMetaConfigurationForPull"
Set-DscLocalConfigurationManager -ComputerName "localhost" -Path $FilePath -Verbose

