	@echo off
:Start
	if !%1==! goto Err1
	call PrintMess "Exporting all available scopes from server %1"
	
	if not exist %1-Server-Dump.txt goto Err2
	for /f "skip=3 tokens=6-8" %%i in ('find /I "add scope" %1-Server-Dump.txt') do echo %1,%%i,%%j>>DHCP-scopes.csv
	goto Einde

:Err1
	call PrintMess "ERROR: Parameter error. Missing server name."
	goto Einde
	
:Err2
	call PrintMess "ERROR: Dump file %1-Server-Dump.txt does not exist!"
	goto Einde

:Einde