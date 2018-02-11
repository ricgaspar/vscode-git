:********************************************************************
:
:  File:           createCTXProfile.cmd
:  Created:        Augustus 2004
:  Version:        1.2
:  Author:         Marcel Jussen
:
:  Description:    NedCar user Management scripts.  
:
:  Copyright (C) 2004 KPN Telecom
:
:*******************************************************************

	@echo off
	set NEWUID=%1
	: if not exist C:\NedCarUM2\uid.cmd goto ERROR1
	: call uid.cmd
	echo Creating Citrix profile for %NEWUID%
	
	: for /f %%t in ('cd') do set curpath=%%t
	if !%PDC%==! call C:\nedcarum2\setEnvironment.cmd
:FOLDER
	echo Creating %ctxfolder%\%NEWUID%
	if not exist "%ctxfolder%\%NEWUID%" md "%ctxfolder%\%NEWUID%" 
	if exist "\\%ctxcomputer%\helpdesk$\Directory Structuur\*.*" xcopy "\\%ctxcomputer%\helpdesk$\Directory Structuur\*.*" \\%ctxcomputer%\Ctxprof$\%NEWUID%\*.* /s /e /h /y > nul
:NTFS
	echo Setting permissions.
	call c:\nedcarum2\cacls.exe \\%ctxcomputer%\CTXProf$\%NEWUID% /T /E /G NEDCAR\%NEWUID%:C < "Y.txt" > nul
:READY
	echo ready > C:\NEDCARUM2\ready.sig
	: del C:\NedCarUM2\uid.txt > nul
	goto EINDE
:ERROR1
	echo UID is onbekend of niet ingevuld. Programma error.
	pause
	echo error > C:\NEDCARUM2\ready.sig
	goto EINDE
:EINDE
	set NEWUID=