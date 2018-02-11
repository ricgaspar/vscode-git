	@echo off
:Start
	echo CreateObject("Wscript.Shell").Run """" & WScript.Arguments(0) & """", 0, False>%temp%\hide.vbs
	rem type %temp%\hide.vbs