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

Const LOGFILE = "Set-Logonscript.log"
Const ADS_PROPERTY_CLEAR = 1 

If objArgs.Count() < 1 Then
	PrintMess "Wrong parameters!"
	PrintMess "Use setLogonscript.vbs <username>"
	wscript.quit()
End If

Dim strUsername, strLogonscript
strUsername = objArgs(0)

'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

' VOOR HET NIEUWE LOGONSCRIPT
Const cLogonscript = ""


' VOOR HET OUDE LOGONSCRIPT
'Const cLogonscript = "logon.bat"

'++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


strDN = QueryAD_User(strUsername)
strLogonscript = cLogonscript
If Len(strDN) > 0 Then
		PrintMess "Found user " & strUsername & " at " & strDN
		Call SetLogonscript(strDN, strLogonscript)
End If

'----------------------------------------------------------
Function setLogonScript(strDN, strLogonScript)
	Dim nError	
	nError = 0
	
	'On Error Resume Next	
	Set objUser = GetObject("LDAP://" & strDN)
	nError=err.number
	If nError=0 Then
  		PrintMess "Current logon script: " & objUser.scriptPath
		if len(strLogonScript)>0 then
			PrintMess "Setting logon script to: " & strLogonScript
			objUser.scriptPath = strLogonScript
		else
			PrintMess "Clearing logon script property."
			objUser.PutEx ADS_PROPERTY_CLEAR, "scriptPath", 0
		end if
		objUser.SetInfo

		nError=err.number
		If nError<>0 Then			
			PrintMess "ERROR: Could not set Logonscript! " & CStr(nError)
			PrintMess "       " & strDN
			PrintMess "       " & strLogonscript
		Else
			PrintMess "Logon path successfully changed to '" & strLogonscript & "'"
		End If
		err.clear()
	Else
		PrintMess "ERROR: Could not connect to: " & strDN
		err.clear()
	End If
	setLogonScrip = nError
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

Function Show_USER_CLASS()

	Set objUserClass = GetObject("LDAP://schema/user")
	Set objSchemaClass = GetObject(objUserClass.Parent)
 
	i = 0
	WScript.Echo "Mandatory attributes:"
	For Each strAttribute in objUserClass.MandatoryProperties
		i= i + 1
		WScript.Echo i & vbTab & strAttribute
		Set objAttribute = objSchemaClass.GetObject("Property",  strAttribute)
    		WScript.Echo " (Syntax: " & objAttribute.Syntax & ")"
    		If objAttribute.MultiValued Then
        		WScript.Echo " Multivalued"
    		Else
        		WScript.Echo " Single-valued"
    		End If
	Next
 
	WScript.Echo VbCrLf & "Optional attributes:"
	For Each strAttribute in objUserClass.OptionalProperties
    		i=i + 1
    		WScript.Echo i & vbTab & strAttribute
    		Set objAttribute = objSchemaClass.GetObject("Property",  strAttribute)
    		WScript.Echo " [Syntax: " & objAttribute.Syntax & "]"
    		If objAttribute.MultiValued Then
        		WScript.Echo " Multivalued"
    		Else
        		WScript.Echo " Single-valued"
    		End If
	Next

End Function