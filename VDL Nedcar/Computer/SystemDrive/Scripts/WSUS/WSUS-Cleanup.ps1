# ---------------------------------------------------------
# Cleanup WSUS
# Marcel Jussen
# 27-01-2016
# ---------------------------------------------------------

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$Global:SendLog = 'C:\Logboek\WSus-clean-monthly.log'

Function WSUS-Cleanup {
	$Server = 's007.nedcar.nl'
  $UseSSL = $false
  $PortNumber = 8350

  [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null 
	$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer(); 
	$cleanupScope = new-object Microsoft.UpdateServices.Administration.CleanupScope; 
	$cleanupScope.DeclineSupersededUpdates = $true        
	$cleanupScope.DeclineExpiredUpdates = $true 
	$cleanupScope.CleanupObsoleteUpdates = $true 
	$cleanupScope.CompressUpdates = $true 
	$cleanupScope.CleanupObsoleteComputers = $true 
	$cleanupScope.CleanupUnneededContentFiles = $true 
	$cleanupManager = $wsus.GetCleanupManager(); 
	$cleanupManager.PerformCleanup($cleanupScope) | Out-File $Global:SendLog
}

$ScriptName = $myInvocation.MyCommand.name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "WSUS-Cleanup"
$GlobLog = Init-Log -LogFileName $logfile

Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

WSUS-Cleanup

# We are done.
Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

$Title = "WSUS Cleanup task results."

$SendTo = "m.jussen@vdlnedcar.nl"
$dnsdomain = 'vdlnedcar.nl'
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $Global:SendLog -Headline $Title	


