	@echo off
:Start
	for /F %%I in (users.ini) do cscript //NoLogo setpdwexpiration.vbs %%I
:Einde