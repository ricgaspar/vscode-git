	@echo off
:Start	
	if exist C:\Logboek\VNB-QST-Validate.log del C:\Logboek\VNB-QST-Validate.log /Q /F>nul
	powershell -ExecutionPolicy ByPass -file "%~dp0validate.ps1" %1
	rem if exist C:\Logboek\VNB-QST-Validate.log start /max notepad.exe C:\Logboek\VNB-QST-Validate.log