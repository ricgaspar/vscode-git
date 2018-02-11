	@echo off
:----------------------------------------
:DumpServersFromAD
	call Export-DHCP-Servers.cmd
	if not exist dhcp-servers.txt goto Einde
:DumpServer	
	for /f %%i in (dhcp-servers.txt) do (	
		call Public-Exports.cmd %%i				
	)
:Einde