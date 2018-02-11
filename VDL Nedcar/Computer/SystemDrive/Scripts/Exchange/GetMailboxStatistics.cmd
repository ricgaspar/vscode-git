	@echo off
:Start
	cd /d c:\scripts\Exchange
	powershell ./GetMailboxStatistics.ps1

	powershell ./MbStats.ps1