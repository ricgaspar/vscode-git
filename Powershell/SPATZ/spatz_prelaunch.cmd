	@echo off
:Start
	powershell set-executionpolicy -executionpolicy unrestricted
	cd /d C:\Scripts\SPATZ
	if exist spatz_prelaunch.ps1 (
		REM powershell .\spatz_prelaunch.ps1
	) else (
		echo The script spatz_prelaunch.ps1 could not be found and executed.
	)