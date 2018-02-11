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

$addfs = Get-Content .\TSM\add-lines.txt -ErrorAction SilentlyContinue

$TSM_Home = 'C:\Program Files\Tivoli\TSM\baclient'
$TSM_InclExcl = "$TSM_Home\inclexcl.dsm"
if(Test-Path $TSM_InclExcl) {
	Write-host "TSM definition file '$TSM_InclExcl' was found."	
	$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Versions\configure-TSM-InclExcl-$NCSTD_VERSION.log"	
	if(Test-Path($SCRIPTLOG)) {
		Write-Host "$SCRIPTLOG already exists. Nothing to execute."
	} else {	
		Append-Log "Configuring TSM definition file '$TSM_InclExcl'"
		Append-Log "Removing lines from definition files."
		# Remove unwanted text from the file
		try {
			$content = Get-Content $TSM_InclExcl 
			$newcontent = $content
			$remfs = Get-Content .\TSM\remove-lines.txt 
			# Remove lines in the content
			foreach($line in $remfs) {
				Append-Log "Removing: '$($line)'"
				$newcontent = $newcontent | Where-Object {$_ -ne $line }
			}
			$newcontent | Set-Content $TSM_InclExcl 
		}
		catch {
			Write-Host 'An error occurred.'
		}
		
		Append-Log "Adding lines to definition files."
		# Add text to the file		
		try {
			$content = Get-Content $TSM_InclExcl
			$addfs = Get-Content .\TSM\add-lines.txt
			# Add lines to the file
			foreach($line in $addfs) {
				if($line.Length -gt 0) {
					if(!(Select-String -SimpleMatch $line -Path $TSM_InclExcl)) {
						Append-Log "Adding: '$($line)'"
						(Get-Content $TSM_InclExcl),$line | Set-Content $TSM_InclExcl
					}
				}
			}
		}
		catch {
			Write-Host 'An error occurred.'
		}
	}	
} else {
	Write-Host "TSM folder '$TSM_Home' was not found."
}