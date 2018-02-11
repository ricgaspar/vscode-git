VARNAME = "SAPLOGON_INI_FILE"
On Error Resume Next
set oArgs = WScript.Arguments
set oWMIService = GetObject("winmgmts:\\" & oArgs(0) & "\root\cimv2")
If err.number <> 0 Then
	wscript.echo "WMI Error"
Else
	Set cItems = oWMIService.ExecQuery("Select * From Win32_Environment Where Name = '" & VARNAME & "'")
	If err.number <>0 Then
		Wscript.echo "ENV Error"
	Else		
		For Each oItem In cItems
  		strValue = oItem.VariableValue
		Next
		If Len(strValue)>0 Then Wscript.echo oArgs(0) & " " & strValue
	End If
End If



