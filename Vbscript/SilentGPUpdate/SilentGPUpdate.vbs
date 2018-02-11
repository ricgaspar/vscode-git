'Define Variables and Objects.
Set WshShell = CreateObject("Wscript.Shell")

'Refresh the USER policies and also answer no to logoff if asked.
Result = WshShell.Run("cmd /c echo n | gpupdate /target:user /force",0,true)

'Refresh the Computer policies and answer no to reboot. 
Result = WshShell.Run("cmd /c echo n | gpupdate /target:computer /force",0,true)

'Hand back the errorlevel
Wscript.Quit(Result)
