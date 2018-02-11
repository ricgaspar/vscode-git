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
		
	# $buienradar_url = "http://www.buienradar.nl/image?fn=buienradarnl-1x1-ani550-verwachting.gif&type=forecastzozw"
	$buienradar_url = "http://api.buienradar.nl/image/1.0/RadarMapNL?w=350&h=350"	
    
	$downloadfile = 'C:\Temp\image.gi_'
	$websitefile = 'C:\inetpub\wwwroot\image.gif'

    # Make sure any old download is removed.
	if( Test-FileExists ($downloadfile) ) { 
		Remove-Item $filedata -Force -ErrorAction SilentlyContinue 
	}
		
	try {
		$Webclient = new-object System.Net.WebClient
        # Enable proxy authentication with user credentials
        $Webclient.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials		
		$Webclient.DownloadFile($buienradar_url, $downloadfile)		
		
        # If a download exists, remove the old web file and copy the new.
		if( Test-Path $downloadfile ) { 
            Echo-Log "Retrieve data from buienradar.nl was successfull."
            Echo-Log "File: $downloadfile"

            # Remove old GIF file on the webserver
            Echo-Log "Web server file: $websitefile"
			if( Test-Path $websitefile ) {                
				Remove-Item $websitefile -Force -ErrorAction SilentlyContinue 
			}

            # Move the download to the webserver if the previous image was removed.
            if( !(Test-Path $websitefile )) {
			    Move-Item $downloadfile $websitefile -Force -ErrorAction SilentlyContinue

                # Check if a website image is found.
                if( Test-Path $websitefile ) {
                    Echo-Log "The GIF image was uploaded to website."
                }
            } else {
                Echo-Log "ERRROR: The old GIF image could not be removed from the website."
            }            
		}
	}
	catch {
		Echo-Log "ERROR: Retrieve gif data from buienradar.nl has failed!"

        # Remove old GIF to make sure no old image is shown on the web server.
        if( Test-Path $websitefile ) { 
				Remove-Item $websitefile -Force -ErrorAction SilentlyContinue 
		}
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