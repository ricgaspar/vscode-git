	@echo off
:Start
	call setEnvironment.cmd
	for /f %%i in (users.txt) do call :RuimOp %%i
	goto Einde
	
:RuimOp
	if !%1==! goto Err1
	call :PrintMess "-------------------------------------------"
	call :PrintMess "Delete %1"

goto CtxProf

	cscript //NoLogo chkUserDisabled.vbs %1
	if errorlevel 2 goto Err2
	if errorlevel 1 goto HomeDir
	goto Err3
	
:HomeDir
	if not exist "%HomeFolder%\%1" call :PrintMess "Homedirectory %HomeFolder%\%1 was niet gevonden."
	if not exist "%HomeFolder%\%1" goto CtxProf
	call :PrintMess "Delete homedir %HomeFolder%\%1"
	if exist "%HomeFolder%\%1" call deleteHomeShare.cmd %1
:CtxProf
	if not exist "%CtxFolder%\%1" call :PrintMess Citrix profiel %CtxFolder%\%1 was niet gevonden.
	if not exist "%CtxFolder%\%1" goto UID
	call :PrintMess "Delete CITRIX profile %CtxFolder%\%1"
	if exist "%CtxFolder%\%1" call DeleteCitrixProfile.cmd %1
	goto Einde

:UID
	call :PrintMess "Delete user account %1"
	call cscript //NoLogo deleteuser-AD.vbs %1
	call :PrintMess "-------------------------------------------"
	
	goto Einde
	
:Err1
	call :PrintMess "Geen accountnaam!"
	goto Einde
:Err2
	call :PrintMess "Account %1 is niet gevonden in AD!"
	goto Einde
:Err3
	call :PrintMess "Account %1 is niet disabled!"
	goto Einde

:PrintMess
	klok datum>>%NEDCARUM2LOG%
	klok tijd>>%NEDCARUM2LOG%	
	echo %1>>%NEDCARUM2LOG%
	echo %1
	goto Einde
	
:Einde
	