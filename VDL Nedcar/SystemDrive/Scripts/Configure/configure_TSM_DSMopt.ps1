# =========================================================
#
# Marcel Jussen
# 02-09-2016
#
# =========================================================
param (
	[string]$NCSTD_VERSION = '6.0.0.0'
)

# ---------------------------------------------------------
Function Append-Log {
	param (
		[string]$Message
	)	
	Write-host $message
	Add-Content $SCRIPTLOG $Message -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------------------
Write-Host "Started NCSTD Configure $NCSTD_VERSION"

# Make sure to run this script from the config folder or else no scheduled tasks are created.
set-location 'C:\Scripts\Config'

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-TSM-DSMopt-$NCSTD_VERSION.log"
if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {

	# Nothing implemented yet..
}