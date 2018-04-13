	@echo off
:======================================================
: Version 6.0.7 (26-07-2017)
:======================================================
	cd /D "%~dp0"
	del *.TempPoint.ps1 /Q /S

	start powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\PSVersion.ps1
	start powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\CollectSysinfo.ps1

	REM NTFS ACL information for all folders is EXTREMELY memory and cpu hungry.
	REM start powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\CollectSysinfo-NTFS-ACL.ps1

:-------------------------------------
:Einde