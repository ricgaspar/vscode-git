	@echo off
:Start
	for /f %%i in (computers.txt) do (
		net use t: \\%%i\c$ /user:BMWAdminE bmwbmw12
		if exist t: (
			if not exist T:\Scripts md T:\Scripts
			if not exist T:\Scripts\Remote md T:\Scripts\Remote
			echo %~dp0
			xcopy %~dp0*.ps1 T:\Scripts\Remote\* /Y /Q
			xcopy %~dp0IP.cmd T:\Scripts\Remote\* /Y /Q
		)
		net use t: /d

	pause
		psexec \\%%i /user BMWAdminE /password bmwbmw12 C:\Scripts\Remote\IP.cmd
	)