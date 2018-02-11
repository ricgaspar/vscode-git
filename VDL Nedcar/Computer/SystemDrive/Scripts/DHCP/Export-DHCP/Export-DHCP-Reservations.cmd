	@echo off
	call C:\Scripts\Secdump\setsql.cmd
	
:Start
	if !%1==! goto Err1
	call PrintMess "Exporting all available reservations from server %1"
	if not exist %1-Server-Dump.txt goto Err2
			
	find /I "Add reservedip" %1-Server-Dump.txt | find /I "Dhcp server">res.txt
	for /f "tokens=5,8-11" %%i in (res.txt) do echo %1,%%i,%%j,%%k,%%l>>DHCP-reservations.csv
	del /Q res.txt>nul	

	goto Einde

:Err1
	call PrintMess "ERROR: Parameter error. Missing server name."
	goto Einde
	
:Err2
	call PrintMess "ERROR: Dump file %1-Server-Dump.txt does not exist!"
	goto Einde

:Einde