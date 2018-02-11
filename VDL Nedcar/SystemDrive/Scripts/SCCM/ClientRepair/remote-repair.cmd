	@echo off
:Start
	cd /d C:\Scripts\SCCM\ClientRepair
	powershell -ExecutionPolicy ByPass -file remote-repair.ps1
:Rep
	rem if exist d:\repair.cmd call d:\repair.cmd