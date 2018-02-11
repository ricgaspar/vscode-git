	@echo off
	if !%1==! goto Einde
:start
	klok nu>%temp%\message.txt
	echo %1>>%temp%\message.txt
	call blat %temp%\message.txt -f %COMPUTERNAME%@nedcar.nl -tf recipients.txt -subject %1
:Einde