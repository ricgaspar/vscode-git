	@echo off
	cd /d "%~dp0"
	rem call "%~dp0InstallHAPI.cmd"
	echo Updating BIOS settings on %COMPUTERNAME% > "%PROGRAMDATA%\VDL Nedcar\Logboek\BIOS\Dell-BIOS-Settings-Update.log"
:WakeOnLAN
	call "%~dp0cctk.cmd" --deepsleepctrl=disable
	call "%~dp0cctk.cmd" --wakeonlan=enable
:Power
	call "%~dp0cctk.cmd" --acpower=last
:Einde
	exit 0