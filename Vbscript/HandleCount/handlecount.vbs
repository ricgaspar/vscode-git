On Error Resume Next

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20

arrComputers = Array("S123","S134","S141","S145","S146","S147","S153","S164")
wscript.echo "PolDateTime,Systemname,Name,CreationDate,ExecutablePath,HandleCount"
For Each strComputer In arrComputers
   Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
   Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_Process where caption='prole.exe'", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)

   For Each objItem In colItems
   		Wscript.echo Chr(34) & CStr(Now()) & Chr(34) & "," & _
   			Chr(34) & strComputer & Chr(34) & "," & _
      	Chr(34) & objItem.Caption & Chr(34) & "," & _
      	FormDate(objItem.CreationDate) & "," & _
      	Chr(34) & objItem.ExecutablePath & Chr(34) & "," & _
      	objItem.HandleCount
   Next
Next

Function FormDate(dtmDate)
  FormDate = CDate(Mid(dtmDate, 5, 2) & "/" & _
			Mid(dtmDate, 7, 2) & "/" & Left(dtmDate, 4) & " " & _
		  Mid(dtmDate, 9, 2) & ":" & Mid(dtmDate, 11, 2) & ":" & Mid(dtmDate,13, 2))
End Function
	