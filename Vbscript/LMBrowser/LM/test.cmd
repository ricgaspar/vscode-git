	@echo off
:Start
	for /f %%j in (hosts.ini) do (
		echo server  ==[ %%j ]============================
		for /f "delims=~" %%i in (regkey.ini) do (			
			echo Registry key: \\%%j\%%i
			regfree -listvalue \\%%j\%%i 			
		)
		echo Status BROWSER service on %%j.
		sc \\%%j query browser | find /I "STATE"
		echo ==========================================
	)