	@echo off
:Start
	set ImportLog=%systemdrive%\Logboek\Secdump-GroupmembersAD.log
:**********
	exit
:**********

:SetSQLInfo
	call C:\Scripts\Secdump\setsql.cmd

:Export
	call :Add2Log "Export AD Group Members"
	if exist groupmembersAD.csv del groupmembersAD.csv /Q >nul
	CSVDE -f groupmembersAD.csv -r (objectCategory=group) -m -n -l "name,member"

	if not exist groupmembersAD.csv goto Err2
	
:Import2SQL	
	call :LogParse group_members.sql
	
	goto Einde
	
:----------------------	
:LogParse
	call :Add2Log "Calling logparser with %1 %SQLSERVER%"
	call LogParser.exe file:%1 -i:CSV -o:SQL -dtLines:0 -createTable:ON -clearTable:ON -server:%SQLSERVER% -database:%SQLDB% -driver:"SQL Server" -username:%SQLUID% -password:%SQLUIDPW%>%temp%\LogParser.log	
	for /F "delims==" %%i IN (%temp%\logparser.log) do call :Add2Log "%%i"
	goto Einde

:----------------------	
:Add2Log
	klok nu>>%IMPORTLOG%
	echo %1>>%IMPORTLOG%

	klok nu
	echo %1
	goto Einde

:Err1
	call Add2Log "ERROR: CSVDE Export not present!"
	goto Einde

:Err2
	call Add2Log "ERROR: CSVDE Export group members not present!"
	goto Einde
:----------------------	
:Einde