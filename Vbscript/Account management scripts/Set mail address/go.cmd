	@echo off
:Start
	for /f "delims=; tokens=1,3" %%i in (email.txt) do (
		echo %%i - %%j
		cscript //NoLogo setMail.vbs %%i %%j
	)