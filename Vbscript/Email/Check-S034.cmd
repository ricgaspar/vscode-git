	@echo off
	set s034log=C:\Logboek\S034-Check.log
	set checksys=S034

:Start
	klok nu>>%s034log%
	echo ======================================================>>%s034log%
	klok nu>>%s034log%
	echo Searching SMB shares on %checksys%>>%s034log%
	klok nu>>%s034log%
	net view \\%checksys% | find /I "Disk">>%s034log%

	if errorlevel 1 goto NotFound
:Found
	klok nu>>%s034log%
	echo SMB Shares on %checksys% found.>>%s034log%
	klok nu
	echo SMB Shares on %checksys% found.

	call D:\Scripts\Email\sms.cmd "%checksys% IS ONLINE."

	goto Einde

:NotFound
	klok nu>>%s034log%
	echo SMB shares on %checksys% not found.>>%s034log%
	klok nu
	echo SMB shares on %checksys% not found.
	set timer=X

:RePing
	klok nu>>%s034log%
	echo Ping check %checksys%>>%s034log%
	klok nu
	echo Ping check %checksys%
	ping -n 1 -w 2000 %checksys% | find /I "Request timed out">>%s034log%
	if errorlevel 1 goto Waitx

	call D:\Scripts\Email\sms.cmd "%checksys% cannot be pinged. Status=OFFLINE"		
	goto Einde
:Waitx	
	klok nu
	echo Waiting 180 seconds.	
	set timer=%timer%X
	Wait 180
	if !%timer%==!XXXXXXXXXX goto ERR
	goto RePing

:ERR
	call D:\Scripts\Email\sms.cmd "%checksys% is NOT offline."
:Einde