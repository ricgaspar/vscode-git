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
	if not exist "%CtxFolder%\%1" goto DIR2
	echo %CtxFolder%\%1>> %NEDCARUM2LOG%
	if exist "%CtxFolder%\%1\*.*" call attrib "%CtxFolder%\%1\*.*" -h -r -s /s >> %NEDCARUM2LOG%	
:FILES
	echo y | rd "%CtxFolder%\%1" /s >> %NEDCARUM2LOG%

:DIR2
	if not exist "%CtxFolder2%\%1" goto EINDE	
	echo %CtxFolder2%\%1>> %NEDCARUM2LOG%
	if exist "%CtxFolder2%\%1\*.*" call attrib "%CtxFolder2%\%1\*.*" -h -r -s /s >> %NEDCARUM2LOG%
:FILES2
	echo y | rd "%CtxFolder2%\%1" /s >> %NEDCARUM2LOG%
	goto Einde
:Einde