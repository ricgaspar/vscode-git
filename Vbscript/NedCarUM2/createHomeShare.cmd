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
:DIR 
	if not exist "%HomeFolder%\%1" md "%HomeFolder%\%1" >> %NEDCARUM2LOG%
  if not exist "%HomeFolder%\%1\Exchange" md "%HomeFolder%\%1\Exchange" >> %NEDCARUM2LOG%
  if not exist "%HomeFolder%\%1\Profile" md "%HomeFolder%\%1\Profile" >> %NEDCARUM2LOG%
  if not exist "%HomeFolder%\%1\My Documents" md "%HomeFolder%\%1\My Documents" >> %NEDCARUM2LOG%
  if not exist "%HomeFolder%\%1\My Documents\My Downloads" md "%HomeFolder%\%1\My Documents\My Downloads" >> %NEDCARUM2LOG%
  if not exist "%HomeFolder%\%1\My Documents\My Pictures" md "%HomeFolder%\%1\My Documents\My Pictures" >> %NEDCARUM2LOG%
:SHARE  
	echo C:\nedcarum2\rmtshare.exe \\%HomeComputer%\%1$=%HomeLocation%\%1 /GRANT "NEDCAR\Domain Admins":F /GRANT NEDCAR\%1:C /REMARK:"" >> %NEDCARUM2LOG%
	call C:\nedcarum2\rmtshare.exe \\%HomeComputer%\%1$=%HomeLocation%\%1 /GRANT "NEDCAR\Domain Admins":F /REMARK:"">> %NEDCARUM2LOG%

	call C:\nedcarum2\rmtshare.exe \\%HomeComputer%\%1$ /GRANT "NEDCAR\%1":C > %temp%\home.log
	type %temp%\home.log>>%NEDCARUM2LOG%
	goto Einde
:Error
	echo No parameter applied [%1] >> %NEDCARUM2LOG%
:Einde