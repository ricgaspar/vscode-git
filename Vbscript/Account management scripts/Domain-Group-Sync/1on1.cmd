	@echo off
:Start
	for /f "delims=; tokens=1,2" %%i in (groups.txt) do (
		cscript //NoLogo SyncGroups.vbs "%%i" "%%j"
	)
	copy C:\Logboek\GroupSync.log "D:\Account management scripts\Domain-Group-Sync\Report\GroupSync.log" /Y