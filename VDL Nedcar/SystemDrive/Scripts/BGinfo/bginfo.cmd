	@echo off
:Start
	if exist %systemroot%\bginfo.bmp del %systemroot%\bginfo.bmp /Q >nul
        if not exist %systemroot%\bginfo.bmp start %systemdrive%\Scripts\Utils\SysInternals\bginfo.exe C:\Scripts\BGInfo\config.bgi /timer:0 /silent
:Einde

