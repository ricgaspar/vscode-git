'========================================================================#
'#
'#
'# AUTHOR: Marcel Jussen
'#
'========================================================================#

'======================= FORCE CSCRIPT RUN ===============================
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
'======================= FORCE CSCRIPT RUN ===============================

Const SOURCE="ping.ini"
Const UDL = "secdump.udl"

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20
Const blDEBUG = False

Const ForReading  = 1
Const ForWriting  = 2
Const ForAppending  = 8
Const TristateFalse = 0

Const HKEY_CURRENT_USER = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002


' === SET GLOBAL VARIABLES ============
' Get the current User ID, Domain name and Computername
Dim gUSERNAME     ' Username (ie. Q055817)
Dim gDOMAIN       ' Domain (ie. NEDCAR)
Dim gCOMPUTERNAME ' Computername (ie. B187)

Dim strLogFileName
Dim objFSO, fsoLog
strLogFilename= "Logboek\pingcheck.log"

Call Set_Globals()      ' Open log
Call Main(objArgs(0))

Function Main(strComputer)
  If PingAble(strComputer) Then
  	PrintMess "  The machine " & strComputer & " was pingable!"  	
	Else
		PrintMess "  The machine " & strComputer & " was NOT pingable!"		
  End If  
End Function

Function PingAble(strComputer)
  Dim blResult
  blResult=False
  On Error Resume Next

  Set objShell = CreateObject("WScript.Shell")
  strCommand = "%comspec% /c ping -n 3 -w 1000 " & strComputer & ""
  Set objExecObject = objShell.Exec(strCommand)

  Do While Not objExecObject.StdOut.AtEndOfStream
    strText = objExecObject.StdOut.ReadAll()
    If Instr(strText, "Reply") > 0 Then blResult=True
  Loop

  On Error GoTo 0
  PingAble=blResult

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
  If blDEBUG Then PrintMess strResult
  FindUDL = strResult
End Function

Function Exec_SQL_Query(strSQL)
  Dim strUDL, ODBC_conn, intError
  'Save gathered information to SQL database
  On Error GoTo 0
  strUDL = FindUDL(UDL)
  If Len(strUDL) > 0 Then
    On Error Resume next
    Set ODBC_conn = WScript.CreateObject("ADODB.connection")
    ODBC_conn.open "File Name=" & strUDL
    intError = err.number
    On Error GoTo 0
    If intError<>0 Then
      PrintError "Error while connecting to database.", strUDL
      err.clear()
    Else
      On Error Resume next
      Set recset = WScript.CreateObject("ADODB.RecordSet")
      If blDEBUG Then PrintMess strSQL
      recset.open strSQL, ODBC_conn
      intError = err.number
      On Error GoTo 0
      err.clear()
      If intError<>0 Then
        PrintError "Execution of query resulted in an error!. ", CStr(intError) & ": " & strSQL
      End If
    End If
  End If
End Function

Function Set_Globals
  gUSERNAME = Get_UserName
  gDOMAIN = Get_DomainName
  gCOMPUTERNAME = Get_SystemName

  strLogFilename="C:\" & strLogFilename  
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  Set fsoLog=objFSO.OpenTextFile(strLogFilename, ForWriting, True)
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
  strOutText = strOutText & ": " & strMessage
  wscript.echo strOutText
  fsoLog.writeline strOutText
End Sub

Sub PrintError(strErrorString, strText)
  PrintMess "** ERROR: " & strErrorString
  PrintMess "**        " & strText
End Sub

