# ---------------------------------------------------------
# Download and update MS Offline Defender SCCM package
# Marcel Jussen
# 15-10-2014
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:PackageUpdate = 0

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "SCCM-OfflineDefender-UpdateDownload-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$DownloadURLx64 = "http://go.microsoft.com/fwlink/?LinkID=121721&clcid=0x409&arch=x64"
$DownloadFileX64 = "D:\Temp\mpam-fex64.exe"

$SCCM_Package_SourceFolder = "\\S007.nedcar.nl\Sources$\apps\exe\Microsoft OfflineDefender"
$SCCM_Package_File = "$SCCM_Package_SourceFolder\mpam-fex64.exe"

$SCCM_Package_ID = "VNB0020E"
$SCCM_Server = 's007.nedcar.nl'
$SCCM_SiteCode = 'VNB'
$DistributionPointGroup = "VDL Nedcar client distribution group"

# Check presence and remove previously downloaded file
if(Test-Path $DownloadFileX64) {
	Echo-Log "Found file: $DownloadFileX64"
	Echo-Log "Removing file: $DownloadFileX64"
	Remove-Item $DownloadFileX64 -ErrorAction SilentlyContinue -Force
}

if(Test-Path $DownloadFileX64) {
	Echo-Log "ERROR: Previous source has not been deleted."
	$Global:PackageUpdate++
} else {

	# Start download of file
	Echo-Log "Previous source file was successfully deleted."
	Echo-Log "Downloading updates from $DownloadURLx64 to $DownloadFileX64"
	$client = new-object System.Net.WebClient
	$client.DownloadFile( $DownloadURLx64, $DownloadFileX64 )

	# Check if download completed
	if(Test-Path $DownloadFileX64) {
		Echo-Log "Download completed successfully"
		$fsize =  (Get-Item $DownloadFileX64).length
		Echo-Log "Size of downloaded file: $fsize bytes"
		
		#Check if SCCM package folder can be accessed.
		Echo-Log "SCCM package source folder: $SCCM_Package_SourceFolder"
		if(Test-Path $SCCM_Package_SourceFolder) {
		
			#Remove old update file
			if(Test-Path $SCCM_Package_File) {
				Echo-Log "Removing file $SCCM_Package_File"
				Remove-Item $SCCM_Package_File -Force -ErrorAction SilentlyContinue
			}
			if(Test-Path $SCCM_Package_File) {
				Echo-Log "ERROR: The file could not be deleted!"
				$Global:PackageUpdate++
			} else {
				Echo-Log "The file was successfully deleted."
				
				# Copy downloaded file to package folder				
				Copy-Item -Path $DownloadFileX64 -Destination $SCCM_Package_File -Force -ErrorAction SilentlyContinue
				if(Test-Path $SCCM_Package_File) {
					Echo-Log "The downloaded file has been copied to the SCCM package folder."
					
					# Trigger SCCM site to update package
					Echo-Log "Trying to connect to Root\SMS\Site_$SCCM_SiteCode on $SCCM_Server"
					$DPGroupQuery = Get-WmiObject -ComputerName "$SCCM_Server" -Namespace "Root\SMS\Site_$SCCM_SiteCode" -Class SMS_DistributionPointGroup -Filter "Name='$DistributionPointGroup'" -ErrorAction SilentlyContinue
					if($DPGroupQuery) { 
						$name = $DPGroupQuery.Name
						Echo-Log "Successfully connected to Root\SMS\Site_$SCCM_SiteCode"
						Echo-Log "Forcing update of package ID $SCCM_Package_ID"
						$result = $DPGroupQuery.ReDistributePackage($SCCM_Package_ID)
						$val = $result.ReturnValue
						Echo-Log "Return value: $val"
					} else {
						Echo-Log "ERROR: Could not connect to WMI provider on $SCCM_Server"
						$Global:PackageUpdate++
					}	
				} else {
					Echo-Log "ERROR: The downloaded file was not successfully copied to the SCCM package folder."
					$Global:PackageUpdate++
				}
			}
		} else {
			Echo-Log "ERROR: The packagefolder could not be found!"
			$Global:PackageUpdate++
		}
	} else {
		Echo-Log "ERROR: The download did not succeed!"
		$Global:PackageUpdate++
	}
}

# We are done.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if ($Global:PackageUpdate -ne 0) {
	$Title = "ERROR: Microsoft Offline Defender update download and package update has ended in an error!"
} else {
	$Title = "Microsoft Offline Defender update download and package update completed successfully."
}

# Send email if download and package update failed.
if ($Global:PackageUpdate -ne 0) {
	# $SendTo = "events@vdlnedcar.nl"
	$SendTo = "m.jussen@vdlnedcar.nl"
	$dnsdomain = 'vdlnedcar.nl'
	$computername = gc env:computername
	$SendFrom = "$computername@$dnsdomain"
	Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title	
}