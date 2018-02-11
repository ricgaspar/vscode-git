'------------------------------------------------------------------------#
'#
'#
'# AUTHOR: Marcel Jussen
'#
'------------------------------------------------------------------------#
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
Const ForReading = 1, ForWriting = 2, ForAppending = 8
Const TristateFalse = 0

Call main()
wscript.Quit
Sub Main
	'Get the command line arguments
	set oArgs=wscript.arguments
	if oArgs.Count >= 2 Then
		Call Convert(oArgs.Item(0),oArgs.Item(1))
	Else
		PrintMess("Error: Parameter errors. Usage txt2xml.vbs inputfile outputfile")
	End If
	Set oArgs=Nothing
End Sub

Sub Convert(strInFile, strOutFile)
	PrintMess("------------------------------------------------------------------------")
	PrintMess("Starting script " & wscript.ScriptFullName)
	PrintMess("Input file:" & strInFile)
	PrintMess("Output file:" & strOutFile)
	
	Set WshShell = WScript.CreateObject("WScript.Shell")
	Set objInputFSO = CreateObject("Scripting.FileSystemObject")
	Set objoutputFSO = CreateObject("Scripting.FileSystemObject")

	lcount=0
	' Insure that file does not already exist
	If objInputFSO.FileExists(strInfile) Then
		' Assign objects for file access
		Set objInfile = objInputFSO.OpenTextFile(strInFile, ForReading, True)
		Set objOutfile = objOutputFSO.OpenTextFile(strOutFile, ForWriting, True)

		strOutText = "<?xml version=" & chr(34) & "1.0" & chr(34) & " ?>"
		objOutFile.WriteLine strOutText
		strOutText = "<system>"
		objOutFile.WriteLine strOutText
		
		strSeparator="="		
		PrintMess("Separator: " & strSeparator)
		
		lcount=0				
		' Read inputfile until EOF
		do while objInFile.AtEndofStream <>True
			rline=Trim(objInFile.ReadLine)
			lcount = lcount + 1			
			
			nFound = InStr(rline, strSeparator)
			strKey = Trim(Mid(rline, 1, nFound-1))
			strVal = Trim(Mid(rline, nFound+1))

			strOutText = vbTab & "<" & strKey & ">" & strVal & "</" & strKey & ">"
			objOutFile.WriteLine strOutText
		Loop

		strOutText = "</system>"
		objOutFile.WriteLine strOutText

	Else
		PrintMess("Input file " & strInfile & " was not found!. Script ended in error.")
	End If
	PrintMess(CStr(lcount) & " lines processed.")
	PrintMess("------------------------------------------------------------------------")
	
	Set objInputFSO = nothing
	Set objOutputFSO = nothing
End Sub

Sub PrintMess(strMessage)
	wscript.echo strMessage
End Sub
