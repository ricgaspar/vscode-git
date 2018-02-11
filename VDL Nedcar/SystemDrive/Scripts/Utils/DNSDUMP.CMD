:: DNSdump Version 2.0 - Dean Wells, MSEtechnology - July 2003

:: PURPOSE - Dumps local server's DNS service configuration and zone content. Once dumped, the content
::           can be imported on any other Windows 2000/2003 based DNS server [includes cross OS dumps]

:: DNSdump V2.0 is INCOMPATIBLE with the current public release

:: Supports Windows 2000/2003 members or DCs including Active Directory integrated zones. Application
:: partitions are supported

:: Requires Administrative credentials on local machine. If the DNS server is also a Domain Controller, 
:: Domain Administrative credemtials are required in order to export or import Active Directory integrated 
:: DNS zones

:: Active Directory integrated zones exported from the domain NC will be translated to the local domain 
:: NC in the event of a cross domain export/import. Further behavioral details documented in syntax help

@echo off
setlocal ENABLEDELAYEDEXPANSION

:: Prepare the display
echo.

:: Define environment
set TOOLNAME=DNSdump
set KNOWNPATH=25,53,79,73,74,65,6d,52,6f,6f,74,25,5c,53,79,73,74,65,6d,33,\
set INSTALLROOT=%SystemRoot%\System32\DNS
set DUMP=%~f2
set STDOUT=nul
set STDERR=nul
set WORKING=0
set ERROR=
set domainDN=
set domainDNS=
set SUPPORTEDBUILDS=2195 3790

:: Check local server meets necessary requirements for successful operation

:: Derive operating system version and validate support
for /f "tokens=3 delims=.]" %%v in ('ver') do set BUILD=%%v
for %%s in (%SUPPORTEDBUILDS%) do (
	if not "%%s"=="%BUILD%" (
		if "!ERROR!"=="" set ERROR=1
	) else (
		set ERROR=0
	)
)
if not "%ERROR%"=="0" (
	call :ERROR unsupported operating system version, build "%BUILD%"
	goto :END
)

:: Check for sufficient arguments
if "%2"=="" (
	call :ERROR insufficient arguments
	call :SYNTAX
	goto :END
)

:: Correct and/or report any errors in the dump directory argument
set DUMP=%DUMP:"=%
set TDUMP=%DUMP: =%
if not "%TDUMP%"=="%DUMP%" (
	call :ERROR dump path CANNOT contain spaces, "%DUMP%"
	goto :END
)

