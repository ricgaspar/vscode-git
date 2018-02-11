'#########################################################################
'#
'#
'# FUNCTION: Check Users domain presence.
'#
'# AUTHOR: Marcel Jussen
'#
'# COMMENT: This script uses ADSI and VBScript to access the Windows NT4
'# domain user information.
'#
'# Do not attempt to run this script with out ADSI and IE 5.0 (with
'# VBScript) installed. Users must be Administrators in the domain to be
'# successful. This script is for W2K/W2K3 only.
'#
'#########################################################################

' Constant definities
const ForReading = 1
const ForWriting = 2

Call Main()

Sub Main()
	' Assign Variables
	Dim strUID
	Dim strInFile, objFile, objInFile
	Dim objArguments
	Dim intReturn
	
	'Get the command line arguments
	set objArguments = WScript.arguments
	if objArguments.Count < 1 Then
		strInFile = InputBox("This script checks accounts if present in the current domain." & CRLF & _ 
			"What is the input file containing the user account information" & CRLF & CRLF & "Press Cancel to quit.", 2)
	Else
		strInFile = objArguments.Item(0)
	End If
	
	If strInFile = "" Then
		WScript.Quit(1)
	End If
	
	Set objFile = CreateObject("Scripting.FileSystemObject")
'
	'Open Output file for saving results
	'
	Set objOutFile = objFile.OpenTextFile("results.log", ForWriting, True)
	objOutFile.writeline("Script start: " & Now())
	objOutFile.writeline(String(80, "-"))
	objOutFile.writeline("The following accounts cannot be found in the current domain.")

	Dim strDN, strText
	
	'
	'Open Input file for reading share info
	'
	If objFile.FileExists(strInFile) = True then

		'
		'Open Input file for reading share info
		'
		Set objInFile = objFile.OpenTextFile(strInFile, ForReading, False)
		Do while objInFile.AtEndofStream <> True
				strUID = Trim(objInFile.ReadLine)		
				strDN=QueryAD_User(strUID)	
				If Len(Trim(strDN))<=0 Then
					strText = strUID
					objOutFile.writeline(strText)
					wscript.echo strText
				End If				
		loop
	Else
		strError = "ERROR: File " & strInFile & " was not found.!!"		
		WScript.echo strError
		objOutFile.writeline(strError)
		intDoIt =  MsgBox(strError, vbOKCancel , "Yo bro...")		
	End If
	
	objOutFile.writeline(String(80, "-"))
	objOutFile.writeline("Script end: " & Now())
	
	objOutFile.close()
End Sub

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