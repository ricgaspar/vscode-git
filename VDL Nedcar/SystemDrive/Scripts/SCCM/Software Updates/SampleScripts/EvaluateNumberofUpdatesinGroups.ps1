# This script will examine the count of updates in each deployed update group and provide a warning
# when the number of updates in a given group exceeds 900.

Param(
    [Parameter(Mandatory = $true)]
    $SiteServerName,
    [Parameter(Mandatory = $true)]
    $SiteCode
    )

Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

# Connect to discovered top level site
cd $SiteCode":"

$UpdateCount = 0

# Get all of the software update groups current configured.
$SoftwareUpdateGroups = Get-cmsoftwareupdategroup

# Loop through each software update group and check the total number of updates in each.
ForEach ($Group in $SoftwareUpdateGroups)
{
    # Only test update groups that are deployed.  Reporting software update groups may be used
    # in some environments and as long as these groups aren't deployed they can contain greater
    # than 1000 updates.  Accordingly, warning for those groups doesn't apply.
    If ($Group.IsDeployed -eq 'True')
    {
        ForEach ($UpdateID in $Group.Updates)
        {
            $UpdateCount=$UpdateCount + 1
        }

        If ($UpdateCount -gt 900)
        {
            write-host "Current count of updates in update group '"$Group.LocalizedDisplayName"' exceeds 900"
        }
    }
    $UpdateCount = 0
}