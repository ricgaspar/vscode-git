:********************************************************************
:
:  File:           syncSourceFiles.cmd
:  Created:        Augustus 2004
:  Version:        1.0
:  Author:         Marcel Jussen
:
:  Description:    NedCar user Management scripts.  
:
:  Copyright (C) 2004 KPN Telecom
:
:*******************************************************************

	@echo off
	set Source=\\S100\d$\NEDCARUM2
	set Dest=C:\NEDCARUM2
	
	if exist %Dest% goto Start
:Install
	md %Dest%
	xcopy %Source%\*.* %Dest%\*.* /S/E/Y/Q
:Start
	xcopy %Source%\*.* %Dest%\*.* /T/E/Y/Q
	set synclog=%Dest%\log\sync.log
	echo Sync sources
	cd /D %Dest%
	For /F %%i in (%Source%\UPDATES.INI) do call %Source%\syncfile.exe %Source%\%%i %Dest%\%%i >> %synclog%
	echo Sync completed.
	set synclog= 	
	
:ShortCuts
	set icon="%APPDATA%\Microsoft\Internet Explorer\Quick Launch\NedCarUM.lnk"
	copy %Source%\nedcarum.lnk %icon% > nul
	set icon="%HOMEDRIVE%%HOMEPATH%\Desktop\NedCar User Management(AD).lnk"
	copy %Source%\nedcarum.lnk %icon% > nul 
	set icon=
	goto Einde
:Einde
	cd /d %Dest%
	exit