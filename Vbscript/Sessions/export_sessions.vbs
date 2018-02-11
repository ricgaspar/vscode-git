'------------------------------------------------------------------------#
'#
'#
'# AUTHOR: Marcel Jussen
'#
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

'On Error Resume Next

Const DEBUG_TEXT = False
Const ForReading  = 1
Const ForWriting  = 2
Const ForAppending  = 8

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20


Const LOGFILE = "Logboek\getsessions.log"

Set WSHNetwork = WScript.CreateObject("WScript.Network")
gCOMPUTERNAME = WshNetwork.ComputerName
If objArgs.Count >= 1 Then
  gCOMPUTERNAME = objArgs(0) 
End If

Call ClearLog

PrintMess("===================================================")
Call GetSystemSessions
PrintMess("===================================================")

Function GetSystemSessions()
  Set OutFile = CreateObject("WScript.Shell")
  Set FileSystem = CreateObject("Scripting.FileSystemObject")
  Set TextFile = FileSystem.OpenTextFile ("ServerSession.csv", ForWriting, True)

  TextFile.WriteLine "ActiveTime,ClientType,ComputerName,Description" & _
      ",IdleTime,InstallDate,Name,ResourcesOpened,SessionType,Status" & _
      ",TransportName,UserName"

  PrintMess "Inventory server sessions on "& gCOMPUTERNAME & "."
  Set WMIService = GetObject("winmgmts:\\" & gCOMPUTERNAME & "\root\CIMV2")
  Set Items = WMIService.ExecQuery("SELECT * FROM Win32_ServerSession", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)

  For Each SubItems in Items
      PrintMess SubItems.UserName & vbTab & SubItems.IdleTime
      strText=""     
      strText = SubItems.ActiveTime & ","
      strText = strText & Chr(34) & SubItems.ClientType & Chr(34) & ","
      strText = strText & Chr(34) & SubItems.ComputerName & Chr(34) & ","
      strText = strText & Chr(34) & SubItems.Description & Chr(34) & ","
      strText = strText & SubItems.IdleTime & ","
      strText = strText & SubItems.InstallDate & ","
      strText = strText & Chr(34) & SubItems.Name & Chr(34) & ","
      strText = strText & SubItems.ResourcesOpened & ","
      strText = strText & SubItems.SessionType & ","
      strText = strText & Chr(34) & SubItems.Status & Chr(34) & ","
      strText = strText & Chr(34) & SubItems.TransportName & Chr(34) & ","
      strText = strText & Chr(34) & SubItems.UserName & Chr(34) & ","
      TextFile.WriteLine StrText
  Next
  TextFile.Close
  PrintMess "Done."
End Function

Function PrintMess(strMsg)
  Dim strMessage, strQfr, wshShell, strPath
  Dim strLogFile

  Dim strOutText, nDate, cTime
  nDate = Date()
  cTime = Time()
  strOutText = CStr(Year(nDate))
  strOutText = strOutText & String( 2-Len(CStr(Month(nDate))),"0" ) & CStr(Month(nDate))
  strOutText = strOutText & String( 2-Len(CStr(Day(nDate))),"0" ) & CStr(Day(nDate))
  strOutText = strOutText & "-"
  strOutText = strOutText & String( 2-Len(CStr(Hour(cTime))),"0" ) & CStr(Hour(cTime))
  strOutText = strOutText & String( 2-Len(CStr(Minute(cTime))),"0" ) & CStr(Minute(cTime))
  strOutText = strOutText & String( 2-Len(CStr(Second(cTime))),"0" ) & CStr(Second(cTime))

  strMessage = strOutText & " : " & strMsg
  wscript.echo strMessage

  On Error Resume Next
  err.clear()
  Dim FSO, OutFileObj
  Set FSO = CreateObject ("Scripting.FileSystemObject")

  set WshShell = WScript.CreateObject("WScript.Shell")
  strPath = WshShell.ExpandEnvironmentStrings("%SystemDrive%")
  strLogFile = strPath & "\" & LOGFILE
  if FSO.FileExists(strLogFile) then
    Set OutFileObj = FSO.OpenTextFile(strLogFile, ForAppending)
  Else
    Set OutFileObj = FSO.CreateTextFile(strLogFile)
  End If
  If err.number<>0 Then
    wscript.echo "Foutje..."
    err.clear()
  Else
    OutFileObj.WriteLine(strMessage)
    OutFileObj.close()
  End if
End Function

Function ClearLog
  set WshShell = WScript.CreateObject("WScript.Shell")
  strPath = WshShell.ExpandEnvironmentStrings("%SystemDrive%")
  strLogFile = strPath & "\" & LOGFILE
  Set FSO = CreateObject ("Scripting.FileSystemObject")
  if FSO.FileExists(strLogFile) Then FSO.DeleteFile(strLogFile)
End Function