
set oArgs = WScript.Arguments
Set objWMIService = GetObject("winmgmts:\\" & oArgs(0) & "\root\cimv2")

Set colShortcuts = objWMIService.ExecQuery("Select * From Win32_ShortcutFile Where " & _
    "Drive = 'c:' AND Path = '\\documents and settings\\all users\\Start Menu\\Programs\\Sap Front End\\'")

For Each objShortcut in colShortcuts
    Wscript.Echo oArgs(0) & vbTab & objShortcut.FileName & vbTab & objShortcut.Name & vbTab & objShortcut.Target    
Next
