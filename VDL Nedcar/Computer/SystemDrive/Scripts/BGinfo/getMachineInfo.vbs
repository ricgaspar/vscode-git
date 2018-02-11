On Error Resume Next

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20
Const cMaxTextWidth = 80

strComputer = "."

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystemProduct", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)
For Each objItem In colItems
	strName = Trim(objItem.Name)
	strVendor = Trim(objItem.Vendor)
	strVersion = Trim(objItem.Version)
	strIdentifyingNumber = Trim(objItem.IdentifyingNumber)
Next

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)
For Each objItem In colItems
	strManufacturer = Trim(objItem.Manufacturer)
	strModel = Trim(objItem.Model)
Next

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_BIOS", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)

For Each objItem In colItems
	strSerialNumber = Trim(objItem.SerialNumber)
	strSMBIOSBIOSVersion = Trim(objItem.SMBIOSBIOSVersion)
	strSMBIOSMajorVersion = Trim(objItem.SMBIOSMajorVersion)
	strSMBIOSMinorVersion = Trim(objItem.SMBIOSMinorVersion)
	strBiosVersion = Trim(objItem.Version)
Next

If Len(strManufacturer)=0 Then strManufacturer=strVendor
If Len(strManufacturer)=0 Then strManufacturer="Unknown manufacturer"
If Len(strModel)=0 Then strModel = strName
If Len(strModel)=0 Then strModel = "Unkown model"
If Len(strSerialNumber) = 0 Then strSerialNumber = strIdentifyingNumber

' Show Manufacturer info
If Len(strModel) > 0 Then strManuInfo = strManuFacturer & " - " & strModel
If Len(strVersion) > 0 Then strManuInfo = strManuInfo & " version (" & strVersion & ")"
strReturn = AddStr(strReturn, strManuInfo)

' Show MB Serial
If Len(strSerialNumber)>0 Then strMBInfo = "Serial number: " &	strSerialNumber 
strReturn = AddStr(strReturn, strMBInfo)

' Show BIOS Version
If Len(strSMBIOSBIOSVersion)>0 Then strBiosInfo = "Bios " & strSMBIOSBIOSVersion
If Len(strSMBIOSMajorVersion)>0 Then strBiosInfo = strBiosInfo & " " & strSMBIOSMajorVersion
If Len(strSMBIOSMinorVersion)>0 Then strBiosInfo = strBiosInfo & "." & strSMBIOSMinorVersion
If Len(strBIOSVersion)>0 Then strBiosInfo = strBiosInfo & " " & strBIOSVersion
strReturn = AddStr(strReturn, strBiosInfo)

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