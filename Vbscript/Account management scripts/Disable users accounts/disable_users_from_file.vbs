'#########################################################################
'#
'#
'# FUNCTION: Disable Users
'#
'# AUTHOR: Marcel Jussen
'#
'# COMMENT: This script uses ADSI and VBScript to access the Windows AD
'# domain user information.
'#
'# Do not attempt to run this script with out ADSI and IE 5.0 (with
'# VBScript) installed. Users must be Administrators in the domain to be
'# successful. This script is for W2K/W2K3 only.
'#
'#########################################################################

'
' Constants 
const ForReading = 1
const ForWriting = 2
const DebugScript = False

Call Main()
WScript.Quit

Sub Main()

	Dim strInFile, objFile, objInFile
	Dim objArguments

	Wscript.echo "Disable Users from current domain."
	Wscript.echo ""
	'
	'Get the command line arguments
	set objArguments = WScript.arguments
	if objArguments.Count < 1 Then
		strInFile = InputBox("This script disables domain accounts in the current domain." & _ 
			CRLF & "What is the input file containing the user account information?" & _ 
			CRLF & CRLF & "Press Cancel to quit.", 2)
	Else
		strInFile = objArguments.Item(0)
	End If
	
	If strInFile = "" Then
		WScript.Quit
	End If

	'
	' Ask confirmation before changing anything
	'
	intDoIt =  MsgBox("Do you wish to start disabling user accounts?", vbOKCancel + vbInformation, "Now what?")
	If intDoIt = vbCancel Then	
		' Do nothing. We are very good at that...
	Else 
		Call DisableUIDs(strInFile)
		intDoIt =  MsgBox("The script has ended.", vbOKCancel , "Yo bro...")
	End If
End Sub

Sub DisableUIDs(strInfile)
	Dim strUID, objFile, objUser, objOutFile

	Set objFile = CreateObject("Scripting.FileSystemObject")
	'
	'Open Output file for saving results
	'
	Set objOutFile = objFile.OpenTextFile("results.log", ForWriting, True)
	objOutFile.writeline("Script start: " & Now())
	objOutFile.writeline(String(80, "-"))

	If objFile.FileExists(strInFile) = True Then
				
		Set objInFile = objFile.OpenTextFile(strInFile, ForReading, False)
		Do while objInFile.AtEndofStream <> True

			On Error Resume Next
		
			'
			' Connect to domain account
			'
			strUID = Trim(objInFile.ReadLine)
			strDN=QueryAD_User(strUID)
			Set objUser = GetObject("LDAP://" & strDN)					
			if err.number < 0 Then
				strResult = strUID & Chr(9) & "ERROR: This account does not exist."
			else	
				' retrieve the fullname of this account
				strFullname = objUser.Fullname
	
				If DebugScript = TRUE Then
					'
					' Ask confirmation before change if DEBUG mode is TRUE
					'
					intDoIt =  MsgBox("Do you wish to alter account " & strUID, _
                      				vbOKCancel + vbInformation, "Current account.")
                      			
	    				If intDoIt = vbCancel Then	
						' Do nothing. We are very good at that...
					else 
						objUser.AccountDisabled = TRUE
						objUser.SetInfo	
					End if
				Else
					'
					' Do not ask questions, just disable the account.
					'
					objUser.AccountDisabled = TRUE
					objUser.SetInfo
				end If
			
				'
				' Check results.
				'
				If objUser.AccountDisabled Then
					strResult = strUID & Chr(9) & strFullname & Chr(9) & "Account disabled."
				Else
					strResult = strUID & Chr(9) & strFullname & Chr(9) & "Untouched."
				End If
			
				'
				' remove object from memory
				'
				Set objUser = Nothing			
			end If
		
			'
			' Show result and save to logfile
			'
			WScript.echo strResult
			objOutFile.writeline(strResult)	
		loop
	Else
		strError = "ERROR: File " & strInFile & " was not found.!!"
		
		WScript.echo strError
		objOutFile.writeline(strError)
		intDoIt =  MsgBox(strError, vbOKCancel , "Yo bro...")
		
	End If

	objOutFile.writeline(String(80, "-"))
	objOutFile.writeline("Script end: " & Now())
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