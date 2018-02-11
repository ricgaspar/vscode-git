	@echo off
	pushd D:\Scripts\Remote-Shutdown
:Start
	for /f %%I in (servers.txt) do (
		shutdown.exe /m \\%%I /s /d P:0:0 /t 180 /f
	)
:Einde
	exit