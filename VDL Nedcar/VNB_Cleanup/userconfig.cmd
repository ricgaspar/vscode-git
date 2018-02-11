  @echo off
:---------------------
: Version 5.0.0
:---------------------
  setlocal

:Start
  ver > %temp%\ver.txt
  find "Version 6." %temp%\ver.txt>nul
  if errorlevel 1 goto NoW2K8
  set ELEVCMD="C:\Scripts\Elevation\Elevate.cmd"
:NoW2K8

:PsReg
  if exist %SYSTEMDRIVE%\Scripts\Registry\sysint.reg call %ELEVCMD% regedit /S %SYSTEMDRIVE%\Scripts\Registry\sysint.reg  
:BgInfo
  if exist %SYSTEMDRIVE%\Scripts\BGInfo\bginfo.cmd call %ELEVCMD% %SYSTEMDRIVE%\Scripts\BGInfo\bginfo.cmd

:Elevation tools are installed during logon. Only when log file in user profile does not exist!
:If NCSTD_VER environment variable is changed (GPO) this script will be reapplied during logon.
  set ELELOG="%USERPROFILE%\Elevation-tools-%NCSTD_VER%.log"
  if exist %ELELOG% goto Einde

:InstallToys
  if not !%ELEVCMD%==! (
    if exist C:\Scripts\Elevation (
      %SYSTEMDRIVE%\Scripts\Utils\klok nu>%ELELOG%
      echo Installing Elevation prompts...
      echo Installing Elevation prompts>>%ELELOG%
      echo Installing CmdHere.inf>>%ELELOG%
      call %ELEVCMD% "%SystemRoot%\System32\InfDefaultInstall.exe" "C:\Scripts\Elevation\CmdHere.inf"
      echo Installing CmdHereAsAdmin.inf>>%ELELOG%
      call %ELEVCMD% "%SystemRoot%\System32\InfDefaultInstall.exe" "C:\Scripts\Elevation\CmdHereAsAdmin.inf"
      echo Installing PowerShellHere.inf>>%ELELOG%
      call %ELEVCMD% "%SystemRoot%\System32\InfDefaultInstall.exe" "C:\Scripts\Elevation\PowerShellHere.inf"
      echo Installing PowerShellHereAsAdmin.inf>>%ELELOG%
      call %ELEVCMD% "%SystemRoot%\System32\InfDefaultInstall.exe" "C:\Scripts\Elevation\PowerShellHereAsAdmin.inf"
    )
  )
  goto Einde
:Einde
