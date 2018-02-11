:********************************************************************
:
:  File:           setEnvironment.cmd
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
	
: Primary domain controller
	set PDC=S150
	set DOMAIN=NEDCAR
	set NEDCARUM2LOG=\\S100\Logboek\NEDCARUM2\opruimen.log

: Home directory info
	set homecomputer=S034
	set homefolder=\\%homecomputer%\Data$
	set homelocation=D:\DATA

: Citrix info
	set newuid=
	set ctxcomputer=S032
	set ctxfolder=\\%ctxcomputer%\Ctxprof$

: Apollo
	set apollocomputer=S032
	set apollofolder=\\%apollocomputer%\Apollo$
