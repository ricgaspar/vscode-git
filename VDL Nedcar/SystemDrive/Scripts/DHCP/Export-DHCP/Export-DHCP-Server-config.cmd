	@echo off
:Start
	if !%1==! goto Err1
	call PrintMess "Exporting configuration info from server %1"
	netsh dhcp server \\%1 dump>%1-Server-Dump.txt	
	if not exist \\S031\Data$\Backup\DHCP md \\S031\Data$\Backup\DHCP
	if not exist \\S031\Data$\Backup\DHCP\Export-DHCP\ md \\S031\Data$\Backup\DHCP\Export-DHCP\
	copy %1-Server-Dump.txt \\S031\Data$\Backup\DHCP\Export-DHCP\%1-Server-Dump.txt /Y

	echo ------------------------------------------------------------------------>%1-Server-Config-DNS.txt	
	echo netsh dhcp server \\%1 show dnsconfig - Displays the DNS dynamic update configuration for the server.>>%1-Server-Config-DNS.txt
	netsh dhcp server \\%1 show dnsconfig>>%1-Server-Config-DNS.txt	
	echo ------------------------------------------------------------------------>>%1-Server-Config-DNS.txt	
	echo netsh dhcp server \\%1 show dnscredentials - Displays the currently set DNS credentials.>>%1-Server-Config-DNS.txt
	netsh dhcp server \\%1 show dnscredentials>>%1-Server-Config-DNS.txt	
	echo ------------------------------------------------------------------------>>%1-Server-Config-DNS.txt	
	goto Einde

:Err1
	call PrintMess "Parameter error! Missing server name."
	goto Einde

:Einde