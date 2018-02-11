:********************************************************************
:
:  File:           renameCTXProfile.cmd
:  Created:        March 2006
:  Version:        1.0
:  Author:         Marcel Jussen
:
:  Description:    NedCar user Management scripts.  
:
:  Copyright (C) 2006 KPN Telecom
:
:*******************************************************************

	@echo off
	if !%1==! goto Error
	if !%PDC%==! call setEnvironment.cmd
:REMSHARE  	
	pushd %CTXFOLDER%
	echo Rename CTX profile from UID %1 to %2 >> %NEDCARUM2LOG%
	echo Rename CTX profile from UID %1 to %2	
	echo ren %1 %2 >> %NEDCARUM2LOG%
	ren %1 %2 >> %NEDCARUM2LOG%
	popd
	goto Einde
:Error
	echo No parameter applied [%1] >> %NEDCARUM2LOG%
:Einde