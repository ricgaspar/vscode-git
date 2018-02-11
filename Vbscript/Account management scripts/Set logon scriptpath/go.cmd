	@echo off
:Start
	for /f "delims=~" %%i in (users.txt) do cscript //NoLogo setLogonscript.vbs "%%i"