'------------------------------------------------------------------------#
'#
'# PCI.VBS Dumps PCI Bus to a CSV format.
'# AUTHOR: Marcel Jussen
'# Version 5.0.0
'------------------------------------------------------------------------#
'----------------------- FORCE CSCRIPT RUN -------------------------------
Dim objArgs, objCount, strArgs
Set objArgs = Wscript.Arguments
For objCount = 0 to objArgs.Count - 1
  strArgs = strArgs + " " + objArgs(objCount)
Next
if right(ucase(wscript.FullName),11)="WSCRIPT.EXE" Then
    Dim ObjShell
    Set objShell = WScript.CreateObject("WScript.Shell")
    objShell.Run "cscript.exe //NoLogo " & wscript.ScriptFullName + " " + strArgs, 1
    wscript.quit
end if
'----------------------- FORCE CSCRIPT RUN -------------------------------
Set buses = GetObject("winmgmts:").InstancesOf("Win32_Bus")
wscript.echo "Bus;Description;Status;ErrorDescription"
For Each bus In buses
  Set devices = GetObject("winmgmts:").ExecQuery ("Associators of {Win32_Bus.DeviceID=""" & bus.DeviceID & """} WHERE AssocClass = Win32_DeviceBus")
  For Each device In devices
    WScript.Echo Chr(34) & bus.DeviceID & Chr(34) & ";" & _
      Chr(34) & device.name & Chr(34) & ";" & _
      Chr(34) & device.PNPDeviceID & Chr(34) & ";" & _
      Chr(34) & device.Status & Chr(34) & ";" & _
      Chr(34) & device.ErrorDescription & Chr(34) & ";"
  Next
Next
