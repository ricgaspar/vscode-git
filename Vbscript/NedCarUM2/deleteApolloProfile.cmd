:********************************************************************
:
:  File:           deleteApolloProfile.cmd
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
	if exist "%ApolloFolder%\%1\*.*" call attrib "%ApolloFolder%\%1\*.*" -h -r -s /s >> %NEDCARUM2LOG%
	if exist "%ApolloFolder%\%1\*.*" goto files
	goto einde
:FILES
	echo y | rd "%ApolloFolder%\%1" /s >> %NEDCARUM2LOG%
:Einde