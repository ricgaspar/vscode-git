
# Site configuration
$SiteCode = "VNB" # Site code
$ProviderMachineName = "s007.nedcar.nl" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

Import-Module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
$PSD = Get-PSDrive -PSProvider CMSite

$SiteCode = "VNB"
$VerbosePreference = "Continue" # Set to SilentlyContinue if you want no output.

$PackageState = Get-WmiObject -ComputerName $ProviderMachineName -Namespace root\sms\site_$($SiteCode) -Class SMS_PackageStatusDistPointsSummarizer | Where-Object {$_.State -ne 0} | Select-Object PackageID, State
ForEach ($Package in $PackageState) {
    $PackageDetails = Get-WmiObject -ComputerName $ProviderMachineName -Namespace root\sms\site_$($SiteCode) -Class SMS_Package | Where-Object { $_.PackageID -eq $Package.PackageID} | Select-Object PackageID, Name, PkgSourcePath
    $PackageDetails | Add-Member -NotePropertyName State -NotePropertyValue $Package.State
    $PackageDetails
}