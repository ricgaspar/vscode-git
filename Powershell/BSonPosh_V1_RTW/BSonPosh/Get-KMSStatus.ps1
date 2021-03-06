function Get-KMSStatus
{

    <#
        .Synopsis 
            Gets the KMS status from the Computer Name specified.
            
        .Description
            Gets the KMS status from the Computer Name specified (Default local host.) Returns a custom object (BSonPosh.KMS.Status)
            
        .Parameter ComputerName
            Computer to get the KMS Status for.
        
        .Example
            Get-KMSStatus mypc
            Description
            -----------
            Returns a KMS status object for Computer 'mypc'
    
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            Get-KMSActivationDetail
            Get-KMSServer
            
        .Notes
            NAME:      Get-KMSStatus
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$ComputerName = $Env:COMPUTERNAME
    )
    Process 
    {
    
        Write-Verbose " [Get-KMSStatus] :: Process Start"
        if($ComputerName -match "(.*)(\$)$")
        {
            $ComputerName = $ComputerName -replace "(.*)(\$)$",'$1'
        }
        $Query = "Select * FROM SoftwareLicensingProduct WHERE Description LIKE '%VOLUME_KMSCLIENT%'"
        Write-Verbose " [Get-KMSStatus] :: ComputerName = $ComputerName"
        Write-Verbose " [Get-KMSStatus] :: Query = $Query"
        try
        {
            Write-Verbose " [Get-KMSStatus] :: Calling WMI"
            $WMIResult = Get-WmiObject -ComputerName $ComputerName -query $Query
            foreach($result in $WMIResult)
            {
                Write-Verbose " [Get-KMSStatus] :: Creating Hash Table"
                $myobj = @{}
                Write-Verbose " [Get-KMSStatus] :: Setting ComputerName to $ComputerName"
                $myobj.ComputerName = $ComputerName
                Write-Verbose " [Get-KMSStatus] :: Setting KMSServer to $($result.KeyManagementServiceMachine)"
                $myobj.KMSServer = $result.KeyManagementServiceMachine
                Write-Verbose " [Get-KMSStatus] :: Setting KMSPort to $($result.KeyManagementServicePort)"
                $myobj.KMSPort = $result.KeyManagementServicePort
                Write-Verbose " [Get-KMSStatus] :: Setting LicenseFamily to $($result.LicenseFamily)"
                $myobj.LicenseFamily = $result.LicenseFamily
                Write-Verbose " [Get-KMSStatus] :: Setting Status to $($result.LicenseStatus)"
                $myobj.Status = ConvertTo-KMSStatus $result.LicenseStatus
                Write-Verbose " [Get-KMSStatus] :: Creating Object"
    
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('BSonPosh.KMS.Status')
                $obj
            }
        }
        catch
        {
            Write-Verbose " [Get-KMSStatus] :: Error - $($Error[0])"
        }
    
    }

}