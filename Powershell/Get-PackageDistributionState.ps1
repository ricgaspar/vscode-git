# ---------------------------------------------------------
# Check for distribution errors of Software Update deployment packs.
#
# Marcel Jussen
# 10-04-2017
# ---------------------------------------------------------


# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop
# ---------------------------------------------------------

$ScriptName = $myInvocation.MyCommand.name

$logfile = "SCCM Check Software Updates deployment package distribution"
$GlobLog = New-LogFile -LogFileName $logfile
Echo-Log ("=" * 60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

# Site configuration
$SiteCode = "VNB" # Site code
$ProviderMachineName = "s007.nedcar.nl" # SMS Provider machine name

# Customizations
$initParams = @{}
$initParams.Add("Verbose", $False)
$initParams.Add("ErrorAction", "Stop")

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

Import-Module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1') | Out-Null
$PSD = Get-PSDrive -PSProvider CMSite

$SiteCode = "VNB"
$VerbosePreference = "SilentlyContinue" # Set to SilentlyContinue if you want no output.

# Collect Software Update Deployment packages
Echo-Log "Collection deployment package details."
$UpdatesDeploymentPackages = Get-WmiObject -ComputerName $ProviderMachineName `
    -Namespace root\sms\site_$($SiteCode) -Class SMS_SoftwareUpdatesPackage | `
    Select-Object PackageID,Name,PkgSourcePath,SourceDate,LastRefreshTime

# Collect status of all packages. State 0=normal, 1=updating
Echo-Log "Collection package distribution status."
$PackageStatus = Get-WmiObject -ComputerName $ProviderMachineName -Namespace root\sms\site_$($SiteCode) `
    -Class SMS_PackageStatusDistPointsSummarizer | Select-Object PackageID, State, SummaryDate | `
    Where-Object { $_.State -gt 1}

$FailedCollection = New-Object System.Collections.ArrayList
ForEach ($FailedPackage in $PackageStatus) {
    $Details = $UpdatesDeploymentPackages | Where-Object { ($_.PackageID -eq $FailedPackage.PackageID) }

    $object = New-Object System.Object
    $object | Add-Member –MemberType NoteProperty –Name 'PackageID' –Value $Details.PackageID
    $object | Add-Member –MemberType NoteProperty –Name 'Name' –Value $Details.Name
    $object | Add-Member –MemberType NoteProperty –Name 'PkgSourcePath' –Value $Details.PkgSourcePath
    $object | Add-Member –MemberType NoteProperty –Name 'SourceDate' –Value $Details.SourceDate
    $object | Add-Member –MemberType NoteProperty –Name 'LastRefreshTime' –Value $Details.LastRefreshTime
    $object | Add-Member –MemberType NoteProperty –Name 'SummaryDate' –Value $FailedPackage.SummaryDate
    $object | Add-Member –MemberType NoteProperty –Name 'State' –Value $FailedPackage.State

    $FailedCollection.Add($object) | Out-Null
}

# Create log file with failed packages.
if ($FailedCollection.count -gt 0) {
    Echo-Log "ERROR: Failed distribution packages are found."
    $PackLog = 'C:\Logboek\SCCM_FailedUpdatePackagesx.log'
    Echo-Log "       See: $PackLog"

    Remove-Item -Path $PackLog -Force -ErrorAction SilentlyContinue
    "" | Out-File $PackLog -Append -NoClobber
    "Please restart WMI service on the distribution point server (S008) and update the distribution points." | Out-File $PackLog -Append -NoClobber
    "" | Out-File $PackLog -Append -NoClobber
    "" | Out-File $PackLog -Append -NoClobber
    $FailedCollection | Where-Object { $_.PackageID -ne $null } | Format-Table -Auto | Out-File $PackLog -Append -NoClobber

    $MainTitle = "SCCM Error: Software updates package distribution failed."
    $Title = $MainTitle

    $computername = $Env:computername
    $SMTPRelayAddress = "mail.vdlnedcar.nl"
    $SendFrom = "SCCM Software Updates <$computername@vdlnedcar.nl>"
    $SendTo = "m.jussen@vdlnedcar.nl"

    Echo-Log "Send email to: $SendTo"
    Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer $Global:SMTPRelayAddress -ToAddress $SendTo -Subject $Maintitle -LogFile $PackLog -Headline $Title
}
else {
    Echo-Log "No problems with the software updates deloyment packages are found."
}

Echo-Log ("-" * 60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("=" * 60)

