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
	if !%HomeFolder%==! call setEnvironment.cmd
:DIR
	if not exist "%HomeFolder%\%1" goto Err1
	if exist "%HomeFolder%\%1" call attrib "%HomeFolder%\%1\*.*" -h -r -s /s >> %NEDCARUM2LOG%
	if exist "%HomeFolder%\%1" goto Share
	goto einde
:SHARE  
	if not exist "\\%HomeComputer%\%1$" goto Err2
	call rmtshare.exe \\%HomeComputer%\%1$ /delete >> %NEDCARUM2LOG%
:FILES
	echo y | rd "%HomeFolder%\%1" /s >> %NEDCARUM2LOG%
	goto Einde
:Err1
	echo Home folder "%HomeFolder%\%1" does not exist!
	echo Home folder "%HomeFolder%\%1" does not exist!>> %NEDCARUM2LOG%
	goto Einde
:Err2
	echo Home share "\\%HomeComputer%\%1$" does not exist!
	echo Home share "\\%HomeComputer%\%1$" does not exist!>> %NEDCARUM2LOG%
	goto Einde
:Einde
