	@echo off
:Start
	for /f "delims=~" %%i in (users.txt) do cscript //NoLogo setTSProfilepath.vbs "%%i"