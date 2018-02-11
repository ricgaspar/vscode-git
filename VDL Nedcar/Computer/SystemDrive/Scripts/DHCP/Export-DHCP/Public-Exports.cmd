	@echo off
	call C:\Scripts\Secdump\setsql.cmd
	if not exist Public-Exports\ md Public-Exports\>nul
	
:Start
	if !%1==! goto Err1
	call PrintMess "Exporting clients per scope on server %1"

	for /f %%k in (scope-options.ini) do (
		echo Exporting scope option: %%k
		for /f "tokens=1 skip=4" %%i in ('netsh dhcp server \\%1 show scope') do (
			echo Export scope: %%i
			if not exist Public-Exports\%1\ md Public-Exports\%1\
			if not exist Public-Exports\%1\%%i\ md Public-Exports\%1\%%i\
			netsh dhcp server \\%1 scope %%i show %%k>Public-Exports\%1\%%i\%%k.txt
		)

		if exist Public-Exports\%1\Command rmdir /S /Q Public-Exports\%1\Command
		if exist Public-Exports\%1\Total rmdir /S /Q Public-Exports\%1\Total
	)

	goto Einde

:Err1
	call PrintMess "ERROR: Parameter error. Missing server name."
	goto Einde	

:Einde