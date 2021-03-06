#-----------------------------------------------------------------------
# VDL Nedcar Windows server standaard
#
# Configure application script
#
# Author: Marcel Jussen
#-----------------------------------------------------------------------

param (
	[string]$NCSTD_VERSION = '6.0.0.0'
)

$SCRIPTLOG = $env:SystemDrive + "\Logboek\Config\Once\configure-Shortcuts.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

if(Test-Path($SCRIPTLOG)) {
	Write-Host "$SCRIPTLOG already exists. Nothing to execute."
} else {
    
    $CommonDesktopFolder =  $env:PUBLIC + '\Desktop'
    
	$msg = "Removing shortcuts on common desktop $CommonDesktopFolder."
	Append-Log $msg
	
    $Shortcut = $CommonDesktopFolder + "\HP System Management Homepage.lnk"
	if(test-path ($Shortcut)) { Remove-Item -Path $Shortcut -Force -ErrorAction SilentlyContinue }

    $Shortcut = $CommonDesktopFolder + "\WinZip.lnk"
	if(test-path ($Shortcut)) { Remove-Item -Path $Shortcut -Force -ErrorAction SilentlyContinue }

    $Shortcut = $CommonDesktopFolder + "\Windows Explorer.lnk"
	if(test-path ($Shortcut)) { Remove-Item -Path $Shortcut -Force -ErrorAction SilentlyContinue }
	
    $msg = 'Add shortcut to common desktop.'

    $ShortCutFile = $env:PUBLIC + '\Desktop\Server Tools.lnk'
    $Target = 'C:\Scripts\Utils'
    $Icon = 'C:\Scripts\Utils\icons\motherboard.ico'
    $WscriptShell = New-Object -ComObject Wscript.shell
    $ShortCut = $WscriptShell.CreateShortCut($ShortCutFile)
    $ShortCut.TargetPath = $Target
    $ShortCut.IconLocation = $Icon
    $ShortCut.Save()
	Append-Log $msg
}