	@echo off
	cd /d C:\Scripts\Secdump\ERS

:Start
	: Move Q and E accounts to their correct OU in AD.
	powershell ./Move_ExternalUser.ps1
:Einde