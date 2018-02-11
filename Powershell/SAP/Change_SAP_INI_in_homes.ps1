# =========================================================
#
# Change SAP.INI in home drives 
#
# Marcel Jussen
# 04-02-2015
#
# =========================================================
cls
# ---------------------------------------------------------

# Includes
. C:\Scripts\Secdump\PS\libLog.ps1

# ---------------------------------------------------------

Function Change_TextFile {
	param (
		[string]$TextFilePath = ""		
	)		
	
	if(Test-Path($TextFilePath)) {		
		$save = $false
		$content = (get-content $TextFilePath)
		
		$change = (($content | Select-String -Pattern "sapmsP10") -ne $null)
		if ($change) {			
			$content = ( $content | foreach-object {$_ -replace "sapmsP10", "3600"} )			 
			$save = $true
		}
		
		$change = (($content | Select-String -Pattern "sapmsP01") -ne $null)
		if ($change) {
			$content = ( $content | foreach-object {$_ -replace "sapmsP01", "3600"} )
			$save = $true
		}
		
		$change = (($content | Select-String -Pattern "sapmsA01") -ne $null)
		if ($change) {
			$content = ( $content | foreach-object {$_ -replace "sapmsA01", "3601"} )		
			$save = $true
		}
		
		$change = (($content | Select-String -Pattern "sapmsA10") -ne $null)
		if ($change) {
			$content = ( $content | foreach-object {$_ -replace "sapmsA10", "3601"} )
			$save = $true
		}
		
		$change = (($content | Select-String -Pattern "sapmsD01") -ne $null)
		if ($change) {
			$content = ( $content | foreach-object {$_ -replace "sapmsD01", "3600"} )
			$save = $true
		}
		
		#block save
		# $save = $false
				
		if($save) {
			Echo-Log "Saving altered file $TextFilePath"
			$content | set-content $TextFilePath
		}

	} else {
		Echo-Log "Error: cannot find $TextFilePath"
	}
}

# ---------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
[void](Init-Log -LogFileName $ScriptName)
Echo-Log ("=" * 60)
Echo-Log "Started script $ScriptName"
Echo-Log ("=" * 60)

$homes = "\\NEDCAR.NL\Office\Homes\"
$dirs = dir -Path $homes | Where {$_.psIsContainer -eq $true}
foreach($userhome in $dirs) {
	Echo-Log $userhome
	$SAPINI = $homes + $userhome + "\Windows\SAP\saplogon.ini"
  	Change_TextFile $SAPINI
}

# Change_TextFile "\\NEDCAR.NL\Office\Homes\CC77864\Windows\SAP\saplogon.ini"

Echo-Log ("=" * 60)
Echo-Log "End script $ScriptName"
Echo-Log ("=" * 60)