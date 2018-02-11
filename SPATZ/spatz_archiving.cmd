	@echo off
:Start
	powershell set-executionpolicy -executionpolicy unrestricted
	cd /d C:\Scripts\SPATZ
	if exist spatz_archiving.ps1 (
		powershell .\spatz_archiving.ps1
	) else (
		echo The script spatz_archiving.ps1 could not be found and executed.
	)