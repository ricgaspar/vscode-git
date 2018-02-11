#------------------------------------------------------------------------------------------
# 21-09-2017
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
        [datetime]$DeploymentAvailableDateTime,                
        [parameter(Mandatory=$true)]       
        [datetime]$DeploymentExpireDateime        
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

        $deployment = New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $SoftwareUpdateGroupName -CollectionName $CollectionName `
            -DeploymentName $deploymentname -AvailableDateTime $DeploymentAvailableDateTime -DeadlineDateTime $DeploymentExpireDateime `
            -AllowRestart $false -RestartServer $true -RestartWorkstation $false -DeploymentType Required `
            -TimeBasedOn LocalTime -VerbosityLevel OnlyErrorMessages `
            -UserNotification DisplayAll `
            -SoftwareInstallation $true -RequirePostRebootFullScan $true -AcceptEula -SendWakeupPacket $true                     

        # UserNotification: DisplayAll, DisplaySoftwareCenterOnly, HideAll

        Write-Host "AssignmentName $($deployment.AssignmentName)"
            
        Set-Location C:
    }
}    

#------------------------------------------------------------------------------------------
clear
$SiteServer = 's007.nedcar.nl'

# Define collections to deploy updates to.
$Collections = @('Software updates clients | All Office clients cummulative')

# Which Software update groups are deployed?
$Sugs = @('Updates 2011', `
'Updates 2012', `
'Updates 2013', `
'Updates 2014', `
'Updates 2015', `
'Updates 2016', `
'Updates 2017', `
'Updates 2017-A', `
'Updates 2017-B', `
'Updates 2018-A')

# $Sugs = @('Updates 2011')

$DeploymentAvailableDateTime = [datetime]('01/26/2018 12:00')
$DeploymentExpireDateime     = [datetime]('02/02/2018 12:00')

ForEach($CollectionName in $Collections) {
    Foreach( $SoftwareUpdateGroupName in $Sugs) {       
        Write-Host "Deploy group: [$SoftwareUpdateGroupName] to [$CollectionName]"

        # Deploy SUG to Collection
        DeployUpdateGroup -SiteServer $SiteServer -SoftwareUpdateGroupName $SoftwareUpdateGroupName -CollectionName $CollectionName `
            -DeploymentAvailableDateTime $DeploymentAvailableDateTime -DeploymentExpireDateime $DeploymentExpireDateime            
    }
}