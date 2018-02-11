	@echo off
:Start
	powershell -ExecutionPolicy Bypass -file "%~dp0get-weather.ps1"
	powershell -ExecutionPolicy Bypass -file "%~dp0get-buienradar.ps1"
:Einde