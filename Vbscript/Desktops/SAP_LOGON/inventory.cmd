	@echo off
:Start

	rem goto :CheckShortcuts

:CheckPing
	if exist pingable.ini del pingable.ini >nul
	if exist failed.ini del failed.ini >nul
	for /F %%i in (systems.ini) do (
		klok nu
		echo %%i
		ping %%i -n 1 -w 1000 | find "Reply from" 
		if not errorlevel 1 (
			echo %%i>>pingable.ini
		) else (
			echo %%i>>failed.ini
		)
	)	
	
:CheckPath
	cls
	if exist NoAccess.ini del NoAccess.ini >nul
	if exist SAPguiFound.ini del SAPguiFound.ini >nul
	if exist SAPguiNotFound.ini del SAPguiNotFound.ini >nul
	for /F %%i in (pingable.ini) do (
		klok nu 
		echo %%i
		if exist "\\%%i\c$\Program Files\" (
			if exist "\\%%i\c$\Program Files\SAP\FrontEnd\SAPgui\SAPgui.exe" (
				echo %%i>>SAPguiFound.ini
			) else (
				echo %%i>>SAPguiNotFound.ini
			)
		) else (
			echo %%i>>NoAccess.ini
		)
	)
	
:CheckEnv
	cls	
	if exist results.txt del results.txt >nul
	if exist shortcuts.txt del shortcuts.txt >nul
	for /F %%i in (SAPguiFound.ini) do (
		klok nu
		echo %%i
		cscript //NoLogo getremoteenv.vbs %%i >> results.txt
		cscript //NoLogo shortcuts.vbs %%i >> shortcuts.txt
	)
	
	
	