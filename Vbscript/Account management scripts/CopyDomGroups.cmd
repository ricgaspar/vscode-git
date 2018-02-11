	@echo off
:Start
	if {%2}=={} @echo Syntax: Call CopyDomGroups From Add_or_Replace [To]&goto :EOF
	setlocal
	set from=%1
	set ar=%2
	set to=%username%
	if not {%3}=={} set to=%3
	if /i "%ar%" EQU "a" goto arok
	if /i "%ar%" NEQ "r" @echo Syntax: Call CopyDomGroups From MergeReplace [To]&goto finish
:arok
	for /f "Tokens=*" %%u in ('dsquery user -samid %from%') do set fdn=%%u
	if not defined fdn @echo CopyDomGroups %from% not found.&goto finish
	for /f "Tokens=*" %%u in ('dsquery user -samid %to%') do set tdn=%%u
	if not defined tdn @echo CopyDomGroups %to% not found.&goto finish
	if /i "%ar%" EQU "a" goto add
	@echo.>%TEMP%\CopyDomGroups.tmp
	for /f "Tokens=*" %%a in ('dsget user %fdn% -memberof') do @echo %%a>>%TEMP%\CopyDomGroups.tmp
	for /f "Tokens=*" %%b in ('dsget user %tdn% -memberof ^|findstr /i /l /v /g:%TEMP%\CopyDomGroups.tmp') do set DN=%%b&call :rparse
:add
	@echo.>%TEMP%\CopyDomGroups.tmp
	for /f "Tokens=*" %%a in ('dsget user %tdn% -memberof') do @echo %%a>>%TEMP%\CopyDomGroups.tmp
	for /f "Tokens=*" %%b in ('dsget user %fdn% -memberof ^|findstr /i /l /v /g:%TEMP%\CopyDomGroups.tmp') do set DN=%%b&call :aparse
:finish
	if exist %TEMP%\CopyDomGroups.tmp del /a %TEMP%\CopyDomGroups.tmp
	endlocal
	goto :EOF
:rparse
	dsmod group %DN% -rmmbr %tdn% >nul
	goto :EOF
:aparse
	dsmod group %DN% -addmbr %tdn% >nul