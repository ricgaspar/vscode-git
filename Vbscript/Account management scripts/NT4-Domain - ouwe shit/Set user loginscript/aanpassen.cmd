	@echo off
	cls
	
	if not exist users.txt goto Err1	
:Start
	for /f %%i in (users.txt) do call :SetLogon %%i
	goto Einde
:SetLogon
	Echo Aanpassen gebruiker %1
	cusrmgr.exe -u %1 -m \\S001 -n logon.bat
	goto Einde
:Err1
	echo Dit script heeft als input de file USERS.TXT (met per regel een UID) nodig!
	echo Het input bestand werd niet gevonden. 
	pause
:Einde