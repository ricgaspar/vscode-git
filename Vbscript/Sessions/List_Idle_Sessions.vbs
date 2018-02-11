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

Const DEBUG_TEXT = False
Const ForReading  = 1
Const ForWriting  = 2
Const ForAppending  = 8

Const LOGFILE = "Logboek\secdump-idle-sessions.log"
Const UDL = "secdump.udl"

'Global variables
Dim gDOMAIN        ' Domain (ie. NEDCAR)
Dim gCOMPUTERNAME  ' Computername (ie. B187)

Dim WshNetwork

' --- SET GLOBAL VARIABLES ------------
' Get the current User ID, Domain name and computer name
Set WSHNetwork = WScript.CreateObject("WScript.Network")
gDOMAIN = WshNetwork.UserDomain
gCOMPUTERNAME = WshNetwork.ComputerName

' -- Here we go... ----
Call ClearLog

PrintMess("===================================================")
PrintMess("Procedure List_Idle_Sessions.vbs is started.")
PrintMess("===================================================")


PrintMess("===================================================")
PrintMess("Procedure List_Idle_Sessions.vbs has ended.")
PrintMess("===================================================")

Function List_Idle_Sessions
  strUDL = FindUDL(UDL)
  If Len(strUDL) > 0 Then
    On Error Resume next
    Set ODBC_conn = WScript.CreateObject("ADODB.connection")
    ODBC_conn.open "File Name=" & strUDL
    intError = err.number
    If intError<>0 Then
      PrintMess "Error while connecting to database"
      err.clear()
    Else
      PrintMess("Query DB for idle sessions.")
      Set recset = WScript.CreateObject("ADODB.RecordSet")
      sql = "exec QRY_SESSIONS_TIMEOUT "& chr(34) & strComputer & Chr(34)
      If DEBUG_TEXT Then PrintMess SQL
      recset.open sql, ODBC_conn
      intError = err.number
      If intError<>0 Then
        PrintMess "Error while executing SQL query command."
        printMess err.description()
        err.clear()
      Else
        recset.MoveFirst
        While (Not recset.EOF)
          strComputername=recset.Fields.Item("Computername").Value
          strActiveTime=recset.Fields.Item("ActiveTime").Value
          strIdleTime=recset.Fields.Item("IdleTime").Value
          strUsername=recset.Fields.Item("Username").Value

	  wscript.echo strComputername & "," & strActiveTime & "," & strIdleTime & "," & strUsername
          
          recset.MoveNext
        Wend
      End If
    End If
  Else
  PrintMess "UDL file was not found!"
  End If
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
'  wscript.echo strMessage

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

Function Exec_SQL_Query(strSQL)
  Dim strUDL, ODBC_conn, intError
  'Save gathered information to SQL database
  strUDL = FindUDL(UDL)
  If Len(strUDL) > 0 Then
    On Error Resume next
    Set ODBC_conn = WScript.CreateObject("ADODB.connection")
    ODBC_conn.open "File Name=" & strUDL
    intError = err.number
    If intError<>0 Then
      PrintMess "Error while connecting to database."
      err.clear()
    Else
      Set recset = WScript.CreateObject("ADODB.RecordSet")
      recset.open strSQL, ODBC_conn
      intError = err.number
      err.clear()
      On Error GoTo 0
      If intError<>0 Then
        Call PrintMess("Execution of query resulted in an error!." & CStr(intError) & ": " & strSQL)
      End If
    End If
  End If
End Function


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
    if FSO.FileExists(strTemp) Then strResult = strTemp
    strPath = Mid(strPath,intPos+1)
    intPos = InStr(strPath, ";")
    if intPos=0 then
      strTemp = strPath & "\" & strUDL
      if FSO.FileExists(strTemp) Then strResult = strTemp
    End If
  Loop
  FindUDL = strResult
End Function

Function ClearLog
  set WshShell = WScript.CreateObject("WScript.Shell")
  strPath = WshShell.ExpandEnvironmentStrings("%SystemDrive%")
  strLogFile = strPath & "\" & LOGFILE
  Set FSO = CreateObject ("Scripting.FileSystemObject")
  if FSO.FileExists(strLogFile) Then FSO.DeleteFile(strLogFile)
End Function

