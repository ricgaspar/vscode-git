@copy "%~dp0log_wifi_data.*" "%WINDIR%\Tooling\"* /Y
@copy "%~dp0Wifi_SignalStrength_Log.ps1" "%WINDIR%\Tooling\"* /Y
@powershell -ExecutionPolicy ByPass -file "%~dp0Wifi_SignalStrength_Log.ps1"
rem @exit 0