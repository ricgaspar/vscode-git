	@echo off
:Start
	if exist servers.txt del /Q servers.txt>nul
	call PrintMess "Retrieving DHCP servers from Active Directory."
	for /f "skip=3 tokens=2" %%i in ('netsh dhcp show server') do echo %%i>>servers.txt
	if exist tmp-servers.txt del /Q tmp-servers.txt>nul
:PingEm
	if exist dhcp-servers.txt del /Q dhcp-servers.txt>nul
	for /f "delims=[] tokens=1" %%i in (servers.txt) do (
		ping %%i | find /I "Reply from" >nul
		if errorlevel 1 goto NotPingable
		echo %%i>>dhcp-servers.txt
		call PrintMess "Found server %%i"
:NotPingable
		echo.>nul
	)
:Cleanup
	if exist servers.txt del /Q servers.txt>nul
	call :PrintMess "Done searching for DHCP servers."
	goto Einde
	
:Einde
