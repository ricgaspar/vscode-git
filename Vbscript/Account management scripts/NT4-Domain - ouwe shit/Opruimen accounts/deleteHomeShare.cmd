:********************************************************************
:
:  File:           deleteHomeShare.cmd
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
	if !%1==! goto Einde
:DIR
	echo Resetting attributes on files and folders in %HomeFolder%\%1 >> %NEDCARUM2LOG%
	if exist "%HomeFolder%\%1" call attrib "%HomeFolder%\%1\*.*" -h -r -s /s >> %NEDCARUM2LOG%
	if exist "%HomeFolder%\%1" goto Share
	goto einde
:SHARE
	echo Delete share \\%HomeComputer%\%1$>> %NEDCARUM2LOG%
	call rmtshare.exe \\%HomeComputer%\%1$ /delete >> %NEDCARUM2LOG%
:FILES
	echo Delete folder %HomeFolder%\%1>> %NEDCARUM2LOG%
	echo y | rd "%HomeFolder%\%1" /s >> %NEDCARUM2LOG%
:Einde
