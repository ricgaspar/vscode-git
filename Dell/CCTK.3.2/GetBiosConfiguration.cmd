	@echo off
	cd /d "%~dp0"
	rem call "%~dp0InstallHAPI.cmd"
	md "%PROGRAMDATA%\VDL Nedcar\Logboek\BIOS\" >nul
	echo Retrieve BIOS data from %COMPUTERNAME% > "%PROGRAMDATA%\VDL Nedcar\Logboek\BIOS\Dell-BIOS-Settings.log"
	call "%~dp0getcctk.cmd" --version
    call "%~dp0getcctk.cmd" --biosver
	call "%~dp0getcctk.cmd" --deepsleepctrl
	call "%~dp0getcctk.cmd" --wakeonlan
	call "%~dp0getcctk.cmd" --acpower
:Einde
	exit 0