# ---------------------------------------------------------
Import-Module VNB_PSLib

Function Get-SMSSiteCode {
    [Cmdletbinding()]
    Param (
        [Parameter()]
        [string]
        $SiteServer
    )
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
            return $SiteCode
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
}

function Get-DeviceCollection {
    [Cmdletbinding()]
    Param (
        [Parameter()]
        [string]$SiteServer,
        [Parameter()]
        [string]$SiteCode,
        [Parameter()]
        [string]$MString
    )
    $collections = @()
    Get-WmiObject -name root\sms\site_$SiteCode -class sms_collection -comp $SiteServer | ForEach-Object {
        $collection = [wmi]$_.__path
        if ($collection.Name -Match $MString -and $collection.collectionid -notlike 'sms*') {
            $collections += $collection.name
        }
    }
    return $collections
}


Clear-Host

try {
    Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
}
catch [System.UnauthorizedAccessException] {
    Write-Warning -Message "Access denied" ; break
}
catch [System.Exception] {
    Write-Warning "Unable to load the Configuration Manager Powershell module from $env:SMS_ADMIN_UI_PATH" ; break
}

$ScriptName = $myInvocation.MyCommand.name
$GlobLog = Init-Log -LogFileName "SCCM-UpdateDeviceCollection"
Echo-Log ("=" * 60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$SiteServer = 's007.nedcar.nl'
$SiteCode = Get-SMSSiteCode -SiteServer $SiteServer

$MString = 'Hardware Hewlett Packard'
$Collections = Get-DeviceCollection -SiteServer $SiteServer -SiteCode $SiteCode -MString $MString
$Collections | ForEach-Object {
    $collection = Get-WmiObject -name root\sms\site_$sitecode -class sms_collection -comp $SiteServer -filter "name = '$_'"
    #$collection.psbase()
    $Name = $collection.Name
    $Name = $Name -Replace 'Hardware Hewlett Packard -', 'Hardware | HP |'
    Write-Host "$Name"
    $Collection.Name = $Name
    $collection.put() | out-null
}


# We are done.
Echo-Log ("-" * 60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Close-LogSystem