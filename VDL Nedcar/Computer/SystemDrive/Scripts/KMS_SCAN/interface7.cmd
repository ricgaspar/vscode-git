	@echo off
	cd /d "%~dp0"
:Start
	for /f %%i in ('klok nu') do (
		c:\scripts\KMS_SCAN\windump.exe -i 7 -U -F c:\scripts\KMS_SCAN\filter.txt -q > c:\scripts\KMS_SCAN\dump-interface7-%%i.log 2>&1
	)
