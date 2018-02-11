Const ForReading = 1
Const ForWriting = 2

Set objArgs = Wscript.Arguments
If objArgs.Count = 4 Then
	strInfile = objArgs(0)
	strOutFile = objArgs(1)
	strSearch = objArgs(2)
	strReplace = objArgs(3)
	
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFSO.OpenTextFile(strInfile, ForReading)

	strText = objFile.ReadAll
	objFile.Close
	strNewText = Replace(strText, strSearch, strReplace)

	Set objFile = objFSO.CreateTextFile(strOutFile, ForWriting)
	objFile.WriteLine strNewText
	objFile.Close
Else
	Wscript.echo "Foutje! Bedankt."
End If
	

