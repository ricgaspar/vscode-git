Function Get-SCCM-AllSystems {
	[CmdletBinding()]
    Param(
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site Server")]
                $SiteServer,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site code")]
                $SiteCode
         )
	Try{        		
		$strQuery = 'SELECT * FROM SMS_CM_RES_COLL_SMS00001'
		Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -ComputerName $SiteServer -Query $strQuery `
			-ErrorAction STOP 
    }
    Catch{
        $_.Exception.Message
    }	 	
}

Function Get-SCCM-ClientData {
	[CmdletBinding()]
    Param(
		[Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site Server")]
                $SiteServer,
		[Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site code")]
                $SiteCode,
		[Parameter(Mandatory=$True,HelpMessage="Please Enter device name")]
                $DeviceName
         )
	Try{        		
		$strQuery = "SELECT * FROM SMS_CM_RES_COLL_SMS00001 where Name='$DeviceName'"
		Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -ComputerName $SiteServer -Query $strQuery `
			-ErrorAction STOP 
    }
    Catch{
        $_.Exception.Message
    }	 	
}

Function Get-DeviceResourceID
{
    [CmdletBinding()]
    Param(
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site Server")]
                $SiteServer,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site code")]
                $SiteCode,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter device name")]
                $DeviceName
         )
 
    Try{
        Get-WmiObject -Namespace "Root\SMS\Site_$SiteCode" -Class SMS_R_SYSTEM -Filter "Name='$DeviceName'" `
        	-ErrorAction STOP -Computername $SiteServer	| Select ResourceID	
    }
    Catch{
        $_.Exception.Message
    }
}

Function Get-SCCM-Device-Collections {
	[CmdletBinding()]
    Param(
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site Server")]
                $SiteServer,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site code")]
                $SiteCode,
         [Parameter(Mandatory=$True,HelpMessage="Please Enter resource id")]
                $ResourceID
         )

	Try{
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

# exit 0

cls

$SCCMSiteCode = 'VNB'
$SCCMSiteServer = 's007.nedcar.nl'

$AllSystems = Get-SCCM-AllSystems -SiteCode $SCCMSiteCode -SiteServer $SCCMSiteServer
$ColArray = $null
foreach($System in $AllSystems) {	
	$Computername = $System.Name
	$collections = Get-SCCM-Device-Collections -SiteCode $SCCMSiteCode -SiteServer $SCCMSiteServer $System.ResourceId 
	$CollCount = $collections.Count 
	if($CollCount -le 15) {		
		write-host "*** ERROR: $computername (collections=$CollCount)"
		$ColArray += ,@($System.Name,$System.ResourceID,$CollCount)
	} else {
		Write-Host "OK $Computername (collections=$CollCount)"
	}
}


