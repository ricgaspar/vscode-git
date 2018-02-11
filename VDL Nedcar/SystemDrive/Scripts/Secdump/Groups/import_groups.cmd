	@echo off
:Start
	set ImportLog=%systemdrive%\Logboek\Secdump-GroupsAD.log
:**********
	exit
:**********
:SetSQLInfo
	call C:\Scripts\Secdump\setsql.cmd

:Export
	call :Add2Log "Export AD Groups"
	if exist groupsAD.csv del groupsAD.csv /Q >nul
	CSVDE -f groupsAD.csv -r "objectClass=group" -m -l "DN,cn,description,distinguishedName,name,sAMAccountName,groupType,objectSid"
	if not exist groupsAD.csv goto Err1
		
:Import2SQL	
	call :LogParse groupsAD.sql	
	goto Einde
	
:----------------------	
:LogParse
	call :Add2Log "Calling logparser with %1"
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