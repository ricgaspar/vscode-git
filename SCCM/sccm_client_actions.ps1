Function Get-SMSSiteCode {
    [Cmdletbinding()]    
    Param (    	
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer     
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

Function Get-SCCM-DeviceCollection
{
	[CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer,

        [parameter(Mandatory=$true,HelpMessage="Device collection ID")]        
        [string]$DeviceCollectionID
    )

	Try{    
        $SiteCode = Get-SMSSiteCode -SiteServer $SiteServer
		$strQuery = "SELECT * FROM SMS_CM_RES_COLL_$DeviceCollectionID"
		Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -ComputerName $SiteServer -Query $strQuery `
			-ErrorAction STOP 
    }
    Catch{
        $_.Exception.Message
    }	 	
}


Function Get-SCCM-AllSystems 
{
	[CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer
    )

	Try{    
        $SiteCode = Get-SMSSiteCode -SiteServer $SiteServer
		$strQuery = 'SELECT * FROM SMS_CM_RES_COLL_SMS00001'
		Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -ComputerName $SiteServer -Query $strQuery `
			-ErrorAction STOP 
    }
    Catch{
        $_.Exception.Message
    }	 	
}

Function Get-SCCM-ClientData 
{
	[CmdletBinding()]
    Param(
		[parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer,
        		
		[Parameter(Mandatory=$True,HelpMessage="Please Enter device name")]
        [string]$DeviceName
    )
	Try {        		
        $SiteCode = Get-SMSSiteCode -SiteServer $SiteServer
		$strQuery = "SELECT * FROM SMS_CM_RES_COLL_SMS00001 where Name='$DeviceName'"
		Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -ComputerName $SiteServer -Query $strQuery `
			-ErrorAction STOP 
    }
    Catch {
        $_.Exception.Message
    }	 	
}

Function Get-DeviceResourceID
{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$SiteServer,
                
        [Parameter(Mandatory=$True,HelpMessage="Please Enter device name")]
        [string]$DeviceName
    )
 
    Try {
         $SiteCode = Get-SMSSiteCode -SiteServer $SiteServer
         Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_R_SYSTEM -Filter "Name='$DeviceName'" `
        	-ErrorAction STOP -Computername $SiteServer	| Select ResourceID	
    }
    Catch {
        $_.Exception.Message
    }
}

Function Get-SCCM-Device-Collections 
{
	[CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")] 
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
        [string]$SiteServer,

        [Parameter(Mandatory=$True,HelpMessage="Please Enter resource id")]
        [string]$ResourceID
    )

	Try{
        $SiteCode = Get-SMSSiteCode -SiteServer $SiteServer

		$ColArray = $null
		$ColIDArray = $null
		$strQuery = "select * from SMS_FullCollectionMembership inner join SMS_Collection on SMS_Collection.CollectionID = SMS_FullCollectionMembership.CollectionID where SMS_FullCollectionMembership.ResourceID like '" + $ResourceID + "'"
		Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -ComputerName $SiteServer -Query $strQuery | ForEach-Object {
			$strQuery = "select * from SMS_ObjectContainerItem inner join SMS_ObjectContainerNode on SMS_ObjectContainerNode.ContainerNodeID = SMS_ObjectContainerItem.ContainerNodeID where SMS_ObjectContainerItem.InstanceKey like '" + $_.SMS_Collection.CollectionID + "'"
			$objWMISearch = Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -ComputerName $SiteServer -Query $strQuery
			$ContainerID = 1
			$ContainerName = "Root"
			foreach ($instance in $objWMISearch){
				$ContainerName = $instance.SMS_ObjectContainerNode.Name
				$ContainerID = $instance.SMS_ObjectContainerNode.ContainerNodeID
			}
			$CompName = $_.SMS_FullCollectionMembership.Name
			$ColArray += ,@($_.SMS_Collection.Name,$ContainerName,$ContainerID)
			
			$ColArray = $ColArray | Sort-Object @{Expression={$_[0]}; Ascending=$true}
			foreach ($instance in $ColArray){
				$CheckNum = 0
				foreach ($inst in $ColIDArray){if ($inst -eq $instance[2]){$CheckNum = 1}}
				if ($CheckNum -eq 0){$ColIDArray += ,@($instance[1],$instance[2])}
			}
			return $ColArray
		}
	}
    Catch{
        $_.Exception.Message
    }
}



Function Execute-SCCMWMIMethod {
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true)]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$Computername = $env:COMPUTERNAME,
                
        [parameter(Mandatory=$False)]
        [string]$ScheduleID = "{00000000-0000-0000-0000-000000000003}"
    )
    try {
        [void](Invoke-WMIMethod -ComputerName $Computername -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule $ScheduleID)
    }
    catch {
        write-host "An error occured while executing trigger $ScheduleID"
    }
}

Function Execute-SCCMAction_FullHWScan {
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true)]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$Computername
    )
    try {
        $HardwareInventoryID= "{00000000-0000-0000-0000-000000000001}"
        Get-WmiObject -ComputerName $Computername -Namespace 'Root\CCM\INVAGT' -Class 'InventoryActionStatus' -Filter "InventoryActionID='$HardwareInventoryID'" | Remove-WmiObject
        Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID $HardwareInventoryID
    }
    catch {
        $_.Exception.Message
    }
}

Function Execute-SCCMAction {
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory=$true)]
        [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})] 
        [string]$Computername
    )
    write-host 'Machine Policy Agent Cleanup'
    Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID "{00000000-0000-0000-0000-000000000040}"

    # write-host 'Application Deployment Evaluation Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Server -ScheduleID "{00000000-0000-0000-0000-000000000121}"

    write-host 'Discovery Data Collection Cycle'
    Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID "{00000000-0000-0000-0000-000000000003}"

    # write-host 'File Collection Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID "{00000000-0000-0000-0000-000000000010}"

    # write-host 'Hardware Inventory Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID "{00000000-0000-0000-0000-000000000001}"

    write-host 'Machine Policy Retrieval Cycle'
    Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000021}"

    write-host 'Machine Policy Evaluation Cycle'
    Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000022}"

    # write-host 'Software Inventory Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000002}"

    # write-host 'Software Metering Usage Report Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000031}"

    # write-host 'Software Update Deployment Evaluation Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000114}"

    # write-host 'Software Update Scan Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000113}"

    write-host 'State Message Refresh'
    Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000111}"

    # write-host 'Windows Installers Source List Update Cycle'
    # Execute-SCCMWMIMethod -ComputerName $Computername -ScheduleID  "{00000000-0000-0000-0000-000000000032}"
    
}

cls

$SiteServer = 's007.nedcar.nl'
$DeviceCollectionID = 'VNB00261'
$Devices = Get-SCCM-DeviceCollection -SiteServer $SiteServer $DeviceCollectionID
foreach($Computer in $Devices) {
    $RemoteComputer = $Computer.Name
    Execute-SCCMAction_FullHWScan -Computername $RemoteComputer
}




