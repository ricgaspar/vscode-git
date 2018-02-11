
Dim objArgs, objCount, strArgs
Set objArgs = Wscript.Arguments
strUsername = objArgs(0)

intRet = deleteUser(strUsername)

wscript.quit(intRet)
	
Function DeleteUser(strUser)
	Dim intRet, strDN
	
	strDN=QueryAD_User(strUser)	
	If Len(Trim(strDN))<=0 Then
		wscript.echo Now() & " : The account " & strUser & " cannot be found!"
		intRet=2
	Else
		wscript.echo Now() & " : " & strDN
		On Error Resume Next
		
		'Get the ADsPath for the domain to search. 
		dim Root, sDomain
		Set Root = GetObject("LDAP://rootDSE")	
		sDomain = Root.Get("rootDomainNamingContext")
		
		' Container where the account is located. 
		dim sADSPath	
		sADsPath = "LDAP://cn=users," & sDomain	
		
		' Delete object from container	
		dim objOU	
		Set objOU = GetObject(sADsPath)
		objOU.delete "user", "cn=" & strUser
		
		' Show the results
		If err.number<>0 Then
			wscript.echo Now() & " : Error while removing " & strUser & " from " & sADsPath
			intRet=1
		Else
			wscript.echo Now() & " : Successfully removed " & strUser & " from " & sADsPath
			intRet=0
		End If
			
	End If
	DeleteUser = intRet
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
	'Choose the Global Catalog you want to search and build the ADsPath
	'---------------------------------------------------------
	sDomain = root.Get("rootDomainNamingContext")
	Set domain = GetObject("GC://" & sDomain)
	sADsPath = "<" & domain.ADsPath & ">"	
	 
	'--------------------------------------------------------
	'Build the search filter.
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

	' Halleluja. We've arrived.
	QueryAD_User = Path

End Function
