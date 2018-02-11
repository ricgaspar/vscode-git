# This script is designed to ensure consistent membership of the reporting software update group.
# In this version it is assumed there is only one reporting software update group.  A reporting software
# update group is assumed to never be deployed.  Accordingly, The script will first check to see if the 
# reporting software update group is deployed.  If so the script will display an error and exit.
# If no error then the updates in every other software update group will be reviewed and added to the
# reporting software update group.  There is no check to see if the update is already in the reporting
# software update group because if it is it won't be added twice.

Param(
    [Parameter(Mandatory = $true)]
    $SiteServerName,
    [Parameter(Mandatory = $true)]
    $SiteCode,
    [Parameter(Mandatory = $true)]
    $ReportingUpdateGroup
    )

Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

# Connect to discovered top level site.
cd $SiteCode":"

# Check to see if the reporting software update group is deployed.  If so, exit.
If ((Get-CMSoftwareUpdateGroup -Name $ReportingUpdateGroup).IsDeployed -eq $true)
{
    write-host "Reporting Software Update Group is deployed.  This is not allowed.  Exiting."
    exit
}

# Get all of the software update groups currently configured.  This list will be used for pupulating the reporting
# software update group.
$AllSoftwareUpdateGroups = Get-CMSoftwareUpdateGroup

# Work through each software update group and add all updates from each to the reporting software update group.
ForEach ($UpdateGroup in $AllSoftwareUpdateGroups)
{
    # As long as the update group being handled is not the reporting software update group, proceed to process.
    If ($UpdateGroup.LocalizedDisplayName -ne $ReportingUpdateGroup)
    {
        # Get all of the updates from the update group being evaluated.
        $Updates = Get-CMSoftwareUpdate -updategroupname $UpdateGroup.LocalizedDisplayName
        # Loop through each update and add to the reporting software update group
        ForEach ($Update in $Updates)
        {
            Add-CMSoftwareUpdateToGroup -SoftwareUpdateGroupName $ReportingUpdateGroup -SoftwareUpdateID $Update.CI_ID
        }
    }
}