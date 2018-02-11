@if not exist C:\Windows\Patchlog md c:\Windows\Patchlog
@powershell -ExecutionPolicy ByPass -file "%~dp0Wifi_SignalStrength_Log.ps1"
