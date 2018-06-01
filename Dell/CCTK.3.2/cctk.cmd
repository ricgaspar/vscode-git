	@ECHO OFF 
:Start
	set cmdline=%*
 	ECHO == Setting BIOS Settings ==	
	IF "%PROCESSOR_ARCHITECTURE%" == "AMD64" GOTO :X64
	GOTO X86 
:X64
	SET CCTKPath="X86_64"
	GOTO RunCCTK
:X86
	SET CCTKPath="X86"
	GOTO RunCCTK
:RunCCTK
	ECHO --Running command %CCTKPath%\cctk.exe %CMDLINE%
	md "%PROGRAMDATA%\VDL Nedcar\Logboek\BIOS\" >nul
	call %CCTKPath%\cctk.exe --valsetuppwd=kleinevogel %CMDLINE% >> "%PROGRAMDATA%\VDL Nedcar\Logboek\BIOS\Dell-BIOS-Settings-Update.log" 2>&1
:Einde
	EXIT /B %errorlevel%