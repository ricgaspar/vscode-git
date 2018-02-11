On Error Resume Next

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20
Const cMaxTextWidth = 50

Dim HideNic

arrComputers = Array(".")
For Each strComputer In arrComputers	
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
	Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True", "WQL", _
										wbemFlagReturnImmediately + wbemFlagForwardOnly)
	For Each objItem In colItems
		HideNic=False			
		If Not HideNic Then HideNic = InStr(objItem.Description, "Bluetooth") > 0
		If Not HideNic Then HideNic = InStr(objItem.Description, "USB") > 0
			
		If Not HideNic Then

			' NIC card nam
			strDesc = Replace(objItem.Description, " - ", vbCrLf)
			strReturn = AddStr(strReturn, strDesc)
			
			If Not IsNull(objItem.IPAddress) Then 
				strIPAddress = Join(objItem.IPAddress, ",")
				strIPSubnet = Trim(Join(objItem.IPSubnet, ","))
				If Len(strIPSubnet)>0 Then strIPAddress= strIPAddress & "/" & strIPSubnet
				strReturn = AddStr(strReturn, "  Address   : " & strIPAddress)
			End If
		
			'Default gateway
			If Not IsNull(objItem.DefaultIPGateway) Then 
				strDefaultIPGateway = Join(objItem.DefaultIPGateway, ",")			 	
				strReturn = AddStr(strReturn, "  Gateway   : " & strDefaultIPGateway)
			End If
		
			' DNS Host and domain
			If Not IsNull(objItem.DNSHostName) Then 
				strReturn = AddStr(strReturn, "  Hostname  : " & objItem.DNSHostName)
	 		End If
	 		If Not IsNull(objItem.DNSDomain) Then 
				strReturn = AddStr(strReturn, "  DNS domain: " & objItem.DNSDomain)
			End If
		
			' DNS search order
			If Not IsNull(objItem.DNSServerSearchOrder) Then 
				strDNSServerSearchOrder = Join(objItem.DNSServerSearchOrder, ", ")		
				strReturn = AddStr(strReturn, "  DNS order : " & strDNSServerSearchOrder)
			End If
		
			' WINS search order
	 		If Not IsNull(objItem.WINSPrimaryServer) Then 
	 			strWins = objItem.WINSPrimaryServer
				If Not IsNull(objItem.WINSSecondaryServer) Then strWins = strWins& ", "& objItem.WINSSecondaryServer
				strReturn = AddStr(strReturn, "  WINS order: " & strWins)
			End If
			strReturn = strReturn & vbCrLf
		End If
	Next
Next

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