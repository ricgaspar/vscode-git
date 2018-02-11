'#########################################################################
'#
'#
'# FUNCTION: Disable Users
'#
'# AUTHOR: Marcel Jussen
'#
'# COMMENT: This script uses ADSI and VBScript to access the Windows NT4
'# domain user information.
'#
'# Do not attempt to run this script with out ADSI and IE 5.0 (with
'# VBScript) installed. Users must be Administrators in the domain to be
'# successful. This script is for NT4/W2K/W2K3 only.
'#
'#########################################################################

' Assign Variables
Dim strUID
Dim strInFile, objFile, objInFile
Dim objArguments

'
' Constant definities
const ForReading = 1
const ForWriting = 2
const DebugScript = FALSE
const strDomain = "NEDCAR"

Call Main()
WScript.Quit

Sub Main()

	Wscript.echo "Disable Users from domain " & strDomain
	Wscript.echo ""
	'
	'Get the command line arguments
	set objArguments = WScript.arguments
	if objArguments.Count < 1 Then
		strInFile = InputBox("This script disables domain accounts in domain " & _ 
			strDomain & "." & CRLF & "What is the input file containing the user account information" & _ 
			CRLF & CRLF & "Press Cancel to quit.", 2)
	Else
		strInFile = objArguments.Item(0)
	End If
	
	If strInFile = "" Then
		WScript.Quit
	End If

	'
	' Ask confirmation before change if DEBUG mode is TRUE
	'
	intDoIt =  MsgBox("Do you wish to start disabling user accounts?", vbOKCancel + vbInformation, "Answer the f*cking question..")
	If intDoIt = vbCancel Then	
		' Do nothing. We are very good at that...
	Else 
		Call DisableUIDs(strInFile)
		intDoIt =  MsgBox("The script has ended.", vbOKCancel , "Yo bro...")
	End If
End Sub

Sub DisableUIDs(strInfile)

	Set objFile = CreateObject("Scripting.FileSystemObject")

	'
	'Open Output file for saving results
	'
	Set objOutFile = objFile.OpenTextFile("results.log", ForWriting, True)
	objOutFile.writeline("Script start: " & Now())
	objOutFile.writeline(String(80, "-"))

	'
	'Open Input file for reading share info
	'
	If objFile.FileExists(strInFile) = True then

		'
		'Open Input file for reading share info
		'
		Set objInFile = objFile.OpenTextFile(strInFile, ForReading, False)
		Do while objInFile.AtEndofStream <> True

			'
			' Enable error trap handler.
			'
			On Error Resume Next
		
			'
			' Connect to domain account
			'
			strUID = strDomain & "/" & Trim(objInFile.ReadLine)
		
			Set UserObj = GetObject("WinNT://" & strUID)
			'
			' Check if an error occurred while connecting to the account
			'		
			if err.number < 0 Then
				strResult = strUID & Chr(9) & "ERROR: This account does not exist."
			else	
				' retrieve the fullname of this account
				strFullname = Userobj.Fullname
	
				If DebugScript = TRUE Then
					'
					' Ask confirmation before change if DEBUG mode is TRUE
					'
					intDoIt =  MsgBox("Do you wish to alter account " & strUID, _
                      				vbOKCancel + vbInformation, "Current account.")
                      			
	    				If intDoIt = vbCancel Then	
						' Do nothing. We are very good at that...
					else 
						UserObj.AccountDisabled = TRUE
						UserObj.SetInfo	
					End if
				Else
					'
					' Do not ask questions, just disable the account.
					'
					UserObj.AccountDisabled = TRUE
					UserObj.SetInfo
				end If
			
				'
				' Check results.
				'
				If UserObj.AccountDisabled Then
					strResult = strUID & Chr(9) & strFullname & Chr(9) & "Account disabled."
				Else
					strResult = strUID & Chr(9) & strFullname & Chr(9) & "Untouched."
				End If
			
				'
				' remove object from memory
				'
				Set UserObj = Nothing			
			end If
		
			'
			' Show result
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