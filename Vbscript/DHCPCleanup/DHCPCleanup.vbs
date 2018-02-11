'=========================================================================
' Version 1.0
' Authored by   Marcel Jussen
'               KPN Telecom/Professional Services
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

Const DEBUG_INFO  = True
Const ForReading  = 1
Const ForWriting  = 2
Const ForAppending  = 8

Const ADS_PROPERTY_CLEAR = 1

Const LOGFILE = "Logboek\secdump-DHCPCleanup.log"
Const UDL = "secdump.udl"

'Global variables
Dim USERNAME      ' Username (ie. Q055817)
Dim FULLNAME      ' Fullname (ie. Jussen, Marcel)
Dim DOMAIN        ' Domain (ie. NEDCAR)
Dim COMPUTERNAME  ' Computername (ie. B187)

Dim WshNetwork, intMsgCntr
Dim strMessage

' --- SET GLOBAL VARIABLES ------------
' Get the current User ID, Domain name and Computername
Set WSHNetwork = WScript.CreateObject("WScript.Network")
USERNAME = WSHNetwork.UserName
DOMAIN = WshNetwork.UserDomain
COMPUTERNAME = WshNetwork.ComputerName

Call Main()

wscript.quit()

'---------------------------------------------------------
Function Main()

  Dim strUDL, intError
  Dim strSqlStatement

  strSQLstatement = "select distinct IP_Address, Reservation_name from dhcp_depricated"	
  err.clear()

  'Save gathered information to SQL database
  strUDL = FindUDL(UDL)
  PrintMess strUDL
  If Len(strUDL) > 0 Then
    Set ODBC_conn = WScript.CreateObject("ADODB.connection")
    ODBC_conn.CommandTimeout = 300

    ODBC_conn.open "File Name=" & strUDL
    intError = err.number
    If intError<>0 Then
      PrintMess msgQfrError, "Error while connecting to database"
      err.clear()
    Else
      PrintMess strSQLstatement
      Set recset = WScript.CreateObject("ADODB.RecordSet")
      recset.open strSQLstatement, ODBC_conn      
      
      If err.number<>0 Then
        PrintMess "Execution of statement ended in error."
        err.clear()
      Else
        While not recset.EOF          
          strIP_Address = Trim(recset.fields.item(0).value)          
          strReservation_Name = Trim(recset.fields.item(1).value)
                              
					if PingAble(strReservation_Name) then
						PrintMess "Ping for " + strReservation_Name + " = TRUE"
					end If
          
          recset.movenext()
        Wend
        recset.close()
      End If
    End If
  Else
    PrintMess "UDL file was not found! Value " & UDL
  End If

End Function

'---------------------------------------------------------

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

'---------------------------------------------------------
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