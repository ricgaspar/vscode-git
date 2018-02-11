#------------------------------------------------------------------------------------------
# 20-10-2015
# Marcel Jussen
#------------------------------------------------------------------------------------------

Function DeployUpdateGroup {
    [CmdletBinding(SupportsShouldProcess=$true)] 
    param ( 
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer, 
        [parameter(Mandatory=$true,HelpMessage="Name of the Updates Deployment Package")] 
        [string]$SoftwareUpdateGroupName,
        [parameter(Mandatory=$true,HelpMessage="Name of the Collection")] 
        [string]$CollectionName,
        [parameter(Mandatory=$true)]
        [datetime]$DeploymentAvailableDay,        
        [parameter(Mandatory=$true)]
        [datetime]$DeploymentAvailableTime,        
        [parameter(Mandatory=$true)]
        [datetime]$DeploymentExpiredDay,        
        [parameter(Mandatory=$true)]
        [datetime]$DeploymentExpireTime        
    ) 

    Begin { 
        # Determine SiteCode from WMI 
        try { 
            Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'" 
            $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop 
            foreach ($SiteCodeObject in $SiteCodeObjects) { 
                if ($SiteCodeObject.ProviderForLocalSite -eq $true) { 
                    $SiteCode = $SiteCodeObject.SiteCode 
                    Write-Debug "SiteCode: $($SiteCode)" 
                } 
            } 
        } 
        catch [Exception] { 
            Throw "Unable to determine SiteCode" 
        } 
    } 

    Process {        
        $ModulePath = (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) + '\ConfigurationManager.psd1'
        Import-Module $ModulePath -Force
        if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
            New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
        }
        $SiteDrive = $SiteCode + ":"
        Set-Location $SiteDrive
        
        $DeploymentName = "$SoftwareUpdateGroupName - $CollectionName"

        Start-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $SoftwareUpdateGroupName -CollectionName $CollectionName -DeploymentName $deploymentname -DeploymentType Required -VerbosityLevel OnlyErrorMessages `
            -TimeBasedOn LocalTime  -DeploymentAvailableDay $DeploymentAvailableDay -DeploymentAvailableTime $DeploymentAvailableTime -DeploymentExpireDay $DeploymentExpiredDay -DeploymentExpireTime $DeploymentExpireTime `
            -Description 'Deployed with Powershell script.' -SoftwareInstallation $True -UserNotification DisplayAll -AllowRestart $false -RestartServer $False -RestartWorkstation $false

            # -SoftwareInstallation: Indicates whether to allow the software update to install, even if the installation occurs outside of a maintenance window.
            # -UserNotification: DisplayAll, DisplaySoftwareCenterOnly, HideAll
            # -AllowRestart: Indicates whether to allow a restart following installation.
            # -RestartServer: Indicates whether to allow a server to restart following a software update. Setting this value to $True prevents the server from restarting.
            # -RestartWorkstation: Indicates whether to allow a workstation to restart following a software update. Setting this value to $True prevents the workstation from restarting.
            

        Set-Location C:
    }
}    

#------------------------------------------------------------------------------------------
cls
$SiteServer = 's007.nedcar.nl'

# Define collections to deploy updates to.
$Collections = @('Software updates - All Clients (cummulative)')

# Which Software update groups are deployed?
$Months = @('01','02','03','04','05','06','07','08','09','10')

$DeploymentAvailableDay = [datetime]('10/16/2015')
$DeploymentAvailableTime = '12:00'
$DeploymentExpiredDay = [datetime]('11/6/2015')
$DeploymentExpireTime = '12:00'

foreach($CollectionName in $Collections) {
    foreach($mnth in $Months) {    
        # Build SUG name
        $SoftwareUpdateGroupName = "Updates $mnth-2015"
        Write-Host "Deploy group: [$SoftwareUpdateGroupName] to [$CollectionName]"

        # Deploy SUG to Collection
        DeployUpdateGroup -SiteServer $SiteServer -SoftwareUpdateGroupName $SoftwareUpdateGroupName -CollectionName $CollectionName `
            -DeploymentAvailableDay $DeploymentAvailableDay -DeploymentAvailableTime $DeploymentAvailableTime `
            -DeploymentExpiredDay $DeploymentExpiredDay -DeploymentExpireTime $DeploymentExpireTime
    }
}