Dim objArgs, objCount, strArgs, intReturn
Set objArgs = Wscript.Arguments
strUsername = objArgs(0)

intReturn = ChkUserDisabled(strUsername)

wscript.quit(intReturn)

Function ChkUserDisabled(strUser)
	Dim intRet, strDN
	
	strDN=QueryAD_User(strUser)	
	If Len(Trim(strDN))<=0 Then
			wscript.echo Now() & " : The account " & strUser & " cannot be found!"
			intRet=2
	Else
			wscript.echo Now() & " : " & StrDN
			On Error Resume Next
			dim objUser
			Set objUser = GetObject("LDAP://" & strDN)
			If objUser.accountdisabled Then 
				intRet=1
				wscript.echo Now() & " : The account " & strUser & " is disabled."
			Else
				intRet=0
				wscript.echo Now() & " : The account " & strUser & " is not disabled."
			End If
	End If
	ChkUserDisabled = intRet
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