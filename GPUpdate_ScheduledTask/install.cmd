@copy "%~dp0force_gpupdate.cmd" "%WINDIR%\Tooling\"* /Y
@powershell -ExecutionPolicy ByPass -file "%~dp0Configure_SchedTask.ps1"
@exit 0