	@echo off
:Start
	powershell -ExecutionPolicy ByPass -file "%~dp0fixedip.ps1" -update %1 %2
	call "%~dp0nvspbind.exe" -d * ms_tcpip6 >null
	cmd /c "C:\Scripts\BGinfo\bginfo.cmd"
:einde