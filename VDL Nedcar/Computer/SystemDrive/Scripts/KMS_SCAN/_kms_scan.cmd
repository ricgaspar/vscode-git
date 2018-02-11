	@echo off
	cd /d "c:\scripts\KMS_SCAN\"
:Start
	taskkill /im windump.exe /f >nul
:Import
	powershell -ExecutionPolicy Bypass -file c:\scripts\KMS_SCAN\Import.ps1
	
:StartScan
	for /f %%i in ('klok nu') do ( 
		start c:\scripts\KMS_SCAN\interface2.cmd
		start c:\scripts\KMS_SCAN\interface7.cmd
	)
:Einde