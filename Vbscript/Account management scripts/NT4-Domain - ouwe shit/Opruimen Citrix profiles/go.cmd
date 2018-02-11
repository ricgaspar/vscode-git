	@echo off
:Start
	call setEnvironment.cmd
	for /f %%i in (users.txt) do call :RuimOp %%i
	goto Einde
	
:RuimOp
	if !%1==! goto Err1
	call :PrintMess -------------------------------------------
	call :PrintMess Delete %1	

:CtxProf
	if not exist "%CtxFolder%\%1" goto Prof2
	goto CheckAccount
:Prof2
	if not exist "%CtxFolder2%\%1" goto Err4b
:CheckAccount
	cscript //NoLogo chkUserDisabled.vbs %1
	if errorlevel 2 goto NotFound
	if errorlevel 1 goto Err5
	goto Err3

:NotFound
	call :PrintMess Delete Citrix profiel %1
	call DeleteCitrixProfile.cmd %1
	goto Einde
	
:Err1
	call :PrintMess Geen accountnaam!
	goto Einde
:Err2
	call :PrintMess Account %1 is niet gevonden in AD!
	goto Einde
:Err3
	call :PrintMess Account %1 is niet disabled!
	goto Einde
:Err4
	call :PrintMess Citrix profiel %CtxFolder%\%1 was niet gevonden!
	goto Einde
:Err4b
	call :PrintMess Citrix profiel %CtxFolder%\%1 en %CtxFolder2%\%1 was niet gevonden!
	goto Einde

:Err5
	call :PrintMess Account %1 is disabled!
	goto Einde

:PrintMess
	klok datum>>%NEDCARUM2LOG%
	klok tijd>>%NEDCARUM2LOG%	
	echo %1 %2 %3 %4 %5 %6 %7 %8>>%NEDCARUM2LOG%
	echo %1 %2 %3 %4 %5 %6 %7 %8
	goto Einde
	
:Einde
	