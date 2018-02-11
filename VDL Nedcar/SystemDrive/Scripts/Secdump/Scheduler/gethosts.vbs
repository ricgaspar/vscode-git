'=========================================================================
' Version 1.0
' Authored by   Marcel Jussen
'               KPN MITS
'=========================================================================

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

Const UDL = "secdump.udl"
strUDL = FindUDL(UDL)

Const ForReading = 1, ForWriting = 2, ForAppending = 8

' Open Cleanup log and append messages.
Dim strLogFileName
Dim objFSOin, fsoLog
strLogFilename="C:\Logboek\NCSTD\RemoteUpdate-CreateHostsList.log"
Set objFSOLog = CreateObject("Scripting.FileSystemObject")
Set fsoLog=objFSOLog.OpenTextFile(strLogFilename,ForWriting,True)

Call CreateHostsFile()

Function CreateHostsFile()
  Dim objFSOout, fsoHostSkipped
  Set objFSOout = CreateObject("Scripting.FileSystemObject")
  Set fsoHost=objFSOout.OpenTextFile("hosts.ini", ForWriting, True)

  ' Query SQL database
  Set ODBC_conn = WScript.CreateObject("ADODB.connection")
  Set recset = WScript.CreateObject("ADODB.RecordSet")
  ODBC_conn.open "File Name=" & strUDL

  strSQL="exec QRY_REMOTEUPDATE"
  recset.open strSQL, ODBC_conn

  While not recset.EOF
    strComputer = Trim(recset("systemname"))
    PrintMess "Checking " & strComputer
    If PingSystem(strComputer) Then
      fsoHost.WriteLine(strComputer)
    Else
      PrintMess strComputer & " did not respond to ping check."
    End If
    recset.movenext
  Wend
  recset.close()

  fsoHost.close()
  PrintMess String(40,"=")
End Function

Function PingSystem(strComputer)
  Dim objShell, objExec, strPingResults, result
  result = false

  PrintMess "- Ping connectivity check."
  Set objShell = CreateObject("WScript.Shell")
  Set objExec = objShell.Exec("ping -n 2 -w 500 " & strComputer)
  strPingResults = LCase(objExec.StdOut.ReadAll)
  If InStr(strPingResults, "reply from") Then result=True
  If Result<>True Then PrintMess "*** ERROR: Ping was not successfull."
  PingSystem=result
End Function

Sub PrintMess(strMessage)
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

  strOutText = strOutText & " " & strMessage
  wscript.echo strOutText
  fsoLog.writeline strOutText
End Sub

Function FindUDL(strUDL)
  Dim strResult, WshShell, strPath, intPos
  Dim strFolder, FSO, strTemp
  Set FSO = CreateObject ("Scripting.FileSystemObject")
  strResult = ""
  set WshShell = WScript.CreateObject("WScript.Shell")
  strPath = WshShell.ExpandEnvironmentStrings("%Path%")
  intPos = InStr(strPath, ";")
  Do While intpos > 0 And Len(strResult)=0
    strFolder = Mid(strPath,1,intPos-1)
    If Right(strFolder,1) = "\" Then strFolder=Left(strFolder, Len(strFolder)-1)
    strTemp = strFolder & "\" & strUDL
    If DEBUG_INFO Then wscript.echo "  [" & strTemp & "]"
    if FSO.FileExists(strTemp) Then strResult = strTemp
    strPath = Mid(strPath,intPos+1)
    If DEBUG_INFO Then wscript.echo "  remains [" & strPath & "]"
    intPos = InStr(strPath, ";")
    if intPos=0 then
      strTemp = strPath & "\" & strUDL
      If DEBUG_INFO Then wscript.echo "  [" & strTemp & "]"
      if FSO.FileExists(strTemp) Then strResult = strTemp
    End If
  Loop
  If DEBUG_INFO Then wscript.echo strResult
  FindUDL = strResult
End Function