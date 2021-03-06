# =========================================================
#
# Marcel Jussen
# 10-2-2016
#
# =========================================================
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

Function Get-SCCM-SiteCode {
	[CmdletBinding()]
    Param (
         [Parameter(Mandatory=$True,HelpMessage="Please Enter Primary Server Site Server")]
                $SiteServer         
         )	
	Try {        		
		# Enable terminating error with ErrorAction
		$providerLocation = gcim -ComputerName $siteServerName -Namespace root\sms SMS_ProviderLocation -filter "ProviderForLocalSite='True'" -ErrorAction Stop
		$providerLocation.SiteCode
    }
    Catch {	
		# Catch terminating error
		$ErrorMessage = $_.Exception.Message
    	$FailedItem = $_.Exception.ItemName
		Write-Host "ERROR $FailedItem $ErrorMessage"
    }
}

Function Export-Applications {

	param (
		$UDLConnection
	)
	
	$Computername = $env:COMPUTERNAME
	$SiteServerName = 's007'
	$SiteCode = Get-SCCM-SiteCode -SiteServer $siteServerName
	
	# ---------------------------------------------------------
	Echo-Log "Gathering application data from $siteServerName"
	$ObjectName = 'VNB_SMS_APPLICATIONS'
	$Erase = $True
	$ObjectData = Get-WmiObject SMS_Application -Namespace "root\SMS\site_$SiteCode" -ComputerName $SiteServerName | ?{$_.IsLatest -eq $true}

	if($ObjectData) {								
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Echo-Log "Send data to database."
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 		
	} else {
		Echo-Log "No data found."
	}
	
	# ---------------------------------------------------------
	Echo-Log "Gathering package data from $siteServerName"
	$ObjectName = 'VNB_SMS_PACKAGE'
	$Erase = $True
	$ObjectData = Get-WmiObject SMS_Package -Namespace "root\SMS\site_$SiteCode" -ComputerName $SiteServerName

	if($ObjectData) {								
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Echo-Log "Send data to database."
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 		
	} else {
		Echo-Log "No data found."
	}
	
	# ---------------------------------------------------------
	Echo-Log "Gathering content data from $siteServerName"	
	$ObjectName = 'VNB_SMS_CONTENT'
	$Erase = $True
	$ObjectData = $null
	$ObjectData = Get-WmiObject SMS_Content -Namespace "root\SMS\site_$SiteCode" -ComputerName $SiteServerName

	if($ObjectData) {								
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Echo-Log "Send data to database."
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 		
	} else {
		Echo-Log "No data found."
	}
	
	# ---------------------------------------------------------
	Echo-Log "Gathering content package data from $siteServerName"	
	$ObjectName = 'VNB_SMS_CONTENTPACKAGE'
	$Erase = $True
	$ObjectData = $null
	$ObjectData = Get-WmiObject SMS_ContentPackage -Namespace "root\SMS\site_$SiteCode" -ComputerName $SiteServerName

	if($ObjectData) {								
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Echo-Log "Send data to database."
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 		
	} else {
		Echo-Log "No data found."
	}
	
	# ---------------------------------------------------------
	Echo-Log "Gathering deployment type data from $siteServerName"	
	$ObjectName = 'VNB_SMS_DEPLOYMENTTYPE'
	$Erase = $True
	$ObjectData = Get-WmiObject SMS_DeploymentType -Namespace "root\SMS\site_$SiteCode" -ComputerName $SiteServerName |	?{$_.IsLatest -eq $true}

	if($ObjectData) {								
		$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
		Echo-Log "Send data to database."
		Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
	} else {
		Echo-Log "No data found."
	}
}

Function Export-SourceFolders {
	param (
		$UDLConnection
	)
	
	$ObjectName = 'VNB_SMS_SOURCEPATH'
	
	$Erase = $True
	$SourcePath = '\\S007\sources$'
	$LeafFolder = Split-Path $SourcePath -Leaf
	$Folders = Get-ChildItem -path $SourcePath -Recurse -errorAction SilentlyContinue | where {$_.psIsContainer -eq $true}	
			
	$ObjectData = $Folders
	$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
	Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
	
	$Erase = $False
	$SourcePath = '\\S007.nedcar.nl\SMS_VNB'	
	$LeafFolder = Split-Path $SourcePath -Leaf
	$Folders = Get-ChildItem -path $SourcePath -Recurse -errorAction SilentlyContinue |	where {$_.psIsContainer -eq $true}		
	
	$ObjectData = $Folders
	$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
	Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
	
	$Erase = $False
	$SourcePath = '\\S008\osd$'	
	$LeafFolder = Split-Path $SourcePath -Leaf
	$Folders = Get-ChildItem -path $SourcePath -Recurse -errorAction SilentlyContinue |	where {$_.psIsContainer -eq $true}		
	
	$ObjectData = $Folders
	$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
	Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
}

# ---------------------------------------------------------
# Start script
cls
$ScriptName = $myInvocation.MyCommand.Name
$ScriptPath = split-path -parent $myInvocation.MyCommand.Path

$GlobLog = Init-Log $ScriptName
Echo-Log ("="*60)
Echo-Log "Started script: $ScriptName"

$Computername = $env:COMPUTERNAME
$Erase = $false

$UDLFile = $glb_UDL
if((Test-Path $UDLFile)) {
	$UDLConnection = Read-UDLConnectionString $UDLFile	

	Export-Applications -UDLConnection $UDLConnection	
	Export-SourceFolders -UDLConnection $UDLConnection
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)