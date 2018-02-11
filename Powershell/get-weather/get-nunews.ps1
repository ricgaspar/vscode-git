# =========================================================
<#
.SYNOPSIS
    Collection news information from NU.NL

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	23-07-2015

.CHANGE_DATE
	23-07-2015
 
.DESCRIPTION
    Collect system information and store results in SECDUMP
#>
# =========================================================
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------


Function Send-NewsItems {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
		
		[parameter(Mandatory=$True)]
		[string]
		$Url = "http://www.nu.nl/rss/algemeen",
				
		[parameter(Mandatory=$True)]
		[boolean]
		$Erase = $True
		
	)		
	
	try {
		$Webclient = new-object System.Net.WebClient
		$Webclient.Encoding = [System.Text.Encoding]::UTF8
		$xmldata = [xml]$Webclient.DownloadString($Url)		
	}
	catch {
		Echo-Log "ERROR: Retrieve XML data from wunderground.com has failed!"
	}	
	
	if ($xmldata) {
		# Name of the SQL table
		$ObjectName = 'WU_news_items'						
		$Items = $xmldata.rss.channel.item
		if($Items) {
			Echo-Log "New item data was received. Sending data to table $ObjectName"
			foreach($ObjectData in $Items) {				
				# Add URL to object properties
				$ObjectData | Add-Member -NotePropertyName URL -NotePropertyValue $Url
				$ObjectData | Add-Member -NotePropertyName ItemImage -NotePropertyValue $ObjectData.Enclosure.Url
				
				$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
				Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
				$Erase = $false
			}
		}		
	} else {
		Echo-Log "ERROR: No data to send to SQL database."
	}	

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

# use specific UDL file
$UDLFile = "$ScriptPath\wu.udl"
if((Test-Path $UDLFile)) {
	$UDLConnection = Read-UDLConnectionString $UDLFile	
	
	Send-NewsItems -UDLConnection $UDLConnection -Url "http://www.nu.nl/rss/algemeen" -Erase $True
	Send-NewsItems -UDLConnection $UDLConnection -Url "http://www.nu.nl/rss/auto" -Erase $False
	
} else {
	Echo-Log "ERROR: $UDLFile was not found."	
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)