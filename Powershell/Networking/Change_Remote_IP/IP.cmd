	@echo off
:Start
	if not exist C:\Logboek md C:\Logboek
	Powershell Set-ExecutionPolicy unrestricted -Verbose > C:\Logboek\PS_Policy.log
:Execute
	cd /d C:\Scripts\Remote	
	if exist C:\Scripts\Remote\ChangeIpStack.ps1 (
		Powershell .\ChangeIpStack.ps1
	)