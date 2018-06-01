	@echo off
	cd /d "%~dp0"
	call "%~dp0InstallHAPI.cmd"
:WakeOnLAN
	call "%~dp0cctk.cmd" --deepsleepctrl=disable
	call "%~dp0cctk.cmd" --wakeonlan=enable
:Power
	call "%~dp0cctk.cmd" --acpower=last
:Einde
	exit 0