	@echo off	
:======================================================
: Version 6.0.0.4 (01-04-2016)
:======================================================
:Start
	if not exist %SYSTEMDRIVE%\Logboek md %SYSTEMDRIVE%\Logboek
	if not exist %SYSTEMDRIVE%\Logboek\Cleanup\ md %SYSTEMDRIVE%\Logboek\Cleanup\
	del %SYSTEMDRIVE%\Logboek\Cleanup\*.* /S /Q >nul
	if exist %SYSTEMDRIVE%\Logboek\winrar.log del %SYSTEMDRIVE%\Logboek\winrar.log /Q >nul
:CreateSet
	if not exist %SYSTEMDRIVE%\Scripts\Cleanup md %SYSTEMDRIVE%\Scripts\Cleanup		

:======================================================
:PSVersion
	powershell -ExecutionPolicy Bypass -File %SYSTEMDRIVE%\Scripts\Acties\PSVersion.ps1	
:PS10
	find /I "1.0" %SYSTEMDRIVE%\Logboek\Cleanup\PSVersion.log >nul
	If %ERRORLEVEL% EQU 0 goto :VBS_Cleanup
:PS20
	find /I "2.0" %SYSTEMDRIVE%\Logboek\Cleanup\PSVersion.log >nul
	If %ERRORLEVEL% EQU 0 goto :VBS_Cleanup
:PSNAME
	find /I "%COMPUTERNAME%" C:\Scripts\Acties\systems-disapproved.ini >nul
	If %ERRORLEVEL% EQU 0 goto :VBS_Cleanup

:======================================================
:PS_Cleanup	
	REM powershell -ExecutionPolicy Bypass -File %SYSTEMDRIVE%\Scripts\Acties\cleanup_ini2xml.ps1

	powershell -ExecutionPolicy ByPass -File %SYSTEMDRIVE%\Scripts\Acties\cleanup.ps1
	goto :Einde

:======================================================
:VBS_Cleanup
	set syscleanini=%SYSTEMDRIVE%\Scripts\Acties\cleanup.ini
	set CleanupLog=%SYSTEMDRIVE%\Logboek\Cleanup\Cleanup.log
	if exist %CleanupLog% del %CleanupLog% /Q>nul

	set CleanupSetFldr=%SYSTEMDRIVE%\Scripts\Cleanup
	set CleanupSet=%CleanupSetFldr%\CleanupSet.ini
:VBS	
	call cscript.exe //NoLogo %SYSTEMDRIVE%\Scripts\Acties\cleanup.vbs %syscleanini%
	if exist %CleanupSet% (
		for /f "delims=^" %%I in (%CleanupSet%) do call cscript.exe //NoLogo %SYSTEMDRIVE%\Scripts\Acties\cleanup.vbs "%%I"
	)
	
	goto :Einde
:======================================================
:Einde
	rem exit 0