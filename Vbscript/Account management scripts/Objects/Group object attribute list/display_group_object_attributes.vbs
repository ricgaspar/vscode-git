'=========================================================================
' Version	1.0
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

Const DEBUG_INFO	= True
Const ForReading 	= 1
Const ForWriting 	= 2
Const ForAppending 	= 8

Const LOGFILE = "display_group_object_attributes.log"
Const ADS_PROPERTY_CLEAR = 1 


'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

call Show_GROUP_CLASS()

'----------------------------------------------------------
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

  strLogFile = LOGFILE
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


Function Show_GROUP_CLASS()

	Set objUserClass = GetObject("LDAP://schema/group")
	Set objSchemaClass = GetObject(objUserClass.Parent)
 
	i = 0
	PrintMess "Mandatory attributes:"
	For Each strAttribute in objUserClass.MandatoryProperties
		i= i + 1
		strText = vbTab & CStr(i) & vbTab & strAttribute
		Set objAttribute = objSchemaClass.GetObject("Property",  strAttribute)
    		strText = strText & vbTab & "(Syntax: " & objAttribute.Syntax & ")"
    		If objAttribute.MultiValued Then
        		strText = strText & vbtTab & " Multivalued"
    		Else
        		strText = strText & vbtTab & " Single-valued"
    		End If
		PrintMess strText
	Next
 
	PrintMess "Optional attributes:"
	For Each strAttribute in objUserClass.OptionalProperties
    		i=i + 1
    		strtext = vbTab & CStr(i) & vbTab & strAttribute
    		Set objAttribute = objSchemaClass.GetObject("Property",  strAttribute)
    		strText = strText & vbTab & " [Syntax: " & objAttribute.Syntax & "]"
    		If objAttribute.MultiValued Then
        		strText = strText & vbTab & " Multivalued"
    		Else
        		strText = strText & vbTab & " Single-valued"
    		End If
		PrintMess strText
	Next

End Function