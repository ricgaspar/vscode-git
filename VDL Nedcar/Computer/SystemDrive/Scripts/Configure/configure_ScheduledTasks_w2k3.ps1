# =========================================================
#
# Marcel Jussen
# 29-03-2016
#
# =========================================================
param (
	[string]$NCSTD_VERSION = '6.0.0.1'
)

# ---------------------------------------------------------
# Pre-defined variables
$Global:SERVER_AGE_DAYS = 7

# ---------------------------------------------------------
Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

Function Validate_OS {
	param (
		$OSMajor,
		$OSMinor,
		$OSSubminor
	)
	$result = $false
	
	$os = Get-WmiObject -class Win32_OperatingSystem 
	$version = $os.Version
	Append-Log "OS Version: $version"
	$osarr = $version.split(".")	
	$ver_major = [int]$osarr[0]
	$ver_minor = [int]$osarr[1]
	$ver_subminor = [int]$osarr[2]

	if(($ver_major -eq $OSMajor) -and ($ver_minor -eq $OSMinor) -and ($ver_subminor -ge $OSSubminor)) {
		$result = $true
	}	
	
	return $result
}

# ------------------------------------------------------------------------------
Write-Host "Started NCSTD Configure $NCSTD_VERSION"

# Make sure to run this script from the config folder or else no scheduled tasks are created.
CD /D C:\Scripts\Config

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-ScheduledTasks_w2k3-$NCSTD_VERSION.log"
if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {

    $OSCheck = Validate_OS -OSMajor '5' -OSMinor '2' -OSSubminor '0'
    if($OSCheck) {
        Append-Log "OS Version complies to Windows 2003 or higher"
        
        $temp = SCHTASKS /CHANGE /TN "VNB-Weekly reboot task" /RU SYSTEM
        Append-Log $temp
        $temp = SCHTASKS /CHANGE /TN "VNB-Cleanup files" /RU SYSTEM
        Append-Log $temp
        $temp = SCHTASKS /CHANGE /TN "VNB-System configuration check" /RU SYSTEM
        Append-Log $temp
        $temp = SCHTASKS /CHANGE /TN "VNB-System configuration info" /RU SYSTEM
        Append-Log $temp
        $temp = SCHTASKS /DELETE /TN "VNB-System check W32TM" /F
        Append-Log $temp
        $temp = SCHTASKS /CREATE /TN "VNB-System check W32TM" /SC DAILY /TR "C:\Windows\System32\w32tm.exe /resync /rediscover" /RU SYSTEM /ST 09:00 /RI 240 /ET 08:00 /F
        Append-Log $temp
        
    } else {
        Append-Log "OS Version does not comply to Windows 2003 or higher" 
    }
	Append-Log "End script $ScriptName"
}

