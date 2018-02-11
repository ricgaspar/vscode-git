:********************************************************************
:
:  File:           deleteCitrixProfile.cmd
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
	echo %ctxfolder%\%1
	if exist "%CtxFolder%\%1\*.*" call attrib "%CtxFolder%\%1\*.*" -h -r -s /s >> %NEDCARUM2LOG%
	if not exist "%CtxFolder%\%1\*.*" goto einde
:FILES
	echo y | rd "%CtxFolder%\%1" /s >> %NEDCARUM2LOG%
	goto Einde
:Einde