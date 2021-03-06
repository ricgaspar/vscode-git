# =========================================================
#
# Marcel Jussen
# 20-01-2015
#
# =========================================================
param (
	[string]$NCSTD_VERSION = '6.0.0.0'
)

# ---------------------------------------------------------
# Pre-defined variables

# ---------------------------------------------------------
Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

function CheckComputerConnectivity {
	param ( 
		[string] $Computer
	)
	if([string]::IsNullOrEmpty($Computer)) { return $null }	
	$WmiFilter = "Address='" + $Computer + "'"
	$WmiObject = Get-WmiObject -Class Win32_PingStatus -Filter $WmiFilter
	$StatusCode = $WmiObject.StatusCode
	$IsAlive = ($StatusCode -eq 0)
	return $IsAlive
}

# ------------------------------------------------------------------------------
Write-Host "Started NCSTD Configure $NCSTD_VERSION"

$wmi = Get-WmiObject Win32_Computersystem -ErrorAction SilentlyContinue
$man = $wmi.manufacturer
if($man -eq 'HP') {
	$iloname = "ilo$env:computername.nedcar.nl"	
	$pingable = CheckComputerConnectivity($iloname)
	if($pingable) {	
		$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-ILO-$NCSTD_VERSION.log"
		if(Test-Path($SCRIPTLOG)) {
			Write-Host "$SCRIPTLOG already exists. Nothing to execute."
		} else {
			Append-Log "Start script $ScriptName"	
			
			# Unblock files
			$folder = $env:SystemDrive + "\Scripts\Config\ILO"
			gci $folder | Unblock-File
			
			cd $folder			
			$command = ".\HPQLOCFG.exe -s $iloname -f VDLNedcar-ILO-Configuration.xml -v -n"
			Append-Log $command
	
			# Execute command
			$result = invoke-expression $command						
			Append-Log "End script $ScriptName"
		}
	} else {
		Write-Host "The ILO device $iloname could not be pinged. Aborting script." 
	}
	
} else {
	Write-Host "This is not a HP computer. Aborting script." 	
}

