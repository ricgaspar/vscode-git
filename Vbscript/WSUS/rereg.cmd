	@echo off
	if !%1==! (
		set SERVER=%COMPUTERNAME%
	)	else (
		set SERVER=%1
	)
	
	echo Reregister Windows update client on computer %SERVER%
	pause
	
:Start
	sc \\%SERVER% stop wuauserv	
	reg DELETE HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate /v AccountDomainSid /f
  reg DELETE HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate /v SusClientId /f
  sc \\%SERVER% start wuauserv
  wuauclt.exe /resetauthorization /detectnow
  