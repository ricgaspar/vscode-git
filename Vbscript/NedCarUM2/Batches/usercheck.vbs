
Const INFILE = "ExistingUsers.txt"

Set fsi = CreateObject("Scripting.FileSystemObject" )
If not fsi.FileExists(INFILE) Then wcsript.quit

Set objInfile = fsi.OpenTextFile(INFILE, 1, True)

Do While not objInfile.AtEndofStream
	strUsername = Trim(objInfile.ReadLine)
	Call showBasicUIDInfo(strUserName)
	Call CheckUID(strUserName)
Loop

Function CheckUID(strUserName)
	dim bUIDExists
	Dim sHomeFolder, strHomeServer, strHomeShare
	dim bRes, strRef

	If strUserName <> "" Then
		bUIDExists = chkUIDExists(strUserName)
		if bUIDExists then
			' Check if account has a logon script
			'-------------------------------------------
			dim strDN, objUser
			strDN=QueryAD_User(strUserName)
			Set objUser = GetObject("LDAP://" & strDN)
			dim strScript
			strScript = objUser.ScriptPath
			
			if len(strScript)>0 then
				Call ShowText("Logon script: ", strScript)
			else
				strRef = "Error. Account does not have a logon script!"
				Call repairScript(strUsername)
			end if

			' Check if home folder exists
			'-------------------------------------------
			sHomefolder = "\\S034\Data$\" & strUserName
			bRes = chkFolderExists(sHomeFolder)
			if bRes Then
				Call ShowText("Home location: ", sHomeFolder)
			Else
				Call ShowText("Home location: ", "ERROR: " & sHomefolder & " cannot be found!")
				Call repairHome(strUsername)
			end if

			' Check if home folder is shared
			'-------------------------------------------
			strHomeServer = "S034"
			strHomeShare = strUserName & "$"
			bRes = chkShareExists(strHomeServer, strHomeShare)
			if bRes then
				Call ShowText("Home share: ", sHomeShare)
			else
				Call ShowText("Home share: ", "ERROR: " & sHomeShare & " for " & strUserName & " cannot be accessed.")
				Call repairhomeshare(strUsername)
			end if

			' Check if account has a TS profile attached to it.
			'-------------------------------------------
			dim sCtxfolder
			sCtxfolder = objUser.TerminalServicesProfilePath
			if len(sCtxFolder)>0 Then
				Call ShowText("Terminal server profile setting:", sCtxFolder)
			Else
				Call ShowText("Terminal server profile setting:", "ERROR: " & sCtxFolder & "Account does not have a TS profile set to it.")
				Call repairTSProfile(strUserName)
			end if

			' Check if Citrix profile folder exists
			'-------------------------------------------
			bRes = chkFolderExists(sCtxFolder)
			If bRes Then
				Call ShowText("Citrix profile location:", sCtxFolder)
			Else
				Call ShowText("Citrix profile location:","ERROR: " & sCtxFolder & " Citrix profile for " & strUserName & " cannot be accessed.")
				Call repairCtx(strUserName)
			end if
		else
			call MsgBox("Could not find user " & strUserName & " in the domain.", vbCritical, "Error")
		end if
	end If
End Function

'function to list the properties of a user-account
Function showBasicUIDInfo(strUserName)
	dim Usr, sError, strDN
	strDN=QueryAD_User(strUserName)
	
	Wscript.echo "-------------------------------------------------------------------"

	On Error Resume Next
	Dim objUser
	Set objUser = GetObject("LDAP://" & strDN)
	if err.number<0 then
		err.Clear
		call ShowText("ERROR: " , "Could not find user " & strUserName & " in domain " & strDomainName)
	Else
		Call ShowText("Distinguished name: ", strDN)
		call ShowText("Display Name: ", objUser.displayName)
		call ShowText("User Principal Name: ", objUser.userPrincipalName)
		call ShowText("Given name: ", objUser.givenName)
		call ShowText("Description: ", objUser.description)
	End If
End Function

Sub ShowText(strTextLeft, strTextRight)
	wscript.echo strTextLeft & Chr(9) & strTextRight
End Sub

Function chkUIDExists(strUserName)
	chkUIDExists = (Len(QueryAD_User(strUsername)) > 0)
End Function

Function QueryAD_User(strName)
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
	sFilter = "(&(objectCategory=person)(objectClass=user)(Name=" & strName & "))"
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

Function QueryNet_Domain()
	dim WshNetwork
	Set WshNetwork = CreateObject("WScript.Network")
	QueryNet_Domain = WshNetwork.UserDomain
End Function

'- FOLDERS ----------------------------------------------
'function to check if a folder exists
Function chkFolderExists(sFolder)
	dim fso, bResult
	set fso = CreateObject("Scripting.FileSystemObject")
	if isEmpty(sfolder) then
		bResult = False
	else
		bResult = fso.FolderExists(sFolder)
	end if
	chkFolderExists = bResult
End Function

'- SHARES ----------------------------------------------
'function to check if a share exists (calls chkFolderExists)
Function chkShareExists(strServer, strShare)
	dim objShare, blResult, ShareName, share
	dim strDomain

	strDomain = QueryNet_Domain()
	Set objShare= GetOBJect("WinNT://"& strDomain &"/" & strServer &"/lanmanserver")

	' Fill the temp file with share information
	blResult = False
	For each share in objShare
		ShareName = share.name
		if (blResult=False) AND (strShare=ShareName) then blResult=True
	Next
	chkShareExists = blResult
End Function

'function to check file share permissions
Function chkSharePermissions(sServer, sShare)
	dim bResult
	' Procedure is not implemented yet.
	bResult=True
	chkSharePermissions = bResult
End Function

Sub repairHome(strUsername)
	' Add log entry
	Call createHomeShare(strUserName)
End Sub

Sub repairHomeShare(strUserName)
	call repairHome(strUserName)
end Sub

Sub repairScript(strUserName)
	Dim strDN, objUser
	strDN=QueryAD_User(strUserName)
	Set objUser = GetObject("LDAP://" & strDN)
	objUser.Put "scriptPath", "logon.bat"
	objUser.SetInfo
End Sub

Sub repairTSProfile(strUserName)
	dim strDN, objUser
	strDN=QueryAD_User(strUserName)
	Set objUser = GetObject("LDAP://" & strDN)
	objUser.TerminalServicesProfilePath = "\\s060\ctxprof$\" & strUserName
	objUser.SetInfo
End Sub

Sub repairCtx(strUserName)
	Call createCitrixProfile(strUserName)
End Sub

Function createHomeShare(strUserName)
	dim strCommand, strParms
	Dim wshell, intReturn

	call ShowText("Creating account " & strUsername, "Creating home directory. Wait for procedure to finish.")
	strCommand = "C:\nedcarum2\createHomeShare.cmd " & strUserName
	set wshell = createobject("wscript.shell")
	intReturn = wshell.run("%comspec% /c " & strCommand, 0, True)
	call ShowText("Creating account " & strUsername, "Done.")

End Function

Function createCitrixProfile(strUserName)
	Dim wshShell, strCommand, strRun, strUser

	call ShowText("Creating account " & strUsername, "Creating Citrix profile. Wait for procedure to finish.")

	' create shell and run command in RUNAS environment.
	set wshShell = CreateObject("WScript.Shell")
	strCommand = "C:\nedcarum2\createCTXProfile.cmd " & strUsername
	dim intReturn
	intReturn = wshShell.run("%comspec% /c " & strCommand, 0, True)

	call ShowText("Creating account " & strUsername, "Done.")
End Function

