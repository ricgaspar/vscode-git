	@echo off
:Start
	start powershell.exe -ExecutionPolicy Bypass -NoProfile -file "%~dp0install.ps1"
:Einde
	exit 0