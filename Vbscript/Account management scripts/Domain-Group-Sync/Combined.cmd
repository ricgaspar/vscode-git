	@echo off
:Start
	for /f "delims=!" %%i in (combinegroups.txt) do (
		cscript //NoLogo SyncCombinedGroups.vbs "%%i"
	)
	copy C:\Logboek\GroupCombinedSync.log "D:\Account management scripts\Domain-Group-Sync\Report\GroupCombinedSync.log" /Y
:Einde