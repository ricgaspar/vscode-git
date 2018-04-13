	@echo off
:Start	
	powershell ./export_UsersAD2_SAM.ps1 > C:\Logboek\export_UsersAD2.log
	powershell ./export_Contacts.ps1 > C:\Logboek\export_Contacts.log
:Einde