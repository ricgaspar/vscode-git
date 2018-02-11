	@echo off
	echo BDE check 1.1.3
:Start
	rem (1) Check if a BDE volume is configured.
	rem (2) Check if a BDE volume is created but the computer must be restarted.
	rem (3) Create BDE volume quietly.

:=========================================================	
:CheckBDEvol
	echo Checking for BDE volume.
	bdehdcfg -driveinfo >%temp%\bdeinfo.txt
	findstr /I "properly configured" %temp%\bdeinfo.txt >nul
	if %errorlevel%==1 goto :BDERestart
	if %errorlevel%==0 goto :TPM
:BDERestart
	echo Checking for BDE restart.
	findstr /I "restart" %temp%\bdeinfo.txt >nul
	if %errorlevel%==1 goto :Encrypt
	if %errorlevel%==0 goto :TPM
:CreateBDEVol
	echo Creating BDE volume.
	bdehdcfg -target default -size 500 -quiet
	goto :Restart
:Restart
	echo This computer must be restarted.
	goto Einde

:=========================================================
:TPM
	echo BDE volume is present and ready for use.

:Protectors
	echo Adding protectors to C: and D:
	if exist C:\ (
		manage-bde -protectors -add C: -TPM -rp >%WINDIR%\Patchlog\BDE_PROTECTORS_C.log
	)
	if exist D:\ (
		manage-bde -protectors -add D: -rp >%WINDIR%\Patchlog\BDE_PROTECTORS_D.log
	)

:=========================================================
:Einde