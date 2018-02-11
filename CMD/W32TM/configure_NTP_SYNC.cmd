	@echo off
	cls

	w32tm /config /manualpeerlist:"ntp1.nedcar.nl,0x1 ntp2.nedcar.nl,0x1" /syncfromflags:manual /reliable:yes
	w32tm /config /update

:Restart	
	net stop w32time && net start w32time

:Resync
	w32tm /resync