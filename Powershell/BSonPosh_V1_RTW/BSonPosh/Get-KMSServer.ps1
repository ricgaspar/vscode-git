function Get-KMSServer
{
    
    <#
        .Synopsis 
            Gets the KMS Server.
            
        .Description
            Gets a PSCustomObject (BSonPosh.KMS.Server) for the KMS Server.
            
        .Parameter KMS
            KMS Server to get.
            
        .Example
            Get-KMSServer -kms MyKMSServer
            Description
            -----------
            Gets a KMS Server object for 'MyKMSServer'
    
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            Get-KMSActivationDetail
            Get-KMSStatus
            
        .Notes
            NAME:      Get-KMSServer
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$KMS
    )
    if(!$KMS)
    {
        Write-Verbose " [Get-KMSServer] :: No KMS Server Passed... Using Discovery"
        $KMS = Test-KMSServerDiscovery | select -ExpandProperty ComputerName
    }
    try
    {
        Write-Verbose " [Get-KMSServer] :: Querying KMS Service using WMI"
        $KMSService = Get-WmiObject "SoftwareLicensingService" -ComputerName $KMS
        $myobj = @{
            ComputerName            = $KMS
            Version                 = $KMSService.Version
            KMSEnable               = $KMSService.KeyManagementServiceActivationDisabled -eq $false
            CurrentCount            = $KMSService.KeyManagementServiceCurrentCount
            Port                    = $KMSService.KeyManagementServicePort
            DNSPublishing           = $KMSService.KeyManagementServiceDnsPublishing
            TotalRequest            = $KMSService.KeyManagementServiceTotalRequests
            FailedRequest           = $KMSService.KeyManagementServiceFailedRequests
            Unlicensed              = $KMSService.KeyManagementServiceUnlicensedRequests
            Licensed                = $KMSService.KeyManagementServiceLicensedRequests
            InitialGracePeriod      = $KMSService.KeyManagementServiceOOBGraceRequests
            LicenseExpired          = $KMSService.KeyManagementServiceOOTGraceRequests
            NonGenuineGracePeriod   = $KMSService.KeyManagementServiceNonGenuineGraceRequests
            LicenseWithNotification = $KMSService.KeyManagementServiceNotificationRequests
            ActivationInterval      = $KMSService.VLActivationInterval
            RenewalInterval         = $KMSService.VLRenewalInterval
        }
    
        $obj = New-Object PSObject -Property $myobj
        $obj.PSTypeNames.Clear()
        $obj.PSTypeNames.Add('BSonPosh.KMS.Server')
        $obj
    }
    catch
    {
        Write-Verbose " [Get-KMSServer] :: Error: $($Error[0])"
    }

}