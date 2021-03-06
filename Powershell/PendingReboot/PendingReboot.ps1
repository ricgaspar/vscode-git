
Function PendingRenames {
	param (
		$systemname = '.'
	)
	
	Write-Host "-> $systemname"
	Try
	{
		$HKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $systemname)
		$string = $HKLM.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager").getvalue("PendingFileRenameOperations")
	}
	Catch
	{		
		Write-Host "ERROR: Failed to open remote registry key."
		$string = $null
	}
	
	return $string
}

Function PendingReboot {
	param (
		$systemname
	)
	$check = $False
	if(PendingRenames $systemname){ $check = $true}
	return $check
}

cls
PendingRenames "vdlnc01002"
PendingReboot "vdlnc01002"
