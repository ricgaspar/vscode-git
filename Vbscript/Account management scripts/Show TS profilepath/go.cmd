	@echo off
:Start
	Echo Reading 'users.txt'...
	for /f "delims=~" %%i in (users.txt) do (
		echo %%i
		cscript //NoLogo ShowTSProfilepath.vbs "%%i"
	)