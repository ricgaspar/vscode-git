#
# SCCM ADR test
#
cls

Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

$SiteCode = 'VNB'
$SiteServer = 's007.nedcar.nl'

$computer = $SiteServer
$namespace = "ROOT\SMS\site_VNB" 
$classname = "SMS_AutoDeployment" 

Write-Output "====================================="
Write-Output "COMPUTER : $computer " 
Write-Output "CLASS    : $classname " 
Write-Output "====================================="

Get-WmiObject -Class $classname -ComputerName $computer -Namespace $namespace | 
    Select-Object * -ExcludeProperty PSComputerName, Scope, Path, Options, ClassPath, Properties, SystemProperties, Qualifiers, Site, Container | 
    Format-List -Property [a-z]*