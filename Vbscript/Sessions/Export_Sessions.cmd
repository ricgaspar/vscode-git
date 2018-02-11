	@echo off	
	set SCHEDLOG=%systemdrive%\Logboek\Secdump-Sessions.log
	echo.> %SCHEDLOG%

	pushd %SYSTEMDRIVE%\Scripts\Secdump\Sessions

:----------------------	
:Start
	call :Add2Log "================================================"
	call :Add2Log "Start script %0"

:CheckSystem
	call %systemdrive%\Scripts\Secdump\setsql.cmd
	if !SQLSERVER==! goto Err2
	call :Add2Log "Using SQL Server %SQLSERVER%"
	
:----------------------	
:Inventory local logical drives.		
	cscript //NoLogo export_sessions.vbs

	call :Add2Log "Remove old NTFS records in database."
	cscript //nologo %SYSTEMDRIVE%\Scripts\Utils\sendsql.vbs "delete from sessions where systemname='%COMPUTERNAME%'" >cleandb.log
	for /F "delims=~" %%i IN (cleandb.log) do call :Add2Log "%%i"
	
:Import
	call :Add2Log "Import sessions CSV dump into SQL database."
	call LogParser.exe file:sessions.sql -i:CSV -o:SQL -server:%SQLSERVER% -database:%SQLDB% -driver:"SQL Server" -username:%SQLUID% -password:%SQLUIDPW%>LogParser.log
	for /F "delims=~" %%i IN (logparser.log) do call :Add2Log "%%i"

:----------------------	
:End
	call :Add2Log "End %0"
	call :Add2Log "================================================"
	goto Einde
:Err2
	call :Add2Log "ERROR: SQLServer is unknown!"
	goto End

:----------------------	
:Add2Log
	klok nu>>%SCHEDLOG%
	echo "%1">>%SCHEDLOG%
	klok nu 
	echo %1
	goto Einde
:----------------------
:Einde
	popd