:: Locate critical executables, error and terminate if not found
for %%e in (net.exe findstr.exe ldifde.exe regedit.exe) do (
	set where="%%~$PATH:e"
	if "!where!"=="""" (
		call :ERROR critical executable, "%%e", could not be located  
		goto :END
	)
)
	
:: Determine if DNS service is installed on local machine
regedit /E:A "%TEMP%\DNS-Service.TMP" HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DNS
if not exist "%TEMP%\DNS-Service.TMP" (
	call :ERROR DNS service does not appear to be installed on "%COMPUTERNAME%"
	goto :END
)

:: Check local credentials
net user "%username%" | findstr /i "Administrators" 1>%STDOUT% 2>%STDERR%
if errorlevel 1 (
	net user "%username%" | findstr /i /c:"Domain Admins" 1>%STDOUT% 2>%STDERR%
	if errorlevel 1 (
		call :ERROR security context is insufficient, administrative credentials required
		goto :END
	)
)

:: Determine if local machine is member or Domain Controller
regedit /E:A "%TEMP%\DCorMember.TMP" "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ProductOptions"
if not exist "%TEMP%\DCorMember.TMP" (
	call :ERROR unable to determine machine configuration [DC or member]
	goto :END
)
for /f "tokens=2 delims==" %%t in ('type "%TEMP%\DCorMember.TMP" ^| findstr "ProductType"') do (
	if /i "%%t"==""LanmanNT"" (set TYPE=DC) else (set TYPE=MEMBER)
)

:: Get DNS domain name of local machine
if "%TYPE%"=="DC" (
	regedit /E:A "%TEMP%\NTDS-Service.TMP" HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Netlogon\Parameters
	if not exist "%TEMP%\NTDS-Service.TMP" (
		call :ERROR Directory Service configuration could not be determined
		goto :END
	)
	for /f "tokens=1* delims==" %%s in ('type "%TEMP%\NTDS-Service.TMP" ^| findstr "sysvol"') do (
		set SYSVOL=%%t
		set SYSVOL=!SYSVOL:\\=\!
		for /f "tokens=2 delims=>" %%d in ('dir !SYSVOL! /ad ^| findstr "JUNCTION"') do (
			set domainDNS=%%d
			set domainDNS=!domainDNS: =!
		)
	)
	if "!domainDNS!"=="" (
		call :ERROR Directory Service configuration could not be determined
		goto :END
	)
	call :DERIVEDN "!domainDNS!"
	set domainDN=!partDN!
)

:: Begin script body

:: Determine mode of operation
if /i "%1"=="IMPORT" (
	set MODE=IMPORT
)  else (
	if /i "%1"=="EXPORT" (
		set MODE=EXPORT
	) else (
		call :ERROR invalid mode specified, "%1"
		call :SYNTAX
		goto :END
	)
)

:: React to derived mode and create/verify dump directory structure
if "%MODE%"=="EXPORT" (
	if exist "%DUMP%" (
		call :ERROR dump directory already exists, "%DUMP%"
		goto :END
	) else (
		md "%DUMP%" 2>%STDERR%
		if errorlevel 1 (
			call :ERROR unable to create dump directory, "%DUMP%"
			goto :END
		)
		md "%DUMP%\InstallRoot" 2>%STDERR%
		if errorlevel 1 (
			call :ERROR unable to create directory, "%DUMP%\InstallRoot"
			goto :END
		)
		md "%DUMP%\Logs" 2>%STDERR%
		if errorlevel 1 (
			call :ERROR unable to create log directory, "%DUMP%\Logs"
			goto :END
		)
	)
) else (
	if not exist "%DUMP%" (
		call :ERROR specified dump directory NOT found, "%DUMP%"
		goto :END
	)
)

:: Define custom DNS service installation root if supplied
if not "%3"=="" (
	set INSTALLROOT=%~f3
	if not exist "%INSTALLROOT%" (
		call :ERROR DNS installation root, "%INSTALLROOT%", is invalid
		goto :END
	)
) else (

:: Query DNS service registry key for install root ... if non-standard, error
	for /f "delims=: tokens=2" %%i in ('type "%TEMP%\DNS-Service.TMP" ^| findstr /i "ImagePath"') do set ACTUALPATH=%%i
	if not "%KNOWNPATH%"=="!ACTUALPATH!" (
		call :ERROR non-standard DNS installation root, specify zone file path
		set ERROR=2
		goto :END
	)
	if not exist %INSTALLROOT% (
		md %INSTALLROOT%
		if errorlevel 1 (
			call :ERROR unable to create DNS installation root, "%INSTALLROOT%"
			goto :END
		)
	)
)

:: Export only the non locally critical DNS service registry keys to dump directory
if "%MODE%"=="EXPORT" (
	regedit /E:A "%DUMP%\DNS-Service-LegacyZones.REG" HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DNS\Zones
	regedit /E:A "%TEMP%\DNS-Service-Parameters.TMP" HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\DNS\Parameters
	if not exist "%TEMP%\DNS-Service-Parameters.TMP" (
		call :ERROR unable to retrieve DNS service configuration
		set ERROR=2
		goto :END
	)
	type "%TEMP%\DNS-Service-Parameters.TMP" | findstr /v /i "PreviousLocalHostname" >"%DUMP%\DNS-Service-Parameters.REG"
	if not exist "%DUMP%\DNS-Service-Parameters.REG" (
		call :ERROR unable to retrieve DNS service configuration
		set ERROR=2
		goto :END
	)
)

:: Set working directory and indicate state
pushd "%DUMP%" 1>%STDOUT% 2>%STDERR%
echo %TOOLNAME% - Ready to proceed, configuration as follows -
echo.
echo    * Security context is "%USERDOMAIN%\%USERNAME%"
echo    * Mode of operation is "%MODE%"

if "%TYPE%"=="DC" (
	echo    * Domain Controller detected
	echo    * Active Directory domain name is "%domainDNS%"
	set /p nul=   * Active Directory integrated zones WILL be %MODE%ED <nul
	if "%BUILD%" GTR "2195" (
		echo - NDNC's supported
	) else (
		echo - NDNC's NOT supported
	)	
) else (
	echo    * Non Domain Controller detected
	echo    * Active Directory integrated zones UNAVAILABLE
)

echo    * DNS installation root is "%INSTALLROOT%"
echo    * %TOOLNAME% directory is "%DUMP%"
echo.
echo STATUS - Task progress ...
echo.

:: Set WORKING to TRUE and jump to mode
set WORKING=1
goto :%MODE%

:: Should never get here - FATAL ERROR
call :ERROR a fatal unknown error occurred
set ERROR=2
goto :END

:: Define procedures

:IMPORT

:: Check the import directory for valid dump configuration
if not exist "%DUMP%\DNS-Service-Parameters.REG" (
	call :ERROR unable to retrieve DNS service configuration
	goto :END
)
if not exist "%DUMP%\DNS-Software.REG" (
	echo    - legacy "Zones" configuration detected ... LEGACY USED
)

:: Stop the DNS service
echo    - stopping DNS service
net stop dns 2>&1 | findstr /i /c:"not exist" 1>%STDOUT% 2>%STDERR%
if not errorlevel 1 (
	call :ERROR unable to stop DNS service
)

:: Create .REG file to remove existing registry based DNS service configuration
echo    - removing existing DNS service configuration
echo REGEDIT4>%TEMP%\KillKeys.REG
echo.>>%TEMP%\KillKeys.REG
echo [-HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNS\Parameters]>>%TEMP%\KillKeys.REG
echo [-HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNS\Zones]>>%TEMP%\KillKeys.REG

:: Execute the removal
if exist %TEMP%\KillKeys.REG (
	regedit /s %TEMP%\KillKeys.REG
) else (
	call :ERROR existing configuration could NOT be removed
)

:: Delete the temporary registry file
del %TEMP%\KillKeys.REG 1>%STDOUT% 2>%STDERR%

:: Import the registry data
echo    - reconfiguring DNS service
for %%r in ("%DUMP%\DNS-Service-Parameters.REG" "%DUMP%\DNS-Software.REG" "%DUMP%\DNS-Service-LegacyZones.REG") do (
	if exist %%r (
		regedit /s %%r
	) else (
		if not "%%r"==""%DUMP%\DNS-Service-LegacyZones.REG"" (
			call :ERROR unable to reconfigure DNS service registry settings
		)
	)
)

:: Restore the DNS config./zone files
echo    - restoring DNS service configuration files to "%INSTALLROOT%"
xcopy "%DUMP%\InstallRoot\*.*" "%INSTALLROOT%" /h /y 1>%STDOUT% 2>%STDERR%
if errorlevel 1 (
	call :ERROR unable to export configuration files to "%INSTALLROOT%"
	goto :END
)

:: Restore the Active Directory integrated zones
:: Check the type (DC or member), if member skip, if DC import all files with extension .ADzones
if "%TYPE%"=="DC" if exist "%DUMP%\*.ADzones" (
	echo    - importing Active Directory integrated DNS zones from;
	echo.
	for /f %%z in ('dir /b "%DUMP%\*.ADzones"') do (
		set tmpPART=%%~nz
		if /i "!tmpPART:~0,9!"=="CN=System" (
			call :NCIMPORT !tmpPART!
		) else (
			if not "%BUILD%" GTR "2195" (
				echo       * !tmpPART!
				echo          - unsupported partition detected ... IGNORED
				set ERROR=1
			) else (
				call :NCIMPORT !tmpPART!
			)
		)
	echo.
	)
)

:: Start the DNS service
echo    - restarting DNS service
net start dns 2>&1 | findstr "invalid" 1>%STDOUT% 2>%STDERR%
if not errorlevel 1 (
	call :ERROR unable to start DNS service
)

:: Determine level of success
echo.
if "%ERROR%"=="1" (
	echo STATUS - Import partially completed ... ERRORS OCCURRED
) else (
	echo STATUS - DNS service configuration completed
)

goto :END

:: Handles export of DNS configuration and zone content
:EXPORT

echo    - exporting DNS service configuration

if not exist "%DUMP%\DNS-Service-Parameters.REG" (
	call :ERROR unable to retrieve DNS service configuration
	goto :END
)

:: Construct partition information
echo "%domainDNS%">"%DUMP%\PartitionFQDN.DAT"

regedit /E:A "%DUMP%\DNS-Software.REG" "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\DNS Server"

:: Alert user to legacy storage of zone configuration
:: Else clause derives partitions in which zones exist and assumes domain NC as potential candidate
if not exist "%DUMP%\DNS-Software.REG" (
	echo    - legacy "Zones" key located ... LEGACY CONFIGURATION USED
) else (
	for /f "tokens=2 delims==" %%z in ('type "%DUMP%\DNS-Software.REG" ^| findstr "DirectoryPartition"') do (
		echo %%z>>"%DUMP%\PartitionFQDN.DAT"
	)
)

:: Copy existing DNS install root
echo    - exporting DNS service file structure from "%INSTALLROOT%"
copy "%INSTALLROOT%\*.*" "%DUMP%\InstallRoot" /y 1>%STDOUT% 2>%STDERR%
if errorlevel 1 (
	call :ERROR unable to backup DNS installation root, "%INSTALLROOT%"
	set ERROR=2
	goto :END
)

:: Exports Active Directory integrated zones if running on a DC
:: Removes objectGUID references in order to permit import
if "%TYPE%"=="DC" (
	echo    - exporting Active Directory integrated Zones from;
	echo.
	if not exist "%DUMP%\PartitionFQDN.DAT" (
		call :ERROR unable to derive partitions containing DNS zones
	)
	for /f "tokens=*" %%d in ('type "%DUMP%\PartitionFQDN.DAT"') do (
		call :DERIVEDN %%d
		ldifde -s localhost -d "CN=MicrosoftDNS,!partDN!" -f "%DUMP%\!partDN!.ADtmpZones" -j "%DUMP%\Logs" | findstr /i /c:"No Entries found" 1>%STDOUT% 2>%STDERR%
		if not errorlevel 1 (
			set ERROR=1
			echo       * !partDN! - UNHANDLED ERRORS
		) else (
			echo       * !partDN!
		)
		echo          - preparing zones for import
		echo.
		type "%DUMP%\!partDN!.ADtmpZones" | findstr /v "objectGUID" >"%DUMP%\!partDN!.ADzones"
		del "%DUMP%\!partDN!.ADtmpZones" 2>%STDERR%
		call :LOGS %!partDN!
	)
)

:: Determine level of success
echo.
if not "%ERROR%"=="0" (
	echo STATUS - Export partially completed ... ERRORS OCCURRED
) else (
	echo STATUS - Export completed successfully
)
goto :END

:: End script body

:: Define procedures and error/syntax routines

:: Receives a fully qualified domain name as argument 1 and converts it to a distinguished name
:DERIVEDN
set partDN=%*
set partDN=%partDN:~1,-1%
set partDN=.%partDN%
set partDN=%partDN:.=,DC=%
set partDN=%partDN:~1%
if /i "%domainDN%"=="%partDN%" (
	set partDN=CN=System,%partDN%
)
goto :EOF

:: Import supplied naming context and handle logged output
:NCIMPORT

:: Translate DN references for domain NC integrated zones such that a zone exported from a DC in one domain
:: can be imported into the domain NC of a DC in another
if /i "%tmpPART:~0,9%"=="CN=System" (
	if not "%tmpPART:~10%"=="%domainDN%" (
		set APPEND=-c %tmpPART:~10% %domainDN%
		set logDN=CN=System,%domainDN%
	) else (
		set APPEND=
		set logDN=%*
	)
) else (
	set APPEND=
	set logDN=%*
)

ldifde -s localhost -i -k -f "%*.ADzones" -j "%DUMP%\Logs" %APPEND% | findstr /i "error" 1>%STDOUT% 2>%STDERR%
if not errorlevel 1 (
	echo       * %* ... UNHANDLED ERRORS
	set ERROR=1
) else (
	echo       * %*
)

if not "%APPEND%"=="" (
	echo          - cross domain EXPORT/IMPORT detected, domain DN's translated
	echo            ... "%tmpPART:~10%" to "%domainDN%"
)

call :LOGS %logDN%
goto :EOF

:: Rename logged entries for each partition exported or imported in order preserve each log
:LOGS
del "%DUMP%\Logs\*-%MODE%.LOG" 1>%STDOUT% 2>%STDERR%
del "%DUMP%\Logs\*-%MODE%.ERR" 1>%STDOUT% 2>%STDERR%
ren "%DUMP%\Logs\ldif.log" "[%*]-%MODE%.LOG" 1>%STDOUT% 2>%STDERR%
ren "%DUMP%\Logs\ldif.err" "[%*]-%MODE%.ERR" 1>%STDOUT% 2>%STDERR%
goto :EOF

:: Displays errors
:ERROR
if "%WORKING%"=="1" (
	echo    - FAILED ... %*
) else (
	echo ERROR - %*
)
set ERROR=1
goto :EOF

:: Provides assistance with syntax
:SYNTAX
echo.
echo SYNTAX - %TOOLNAME% [IMPORT^|EXPORT] [dump directory] ^<optional install root^>
echo.
echo   * [IMPORT] imports a %TOOLNAME% exported DNS service configuration
echo   * [EXPORT] exports the existing DNS service configuration
echo   * [dump directory] is a local, writable directory path
echo   * [install root] is the local absolute path used by the DNS service
echo.
echo   * %TOOLNAME% requires -
echo     - administrative credentials
echo     - local execution on the DNS server
echo     - Microsoft Windows 2000/2003 server family, builds %SUPPORTEDBUILDS%
echo.
echo   * %TOOLNAME% provides import and export of -
echo     - DNS service configuration
echo     - Active Directory integrated zones and zone configuration
echo     - standard zone files and zone configuration
echo.
echo   * %TOOLNAME% feature notes -
echo     - existing Active Directory zones will NOT be overwritten during IMPORT
echo     - manually erase existing zones IF an authoritative import IS REQUIRED
echo     - ALL zone configuration options WILL be overwritten during IMPORT
echo     - non Active Directory integrated zones WILL be overwritten during IMPORT
echo     - existing DNS service configuration WILL be overwritten during IMPORT
echo     - DNS service WILL be restarted during IMPORT
echo     - detailed logs are preserved beneath the specified DUMP path
goto :EOF

:END

:: Restore previous working directory
popd

:: Clean up
del "%TEMP%\DNS-Service.TMP" 1>%STDOUT% 2>%STDERR%
del "%TEMP%\DNS-Service-Parameters.TMP" 1>%STDOUT% 2>%STDERR%
del "%TEMP%\NTDS-Service.TMP" 1>%STDOUT% 2>%STDERR%
del "%TEMP%\DCorMember.TMP" 1>%STDOUT% 2>%STDERR%

if "%ERROR%"=="2" (
	if "%MODE%"=="EXPORT" (
		del "%DUMP%\InstallRoot" /f /y 1>%STDOUT% 2>%STDERR%
		rd "%DUMP%\InstallRoot" 1>%STDOUT% 2>%STDERR%
		del "%DUMP%\Logs" /f /y 1>%STDOUT% 2>%STDERR%
		rd "%DUMP%\Logs" 1>%STDOUT% 2>%STDERR%		
		del "%DUMP%" /f /q 1>%STDOUT% 2>%STDERR%
		rd "%DUMP%" 1>%STDOUT% 2>%STDERR%
	)
)