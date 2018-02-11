
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

On Error Resume Next

'--------------------------------------------
Dim DEBUG

DEBUG = FALSE

'--------------------------------------------

Message "========================================================="
Message "Start setTCPIP script."
Message "Purpose: Disable DDNS registration for non-Clan adapters."
Message "========================================================="
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Message ""
Message "------------- Settings BEFORE operation ------------------"
GetSettings

Set colNicConfigs = objWMIService.ExecQuery ("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")
For Each objNicConfig In colNicConfigs
  Message ""
  Message " ---- Changing IP Stack for adapter " & objNicConfig.Index & " --------------"
  Message "  " & objNicConfig.Description

  ' Check for DHCP enabled adapters
  If Not objNicConfig.DHCPEnabled Then
  	config = true
  	' Check for invalid Adapter names
  	' IMPORTANT: This check is disabled.
  	' If config And InStr(UCase(objNicConfig.Description), "USB-USB") > 0 then config=False
  	' If config And InStr(UCase(objNicConfig.Description), "BLUETOOTH") > 0 then config=False
  	' If config And InStr(UCase(objNicConfig.Description), "VMWARE") > 0 then config=False
  	' If Not config Then Message "  Error: Adapter name contains invalid characters."

  	' All preliminary checks have taken place. If adapter is ok then change DDNS registration.
  	if config Then
  		' Purpose is to disable all DDNS registrations for adapters who are not in the 172.18.x.x. range
  		' Check if IP address is in CLAN range 172.18.x.x or 172.24.x.x
  		' If adapter holds more than one IP address this should be reported.
  		blCLANIp=true
  		If Not IsNull(objNicConfig.IPAddress) Then
  			nIPcount=0
    		For Each strIPAddress In objNicConfig.IPAddress
    			strIp = strIPAddress
    			nIPcount=nIPcount+1
    			If blCLANIp Then
    				blCLANIp = ((InStr(strIPAddress, "172.18.")>0) or (InStr(strIPAddress, "172.24.")>0))
    			End If
    		Next
    		If nIPCount>1 Then Message "  ERROR: Multiple IP addresses detected on single adapter!"
    	End If

    	' DDNS registration with a different DNS domain name is not used so value is copied and re-applied
    	' This means that the setting is NOT altered but just copied.
    	blDomainDNSRegistration = objNicConfig.DomainDNSRegistrationEnabled
  		' If this value is true than it's not according to NedCar CLAN standards. This should be reported.
    	If blDomainDNSRegistration Then Message "  ERROR: Specific domain DNS registration was found enabled!"

    	' Full DDNS registration is the parameter we are after.
    	If blCLANIp Then
    		Message "  INFO: IP address detected in C-LAN range: [" & strIP & "]"
    		'Enable DDNS registration
    		blFullDNSRegistration = True
    		message "  INFO: Enabling DDNS for C-LAN Adapter."
  		Else
  			Message "  INFO: IP address : [" & strIP & "]"
  			'Disable DDNS registration
    		blFullDNSRegistration = False
    		message "  INFO: Disabling DDNS."
  		End If

  		If objNicConfig.FullDNSRegistrationEnabled <> blFullDNSRegistration Then
  			message "  CHANGE: The parameter has to be changed!"
  		Else
  			message "  INFO: The parameter is already ok but will be re-applied."
  		End If

  		result = objNicConfig.SetDynamicDNSRegistration(blFullDNSRegistration, blDomainDNSRegistration)
			DNSRegShowResult(result)

		Else
  		Message "  INFO: Adapter is skipped!"
  	End If

  Else
  	Message "  INFO: DHCP is " & CStr(objNicConfig.DHCPEnabled)
  	Message "  INFO: Adapter is skipped."
	End If

Next

Message ""
Message "------------- Settings AFTER operation ------------------"
GetSettings
Message ""
Message "========================================================="
Message "End setTCPIP script."
Message "========================================================="

wscript.quit()

