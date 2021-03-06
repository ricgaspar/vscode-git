function Get-KMSActivationDetail
{

    <#
        .Synopsis 
            Gets the Activation Detail from the KMS Server.
            
        .Description
            Gets the Activation Detail from the KMS Server.
            
        .Parameter KMS
            KMS Server to connect to.
            
        .Parameter Filter
            Filter for the Computers to get activation for.
        
        .Parameter After
            The DateTime to start the query from. For example if I only want activations for the last thirty days:
            the date time would be ((Get-Date).AddMonths(-1))
            
        .Parameter Unique
            Only return Unique entries.
            
        .Example
            Get-KMSActivationDetail -kms MyKMSServer
            Description
            -----------
            Get all the activations for the target KMS server.
            
        .Example
            Get-KMSActivationDetail -kms MyKMSServer -filter mypc
            Description
            -----------
            Get all the activations for all the machines that are like "mypc" on the target KMS server.
            
        .Example
            Get-KMSActivationDetail -kms MyKMSServer -After ((Get-Date).AddDays(-1))
            Description
            -----------
            Get all the activations for the last day on the target KMS server.
    
        .Example
            Get-KMSActivationDetail -kms MyKMSServer -unique
            Description
            -----------
            Returns all the unique activate for the targeted KMS server.
            
        .OUTPUTS
            PSCustomObject
            
        .INPUTS
            System.String
            
        .Link
            Get-KMSServer
            Get-KMSStatus
            
        .Notes
            NAME:      Get-KMSActivationDetail
            AUTHOR:    bsonposh
            Website:   http://www.bsonposh.com
            Version:   1
            #Requires -Version 2.0
    #>
    
    [Cmdletbinding()]
    Param(
    
        [Parameter(mandatory=$true)]
        [string]$KMS,
        
        [Parameter()]
        [string]$Filter="*",
        
        [Parameter()]
        [datetime]$After,
        
        [Parameter()]
        [switch]$Unique
        
    )
    Write-Verbose " [Get-KMSActivationDetail] :: Cmdlet Start"
    Write-Verbose " [Get-KMSActivationDetail] :: KMS Server   = $KMS"
    Write-Verbose " [Get-KMSActivationDetail] :: Filter       = $Filter"
    Write-Verbose " [Get-KMSActivationDetail] :: After Date   = $After"
    Write-Verbose " [Get-KMSActivationDetail] :: Unique       = $Unique"
    
    if($After)
    {
        Write-Verbose " [Get-KMSActivationDetail] :: Processing Records after $After"
        $Events = Get-Eventlog -LogName "Key Management Service" -ComputerName $KMS -After $After -Message "*$Filter*"
    }
    else
    {
        Write-Verbose " [Get-KMSActivationDetail] :: Processing Records"
        $Events = Get-Eventlog -LogName "Key Management Service" -ComputerName $KMS -Message "*$Filter*"
    }
    
    Write-Verbose " [Get-KMSActivationDetail] :: Creating Objects Collection"
    $MyObjects = @()
    
    Write-Verbose " [Get-KMSActivationDetail] :: Processing {$($Events.count)} Events"
    foreach($Event in $Events)
    {
        Write-Verbose " [Get-KMSActivationDetail] :: Creating Hash Table [$($Event.Index)]"
        $Message = $Event.Message.Split(",")
        
        $myobj = @{}
        Write-Verbose " [Get-KMSActivationDetail] :: Setting ComputerName to $($Message[3])"
        $myobj.Computername = $Message[3]
        Write-Verbose " [Get-KMSActivationDetail] :: Setting Date to $($Event.TimeGenerated)"
        $myobj.Date = $Event.TimeGenerated
        Write-Verbose " [Get-KMSActivationDetail] :: Creating Custom Object [$($Event.Index)]"
        $MyObjects += New-Object PSObject -Property $myobj
    }
    
    if($Unique)
    {
        Write-Verbose " [Get-KMSActivationDetail] :: Parsing out Unique Objects"
        $UniqueObjects = $MyObjects | Group-Object -Property Computername
        foreach($UniqueObject in $UniqueObjects)
        {
            $myobj = @{}
            $myobj.ComputerName = $UniqueObject.Name
            $myobj.Count = $UniqueObject.count
    
            $obj = New-Object PSObject -Property $myobj
            $obj.PSTypeNames.Clear()
            $obj.PSTypeNames.Add('BSonPosh.KMS.ActivationDetail')
            $obj
        }
        
    }
    else
    {
        $MyObjects
    }

}
