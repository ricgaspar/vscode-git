	@echo off
	set ServiceName=TlntSvr
:Start
	for /f %%i in (hosts.txt) do call :DisableTelnet %%i
	goto Einde

:DisableTelnet
	cls
	Echo Checking machine %1
	psservice \\%1 query %ServiceName% > %temp%\status.txt
	find /I "RUNNING" %temp%\status.txt > nul
	if not errorlevel 1 goto Running
	goto NotRunning
:Running
	echo  Service %ServiceName% is running.
	psservice \\%1 setconfig %ServiceName% disabled
	psservice \\%1 stop %ServiceName%

	pause
	goto Einde
:NotRunning
	echo  Service %ServiceName% is not running.
	pause
	goto Einde

:Einde
