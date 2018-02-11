	@echo off
:PrintMess
	for /f %%i in ('klok datum') do set ddate=%%i
	for /f %%i in ('klok tijd') do set dtime=%%i
	set execdt=%ddate% %dtime%
	set ddate=
	set dtime=
	echo %execdt% %1
	if !%DHCPLOG%==! GOTO Einde
	echo %execdt% %1>>%DHCPLOG%
:Einde
