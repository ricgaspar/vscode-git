	@echo off
	cd /d C:\Scripts\Secdump\ERS

:Start
	: Synchronise contents of ERS with Active Directory
	: This procedure corrects user account information from ERS with AD
	powershell ./Import_ERS_2_AD.ps1
	
:Einde