#############################################################################
# Author  : Benoit Lecours 
# Website : www.SystemCenterDudes.com
# Twitter : @scdudes
#
# Version : 1.1
# Created : 2017/04/05
# Modified : 2017/08/31
#
# Purpose : This script delete collections without members and deployments
#
#############################################################################

#Load Configuration Manager PowerShell Module
Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0, $Env:SMS_ADMIN_UI_PATH.Length - 5) + '\ConfigurationManager.psd1') -Force -ErrorAction Stop

# Site configuration
$SiteCode = "VNB" # Site code 
$ProviderMachineName = "S007.nedcar.nl" # SMS Provider machine name

# Connect to the site's drive if it is not already present
if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
}

#Get SiteCode
$SiteCode = Get-PSDrive -PSProvider CMSITE
Write-Host "SiteCode: $($SiteCode)"
Set-location $SiteCode":"

Write-host "This script delete device collections without members and deployments. You will be prompted before each deletion."
Write-host "Built-in collections and users collections are excluded"
Write-host "------------------------------------------------------------------------"
Write-Host "Building Devices Collections List. This may take a couple of minutes..."
Write-host "------------------------------------------------------------------------"

$CollectionList = Get-CmCollection | Where-Object {$_.CollectionID -notlike 'SMS*' -and $_.CollectionType -eq '2' -and $_.MemberCount -eq 0} | Select-Object -Property Name, MemberCount, CollectionID, IsReferenceCollection
#$DeploymentList = Get-CMDeployment | Select-Object -Property CollectionID

Write-Host ("Found " + $CollectionList.Count + " collections without members (MemberCount = 0) `n")
Write-Host ("Analyzing list to find collection without deployments... `n")

foreach ($Collection in $CollectionList) {
    $NumCollectionMembers = $Collection.MemberCount
    $CollectionID = $Collection.CollectionID
    $GetDeployment = Get-CMDeployment | Where-Object {$_.CollectionID -eq $Collection.CollectionID}
        
    # Delete collection if there's no members and no deployment on the collection
    If ($GetDeployment -eq $null) #$NumCollectionMembers -eq 0 -and  {
    # User Prompt
    Write-Host ("Collection " + $Collection.Name + " (" + $Collection.CollectionID + ")" + " has no members and deployments")


}