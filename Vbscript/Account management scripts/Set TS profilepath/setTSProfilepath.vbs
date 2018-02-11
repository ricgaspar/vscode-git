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

Const LOGFILE = "Set-TerminalServices-ProfilePath.log"
Const ADS_PROPERTY_CLEAR = 1

If objArgs.Count() < 1 Then
	PrintMess "Wrong parameters!"
	PrintMess "Use settsprofilepath.vbs <username>"
	wscript.quit()
End If

Dim strUsername, strProfilePath
strUsername = objArgs(0)

'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' VOOR HET NIEUWE PROFIEL
Const cPROFILE = "%UserProfileCitrix%\"

' VOOR HET OUDE PROFIEL
'Const cPROFILE = "\\s060\ctxprof$\"
'strProfilePath = cPROFILE & strUserName

'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

strDN = QueryAD_User(strUsername)
If Len(strDN) > 0 Then
	PrintMess strDN
	strProfilePath = cPROFILE & Trim(strUsername)
	Call SetTSProfilePath(strDN, strProfilePath)
Else
	PrintMess "ERROR: Could not find " & strUsername & " in the domain!" 
End If

'----------------------------------------------------------
Function SetTSProfilePath(strDN, strNewProfilePath)
	Dim nError	
	nError = 0
	
	'On Error Resume Next	
	Set objUser = GetObject("LDAP://" & strDN)
	strTSPath = objUser.TerminalServicesProfilePath
	
	nError=err.number
  	If nError=0 Then
		if len(strNewProfilePath) > 0 then 
			If StrComp(strNewProfilePath, strTSPath)<>0 Then
				objUser.TerminalServicesProfilePath = strNewProfilePath
				objUser.SetInfo			
				nError=err.number
				If nError<>0 Then			
					PrintMess "ERROR: Could not set TSProfilePath! " & CStr(nError)
					PrintMess "       " & strDN
					PrintMess "       " & strNewProfilePath
				Else
					PrintMess "Path successfully changed to " & strNewProfilePath
				End If
			End If
		Else
			objUser.PutEx ADS_PROPERTY_CLEAR, "TerminalServicesProfilePath", 0
			objUser.SetInfo
		End If
		
		err.clear()
	Else
		PrintMess "ERROR: Could not connect to: " & strDN
		err.clear()
	End If
	SetTSProfilePath = nError
End Function

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

'----------------------------------------------------------
Function QueryAD_User(strUsername)
	Dim Con, Root, Domain, sDomain, sFilter, sAttribsToReturn, sDepth 
	Dim rs, i, Path
	Dim oCommand 
	Dim objArgs
	Dim ADsObject
	Dim sADsPath
	Dim objName
	Dim objClass
	Dim objSchema
	Dim classObject

	On Error Resume Next

	'--------------------------------------------------------
	'Create the ADO connection object
	'--------------------------------------------------------
	Set Con = CreateObject("ADODB.Connection")
	Con.Provider = "ADsDSOObject"
	Con.Open "Active Directory Provider"

	'Create ADO command object for the connection.
	Set oCommand = CreateObject("ADODB.Command")
	oCommand.ActiveConnection = Con
 
	'Get the ADsPath for the domain to search. 
	Set Root = GetObject("LDAP://rootDSE")

	'---------------------------------------------------------
	'Choose the NC you want to search and build the ADsPath
	'---------------------------------------------------------
	sDomain = root.Get("rootDomainNamingContext")
	Set domain = GetObject("GC://" & sDomain)
	sADsPath = "<" & domain.ADsPath & ">"	
	 
	'--------------------------------------------------------
	'Build the search filter
	'--------------------------------------------------------
	sFilter = "(&(objectCategory=person)(objectClass=user)(Name=" & strUsername & "))"
	sAttribsToReturn = "distinguishedName"
	sDepth = "subtree"

	'---------------------------------------------------------
	'Assemble and execute the query
	'---------------------------------------------------------
	oCommand.CommandText = sADsPath & ";" & sFilter & ";" & sAttribsToReturn & ";" & sDepth	
	Set rs = oCommand.Execute

	'---------------------------------------------------------
	' Navigate the record set and get the object's DN
	'---------------------------------------------------------
	rs.MoveFirst
	While Not rs.EOF
    For i = 0 To rs.Fields.Count - 1
    	If rs.Fields(i).Name = "distinguishedName" Then
	    	Path = rs.Fields(i).Value
      End If        
    Next
    rs.MoveNext
	Wend

	QueryAD_User = Path

End Function