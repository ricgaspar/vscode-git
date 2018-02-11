:********************************************************************
:
:  File:           createHomeShare.cmd
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
	if !%1==! goto Error
	if !%PDC%==! call C:\nedcarum2\setEnvironment.cmd
:REMSHARE  	
	pushd %HOMEFOLDER%
	ren %1 %2>> %NEDCARUM2LOG%
	echo ren %1 %2>>%NEDCARUM2LOG%
	popd
	goto Einde
:Error
	echo No parameter applied [%1] >> %NEDCARUM2LOG%
:Einde