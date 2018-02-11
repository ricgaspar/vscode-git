:********************************************************************
:
:  File:           user.cmd
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
	if !%1==! goto Error1
	set SOURCE=C:\NedCarUM2
	CD /D %Source%
	if exist %Source%\ready.sig del %Source%\ready.sig > nul
:Start
	if not exist setEnvironment.cmd goto Error2
	call setEnvironment.cmd

:DHTML Application
	start /I index.hta
	goto Einde
:Error1
	echo call MsgBox("Please use the NedCar UM Shortcut!", 16, "NedCarUM Error") > %temp%\temp.vbs
	start /min cscript //NoLogo %temp%\temp.vbs
	goto Einde
:Error2
	echo call MsgBox("Environment file is missing!", 16, "NedCarUM Error") > %temp%\temp.vbs
	start /min cscript //NoLogo %temp%\temp.vbs
	goto Einde
:Einde
	if exist %temp%\temp.vbs del /Q %temp%\temp.vbs
	exit