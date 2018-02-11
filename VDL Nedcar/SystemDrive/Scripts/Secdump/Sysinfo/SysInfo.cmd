	@echo off
:======================================================
: Version 6.0.6 (24-05-2017)
:======================================================
	cd /D "%~dp0"
	powershell -ExecutionPolicy Bypass -NoProfile -File .\PSVersion.ps1
	powershell -ExecutionPolicy Bypass -NoProfile -File .\CollectSysinfo.ps1

:-------------------------------------
:Einde