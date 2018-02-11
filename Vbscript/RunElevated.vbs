'=======================================================================
'# RUNELEVATED.VBS 
'# Run commands in elevation mode
'#
'# Marcel Jussen 
'# 1.0 (25-3-2014)
'=======================================================================
set objArgs = wscript.Arguments
if objArgs.Count >= 1 then
  for objCount = 0 to objArgs.Count-1
    if objCount = 0 then strArgs = objArgs(objCount)
    if objCount > 0 then strArgs = strArgs + " " + objArgs(objCount)    
  next
  strArgs = Chr(34) + strArgs + Chr(34)
  set objShell = CreateObject("Shell.Application")
  objShell.ShellExecute strArgs, "cmd.exe", "/c " & strArgs, "runas", 1
end if