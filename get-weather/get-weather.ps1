# =========================================================
<#
.SYNOPSIS
    Collection weather information from WUnderground

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


	# Conditions URL for Born, Netherlands
	# $weatherurl = "http://api.wunderground.com/api/$wuKEY/conditions/lang:NL/q/zmw:00000.7.06380.xml"
	
	# Conditions URL for Maastricht, Netherlands
	$weatherurl = "http://api.wunderground.com/api/$wuKEY/conditions/lang:NL/q/zmw:00000.1.06380.xml"
	
	try {
		$Webclient = new-object System.Net.WebClient
		$Webclient.Encoding = [System.Text.Encoding]::UTF8
		$xmldata = [xml]$Webclient.DownloadString($weatherurl)		
	}
	catch {
		Echo-Log "ERROR: Retrieve XML data from wunderground.com has failed!"
	}	
	
	if ($xmldata) {
		# Name of the SQL table
		$ObjectName = 'WU_Observation'
		
		# Erase old data registered by this computer
		$Erase = $true
		
		# Form data record
		$ObjectData = $xmldata.response.current_observation
		if($ObjectData) {
			Echo-Log "Weather observation was received. Sending data to table $ObjectName"
			# Create table if it does not exist
			$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			
			# Create new record with data 
			Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase		 					
		}
		
		# Form data record
		$ObjectName = 'WU_Location'
		$ObjectData = $xmldata.response.current_observation.display_location
		if($ObjectData) {
			Echo-Log "Weather location was received. Sending data to table $ObjectName"
			# Create table if it does not exist
			$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
			
			# Create new record with data 
			Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
		}		
		
		# Forecast URL for Born, Netherlands
		$weatherurl = "http://api.wunderground.com/api/$wuKEY/forecast/lang:NL/q/zmw:00000.1.06380.xml"
		$xmldata = [xml](new-object System.Net.WebClient).DownloadString($weatherurl)
		$forecast_data = $xmldata.response.forecast.simpleforecast.forecastdays
	
		if(!$forecast_data) {
			$ObjectName = 'WU_Forecast'
			Echo-Log "Forecast data was received. Sending data to table $ObjectName"
			$forecast_list = $forecast_data.forecastday			
			$Erase = $true
			foreach ($forecastday in $forecast_list) {
								
				$object = New-Object –TypeName PSObject
				$object | Add-Member –MemberType NoteProperty –Name conditions –Value $forecastday.conditions
				$object | Add-Member –MemberType NoteProperty –Name icon –Value $forecastday.icon
				$object | Add-Member –MemberType NoteProperty –Name day –Value $forecastday.date.day
				$object | Add-Member –MemberType NoteProperty –Name month –Value $forecastday.date.month
				$object | Add-Member –MemberType NoteProperty –Name year –Value $forecastday.date.year
				$object | Add-Member –MemberType NoteProperty –Name weekday –Value $forecastday.date.weekday
				$object | Add-Member –MemberType NoteProperty –Name weekday_short –Value $forecastday.date.weekday_short
				$object | Add-Member –MemberType NoteProperty –Name high_celcius –Value $forecastday.high.celsius
				$object | Add-Member –MemberType NoteProperty –Name low_celcius –Value $forecastday.low.celcius
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
				
				# Set erase to false in order to add other forecast days to the table.
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