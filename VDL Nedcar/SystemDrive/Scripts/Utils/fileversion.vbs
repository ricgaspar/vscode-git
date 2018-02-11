'----------------------- FORCE CSCRIPT RUN -------------------------------
' Save passed arguments
Set objArgs = Wscript.Arguments
For I = 0 to objArgs.Count - 1
 args = args + " " + objArgs(I)
Next

' Check if Wscript was called
if right(ucase(wscript.FullName),11)="WSCRIPT.EXE" then
    Set y = WScript.CreateObject("WScript.Shell")
    y.Run "cscript.exe " & wscript.ScriptFullName + " " + args, 1
    wscript.quit
end if
'----------------------- FORCE CSCRIPT RUN -------------------------------

'Get the command line arguments
Set objArguments = WScript.arguments
If objArguments.Count < 2 Then
		wscript.quit(-1)
Else
		wscript.echo GetFileInfo(objArguments.Item(0), objArguments.Item(1))
End If

Function GetFileInfo(strFileName, strOption)
	Dim xObj, bResult, strResult
	Dim aKeys, i, strOut
	
	strOut=""
	aKeys = Array("CompanyName", "FileDescription", "FileVersion", "InternalName", "LegalCopyright", "OriginalFilename", "ProductName", "ProductVersion")	
  Set xObj = wscript.CreateObject("Softwing.VersionInfo")    
  bResult = xObj.GetByFilename(strFileName)
  If 1 <> bResult Then
  	strOut="-1"
	Else
			Select Case strOption
			Case "/FV"
				strOut=xObj.GetValue(aKeys(2))
			Case "/PV"
				strOut=xObj.GetValue(aKeys(7))
			Case "/MAJOR"
				strOut=xObj.MajorVersion
			Case "/MINOR"
				strOut=xObj.MinorVersion
			Case "/TEXT"				
				strOut = strOut & "File Name: " & strFileName & vbCrLf				
				For i = 0 To UBound(aKeys)
	  			strValue = strValue & aKeys(i) & ": " & xObj.GetValue(aKeys(i)) & vbCrLf
				Next
				strOut = strOut & strValue & vbCrLf
				strResult = "File Name: " & xObj.FileName & vbCrLf
				strResult = strResult & "Major Version: " & xObj.MajorVersion & vbCrLf
				strResult = strResult & "Minor Version: " & xObj.MinorVersion & vbCrLf
				strResult = strResult & "File Flags: " & xObj.FileFlags & vbCrLf
				strResult = strResult & "File OS: " & xObj.FileOS & vbCrLf
				strResult = strResult & "File Type: " & xObj.FileType & vbCrLf
				strOut = strOut & strResult
		End Select
	End If
  Set xObj = Nothing
	GetFileInfo = strOut
End Function

