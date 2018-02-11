  @echo off
:---------------------
: Version 6.0.0
:---------------------
:Start
  if exist %SYSTEMDRIVE%\Logboek\Auto-reboot.log del %SYSTEMDRIVE%\Logboek\Auto-reboot.log
:TestW2k
  ver | find /I "Version 5.0">nul
  if errorlevel 1 goto W2Kx

:RebootW2k
  echo Windows 2000 machine is restarted.>%SYSTEMDRIVE%\Logboek\Auto-restart.log
  %systemdrive%\Scripts\Utils\shutdown.exe \\%COMPUTERNAME% /R /T:360 /C
  goto Einde

:W2Kx
  echo Windows W2kx machine is restarted.>%SYSTEMDRIVE%\Logboek\Auto-restart.log
  shutdown.exe /r /d P:0:0 /t 360 /f /c "Scheduled restart of server."
:Einde