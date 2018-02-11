	@echo off
:Start
	powershell set-executionpolicy -executionpolicy unrestricted
	cd /d C:\Scripts\SPATZ
	if exist spatz_zip.ps1 (
		powershell .\spatz_zip.ps1
	) else (
		echo The script spatz_zip.ps1 could not be found and executed.
	)