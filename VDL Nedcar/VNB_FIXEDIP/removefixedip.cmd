	@echo off
:Start
	powershell -ExecutionPolicy ByPass -file "%~dp0fixedip.ps1" -remove %1 %2
	cmd /c "C:\Scripts\BGinfo\bginfo.cmd"
:einde