'******************************************************************************
Sub GetSettings

	Set colNicConfigs = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")

	For Each objNicConfig In colNicConfigs
	  Message ""
		Message "Network Adapter         : " & objNicConfig.Index & " " & objNicConfig.Description

		Message "  DHCP                  : " & objNicConfig.DHCPEnabled
  	If Not IsNull(objNicConfig.IPAddress) Then
   		For Each strIPAddress In objNicConfig.IPAddress
   			Message "  IP Address            : " & strIPAddress
   		Next
  	End If
  	If Not IsNull(objNicConfig.IPSubnet) Then
   		For Each strIPSubnet In objNicConfig.IPSubnet
     		Message "  Subnet Mask           : " & strIPSubnet
   		Next
  	End If

   	If Not IsNull(objNicConfig.DefaultIPGateway) Then
   		For Each strDefaultIPGateway In objNicConfig.DefaultIPGateway
   			Message "  Gateway               : " & strDefaultIPGateway
	 	  Next
	  End If

  	If Not IsNull(objNicConfig.GatewayCostMetric) Then
   		For Each strGatewayCostMetric In objNicConfig.GatewayCostMetric
   			Message "  CostMetrics           : " & strGatewayCostMetric
   		Next
  	End If

  	If Not IsNull(objNicConfig.DNSServerSearchOrder) Then
  		Message "  DNS Search order."
   		For Each strDNSServer In objNicConfig.DNSServerSearchOrder
   			Message "    DNS Server          : " & strDNSServer
   		Next
  	End If

		Message "  WINS Primary Server   : " & objNicConfig.WINSPrimaryServer
   	Message "  WINS Secondary Server : " & objNicConfig.WINSSecondaryServer

		If Not IsNull(objNicConfig.FullDNSRegistrationEnabled) Then
    	Message "  Full DDNS Registration: " & CStr(objNicConfig.FullDNSRegistrationEnabled)
    End If
    If Not IsNull(objNicConfig.DomainDNSRegistrationEnabled) Then
    	Message "  Specific DDNS registr.: " & CStr(objNicConfig.DomainDNSRegistrationEnabled)
    End If

 	Next
End Sub

Sub Message(strMessage)
	Wscript.echo Now() & ": " & strMessage
End Sub

Sub DNSRegShowResult(result)
	Select Case result
		Case 0 strMsg = "Successful completion, no reboot required."
		Case 1 strMsg = "Successful completion, reboot required."
		Case 64 strMsg = "Method not supported on this platform."
		Case 65 strMsg = "Unknown failure."
		Case 66 strMsg = "Invalid subnet mask."
		Case 67 strMsg = "An error occurred while processing an instance that was returned."
		Case 68 strMsg = "Invalid input parameter."
		Case 69 strMsg = "More than five gateways specified."
		Case 70 strMsg = "Invalid IP address."
		Case 71 strMsg = "Invalid gateway IP address."
		Case 72 strMsg = "An error occurred while accessing the registry for the requested information."
		Case 73 strMsg = "Invalid domain name."
		Case 74 strMsg = "Invalid host name."
		Case 75 strMsg = "No primary/secondary WINS server defined."
		Case 76 strMsg = "Invalid file."
		Case 77 strMsg = "Invalid system path."
		Case 78 strMsg = "File copy failed."
		Case 79 strMsg = "Invalid security parameter."
		Case 80 strMsg = "Unable to configure TCP/IP service."
		Case 81 strMsg = "Unable to configure DHCP service."
		Case 82 strMsg = "Unable to renew DHCP lease."
		Case 83 strMsg = "Unable to release DHCP lease."
		Case 84 strMsg = "IP not enabled on adapter."
		Case 85 strMsg = "IPX not enabled on adapter."
		Case 86 strMsg = "Frame/network number bounds error."
		Case 87 strMsg = "Invalid frame type."
		Case 88 strMsg = "Invalid network number."
		Case 89 strMsg = "Duplicate network number."
		Case 90 strMsg = "Parameter out of bounds."
		Case 91 strMsg = "Access denied."
		Case 92 strMsg = "Out of memory."
		Case 93 strMsg = "Already exists."
		Case 94 strMsg = "Path, file, or object not found."
		Case 95 strMsg = "Unable to notify service."
		Case 96 strMsg = "Unable to notify DNS service."
		Case 97 strMsg = "Interface not configurable."
		Case 98 strMsg = "Not all DHCP leases could be released/renewed."
		Case 100 strMsg = "DHCP not enabled on adapter."
		Case Else strMsg = "Unknown error!"
	End Select
	If result >=64 Then
		Message "  ERROR: [" & CStr(result) & "]: " & strMsg
	Else
		Message "  INFO: [" & CStr(result) & "]: " & strMsg
	End If

End Sub