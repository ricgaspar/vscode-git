	@echo off
:Start	
	powershell ./export_UsersAD2.ps1 >> C:\log.log	
	powershell ./export_Contacts.ps1 >> C:\log.log	
:Einde