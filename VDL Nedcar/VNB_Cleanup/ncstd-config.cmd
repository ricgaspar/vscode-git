  @echo off
:---------------------
: Version 5.0.0c
:---------------------
:Start
  verify on
  setlocal

: WE ARE NOT USING THIS SCRIPT ANYMORE!
: The lines below are only intended for W2k3 machines

  cd /d C:\Scripts\Config\
  if exist C:\Scripts\Config\install.ps1 powershell C:\Scripts\Config\install.ps1

:E2