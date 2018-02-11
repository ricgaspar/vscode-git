Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20
Const cMaxTextWidth = 80

strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
For Each objItem In colItems     
	strCaption = Trim(objItem.Caption)
	strCSDVersion = Trim(objItem.CSDVersion)
	strVersion = Trim(objItem.Version)
	strOrganization = Trim(objItem.Organization)
	strRegisteredUser = Trim(objItem.RegisteredUser)
Next


Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_Environment where NAME='PROCESSOR_ARCHITECTURE'", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
For Each objItem In colItems
	strProcArch = objItem.VariableValue    
Next

Function WMIDateStringToDate(dtmDate)
WScript.Echo dtm: 
	WMIDateStringToDate = CDate(Mid(dtmDate, 5, 2) & "/" & _
	Mid(dtmDate, 7, 2) & "/" & Left(dtmDate, 4) _
	& " " & Mid (dtmDate, 9, 2) & ":" & Mid(dtmDate, 11, 2) & ":" & Mid(dtmDate,13, 2))
End Function

strReturn = strCaption
If Len(strProcArch)>0 Then strReturn = strReturn & " (" & strProcArch & ")"
If Len(strCSDVersion)>0 Then strReturn = strReturn & " " & strCSDVersion & " "

If Len(strOrganization) > 0 Then
	strOrg = strOrg & strOrganization
	If Len(strRegisteredUser) > 0 Then strOrg = strOrg & " - " & strRegisteredUser
	strReturn = AddStr(strReturn, strOrg)
End If 

On Error Resume Next
wscript.Echo strReturn	'for cmd line
Echo strReturn	'for BGInfo
on error goto 0

Function AddStr(strOrig, strAdd)
	strRet = ""
	strLine = strAdd
	
	' Check if line length does not exceed our max width
	If Len(strLine)>=cMaxTextWidth Then
		If InStr(strLine, ": ")>=0 Then
			counter = InStr(strLine, ": ") + 1
		Else
			counter = 0		
			strLead = Mid(strLine,counter+1,1)
			While strLead = Chr(32) 
				counter = counter + 1
				strLead = Mid(strLIne,counter+1,1)
			Wend
		End If
		strLead = Space(counter)
		strTemp = Mid(strLine,1, cMaxTextWidth) & vbCrLf
		strLine = Mid(strLine,cMaxTextWidth+1)
		While Len(strLine)>=cMaxTextWidth
			strTemp = strTemp & strLead & Mid(strLine,1, cMaxTextWidth) & vbCrLf
			strLine = Mid(strLine,cMaxTextWidth+1)
		Wend
		If Len(strLine)>0 Then strTemp = strTemp & strLead & strLine
		strLine = strTemp
	End If
	If Len(strOrig)<=0 Then
		strRet = strLine
	Else
		strRet = strOrig & vbCrLf & strLine
	End If
	AddStr = strRet
End Function