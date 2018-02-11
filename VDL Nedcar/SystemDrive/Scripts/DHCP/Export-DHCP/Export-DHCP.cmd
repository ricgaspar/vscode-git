	@echo off
	cd /d D:\DHCP\Export-DHCP
	set DHCPLOG=%SYSTEMDRIVE%\Logboek\Export-DHCP.log
	call C:\Scripts\Secdump\setsql.cmd
	
:Start
	if exist *.txt del *.txt /q > nul
	if exist *.csv del *.csv /q > nul
	
	echo "Server","Scope","IP_Address","MAC","Reservation_name","Description">DHCP-reservations.csv	
	echo "Server","Scope","Subnet mask">DHCP-scopes.csv	
	
:----------------------------------------
:DumpServersFromAD
	call Export-DHCP-Servers.cmd
	if not exist dhcp-servers.txt goto Err1
:DumpServer
	
	for /f %%i in (dhcp-servers.txt) do (
		call Export-DHCP-Server-Config.cmd %%i				
		: Create CSV Exports		
		call Export-DHCP-Scopes.cmd %%i		
		call Export-DHCP-Reservations.cmd %%i	
	)
	goto Einde
:----------------------------------------
:Err1
	call PrintMess "DHCP Servers werden niet gevonden!"
	goto Einde
:----------------------------------------
	
	
:Einde