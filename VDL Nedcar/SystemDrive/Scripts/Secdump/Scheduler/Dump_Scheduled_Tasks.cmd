	@echo off
:
:  DEZE PROCEDURE WERKT ALLEEN OP EEN WINDOWS 2003/XP MACHINE!
:
:

: -------------------------------------------------------------------------
:Start
	set ImportLog=%systemdrive%\Logboek\Secdump-Scheduler.log
	set ImportELog=%systemdrive%\Logboek\Secdump-Scheduler-error.log
	if exist %ImportLog% del %ImportLog% > nul
	
	cd /d C:\Scripts\Secdump\Scheduler
:SetSQLInfo
	call C:\Scripts\Secdump\setsql.cmd
	
	call :Add2Log #############################################
	call :Add2Log Start %0
	call :Add2Log Using SQL Server %SQLSERVER%

: -------------------------------------------------------------------------
:StartExports
	call :Add2Log Starting dump procedure
	if exist hosts*.ini del hosts*.ini /Q> nul
	if exist jobs.csv del jobs.csv > nul

 	cscript //Nologo gethosts.vbs

	if not exist hosts.ini goto Err1
 	for /F "tokens=1" %%i in (hosts.ini) do call :DumpHost %%i
 	copy /A header.txt + /A jobs.csv /A alljobs.csv

:Import	
	call :Add2Log Import Scheduler CSV dump to SQL
	call LogParser.exe file:alljobs.sql -i:CSV -o:SQL -server:%SQLSERVER% -database:%SQLDB% -driver:"SQL Server" -username:%SQLUID% -password:%SQLUIDPW% > %temp%\LogParser.log
	for /F "delims==" %%i IN (%temp%\logparser.log) do call :Add2Log %%i

:----------------------	
:End
	popd
	call :Add2Log End %0
	call :Add2Log #############################################

	goto Einde

:DumpHost
	if !%1==!---------- goto Einde
	if !%1==! goto Einde
	
	call :Add2Log Checking machine %1
	if exist scheduler-error-%1.txt del scheduler-error-%1.txt > nul
	jt /SM \\%1 /SE > %temp%\scheduler.txt
:Test1
	find /I "[ERROR]" %temp%\scheduler.txt > nul
	if errorlevel 1 goto test2
	goto Skip
:Test2
	find /I "[FAIL ]" %temp%\scheduler.txt > nul
	if errorlevel 1 goto test3
	goto Skip
:Test3
	schtasks /query /S %1 > %temp%\scheduler.txt
	find /I "There are no scheduled tasks present" %temp%\scheduler.txt > nul
	if errorlevel 1 goto Dump
	goto Skip
:Dump
	call :Add2Log Dumping Scheduled tasks from machine %1
	schtasks /query /S %1 /FO CSV /V /NH>>jobs.csv	
	goto Einde
:Skip
	call :Add2Log Scheduler from system %1 is not compatible
	call :Add2Log or does not contain any jobs.
	copy %temp%\scheduler.txt scheduler-error-%1.txt
	goto Einde
	
:----------------------	
:Add2Log
	klok nu>>%IMPORTLOG%
	echo %1 %2 %3 %4 %5 %6 %7 %8 %9 >>%IMPORTLOG%
	klok nu
	echo %1 %2 %3 %4 %5 %6 %7 %8 %9
	goto Einde
:----------------------
:Einde