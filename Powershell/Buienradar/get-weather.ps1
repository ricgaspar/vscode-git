# =========================================================
<#
.SYNOPSIS
    Collection weather information from WUnderground

.CREATED_BY
	Marcel Jussen

.CREATE_DATE
	23-07-2015

.CHANGE_DATE
	10-08-2016
 
.DESCRIPTION
    Collect weather information and store results in WU database
#>
# =========================================================
#-requires 3.0

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------


Function Send-Observation {
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$True)]
		[string]
		$UDLConnection,
				
		[parameter(Mandatory=$False)]
		[string]
		$Computername = $env:COMPUTERNAME,
		
		[parameter(Mandatory=$False)]
		[bool]
		$Erase = $True
	)
	
	
	
	# API Key belongs to mjussen@gmail.com
	$wuKEY = "00140329959e4101"

	#
	# Collection current weather conditions
	#

    # Born
    # $wuLocation = 'zmw:00000.7.06380'

    # Maastricht    
    $wuLocation = 'zmw:00000.168.06379'
	
	# Conditions URL 
	$weatherurl = "http://api.wunderground.com/api/$wuKEY/conditions/lang:NL/q/$wuLocation.xml"	
	
	try {
		Echo-Log "Creating .NET web client object."
		$Webclient = new-object System.Net.WebClient
        # Enable proxy authentication with user credentials
        $Webclient.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials
		$Webclient.Encoding = [System.Text.Encoding]::UTF8
		
		Echo-Log "Downloading WU Conditions data."
		Echo-Log "Using URL: $($weatherurl)"
		$xmlConditionsData = [xml]$Webclient.DownloadString($weatherurl)
		
		# Forecast URL 
		$weatherurl = "http://api.wunderground.com/api/$wuKEY/forecast/lang:NL/q/$wuLocation.xml"
		Echo-Log "Downloading WU Forecast data."
		Echo-Log "Using URL: $($weatherurl)"
		$xmlForecastData = [xml]$Webclient.DownloadString($weatherurl)	
	}
	catch {
		Echo-Log "ERROR: Retrieve XML data from wunderground.com has failed!"
	}	
	
	if ($xmlConditionsData) {			
		# Erase old data registered by this computer
		$Erase = $true
		
		# Form data record
		$ObjectName = 'WU_Location'
		$ObjectData = $xmlConditionsData.response.current_observation.display_location
		if($ObjectData) {
			Echo-Log "Location: $($ObjectData.full) $($ObjectData.country)"
			# Create table if it does not exist
			$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			
			Echo-Log "Sending location data to table $ObjectName"
			# Create new record with data 
			Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
		}
		
		# Form data record		
		$ObjectName = 'WU_Observation'
		$ObjectData = $xmlConditionsData.response.current_observation
		if($ObjectData) {
			Echo-Log "Observation: $($ObjectData.station_id) $($ObjectData.observation_time)"
			# Create table if it does not exist
			$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			
			Echo-Log "Sending data to table $ObjectName"
			# Create new record with data 
			Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 					
		}			
				
		# Form forecast records
		$forecast_data = $xmlForecastData.response.forecast.simpleforecast.forecastdays	
		if($forecast_data) {
			$ObjectName = 'WU_Forecast'			
			$forecast_list = $forecast_data.forecastday			
			$Erase = $true
			foreach ($forecastday in $forecast_list) {
				Echo-Log "Forecast data: $($forecastday.date.day)-$($forecastday.date.month)-$($forecastday.date.year). Sending data to table $ObjectName"
								
				$object = New-Object –TypeName PSObject
				$object | Add-Member –MemberType NoteProperty –Name conditions –Value $forecastday.conditions
				$object | Add-Member –MemberType NoteProperty –Name icon –Value $forecastday.icon
				$object | Add-Member –MemberType NoteProperty –Name day –Value $forecastday.date.day
				$object | Add-Member –MemberType NoteProperty –Name month –Value $forecastday.date.month
				$object | Add-Member –MemberType NoteProperty –Name year –Value $forecastday.date.year
				$object | Add-Member –MemberType NoteProperty –Name weekday –Value $forecastday.date.weekday
				$object | Add-Member –MemberType NoteProperty –Name weekday_short –Value $forecastday.date.weekday_short
				$object | Add-Member –MemberType NoteProperty –Name high_celcius –Value $forecastday.high.celsius
				$object | Add-Member –MemberType NoteProperty –Name low_celcius –Value $forecastday.low.celsius
				$object | Add-Member –MemberType NoteProperty –Name avehumidity –Value $forecastday.avehumidity				
				$object | Add-Member –MemberType NoteProperty –Name qpf_allday_mm –Value $forecastday.qpf_allday.mm
				$object | Add-Member –MemberType NoteProperty –Name snow_allday_mm –Value $forecastday.snow_allday.mm
				$object | Add-Member –MemberType NoteProperty –Name maxwind_kph –Value $forecastday.maxwind.kph
				$object | Add-Member –MemberType NoteProperty –Name maxwind_dir –Value $forecastday.maxwind.dir
				$object | Add-Member –MemberType NoteProperty –Name maxwind_degrees –Value $forecastday.maxwind.degrees
				$object | Add-Member –MemberType NoteProperty –Name avewind_kph –Value $forecastday.avewind.kph
				$object | Add-Member –MemberType NoteProperty –Name avewind_dir –Value $forecastday.avewind.dir
				$object | Add-Member –MemberType NoteProperty –Name avewind_degrees –Value $forecastday.avewind.degrees
								
				$ObjectData = $object
				$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
				Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
				
				# Set erase to false in order to add all other forecast days to the table.
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
	
	Send-Observation -UDLConnection $UDLConnection -Erase $True	
} else {
	Echo-Log "ERROR: $UDLFile was not found."	
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

# =========================================================
Close-LogSystem