
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

' *** NEW ***
arrDNSServers = Array("172.24.1.2", "172.24.1.1")
Const statPrimWINS 	= "172.24.1.2"
Const statSecWINS 	= "172.24.1.1"

Const OLD_PrimDNS 	= "172.18.0.123"
Const OLD_SecDNS		= "172.18.0.111"
Const OLD_PrimWINS  = "172.18.0.111"
Const OLD_SecWINS   = "172.18.0.201"

'*** OLD ***
'arrDNSServers = Array("172.18.0.123", "172.18.0.111")
'Const statPrimWINS = "172.18.0.111"
'Const statSecWINS  = "172.18.0.201"

'Const OLD_PrimDNS 	= "172.24.1.2"
'Const OLD_SecDNS		= "172.24.1.1"
'Const OLD_PrimWINS = "172.24.1.2"
'Const OLD_SecWINS  = "172.24.1.1"

'--------------------------------------------

Message "========================================================="
Message "Start setTCPIP script." 
Message "========================================================="
Message "Connecting to WMI. "
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Message "------------- Settings BEFORE operation ------------------"
GetSettings  

Set colNicConfigs = objWMIService.ExecQuery _
 ("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True") 
For Each objNicConfig In colNicConfigs  
  Message ""
  Message " ---- Changing IP Stack for adapter " & objNicConfig.Index & " --------------"
  Message "  " & objNicConfig.Description  	
  
  If Not objNicConfig.DHCPEnabled Then 	
  	
  	config = true
  	pos = InStr(UCase(objNicConfig.Description), "USB-USB")
  	If config And pos > 0 then config=False
  	Pos = InStr(UCase(objNicConfig.Description), "BLUETOOTH") 
  	If config And pos > 0 then config=False
  	Pos = InStr(UCase(objNicConfig.Description), "VMWARE") 
  	If config And pos > 0 then config=False
  		
  	If Not config Then
  			Message "  Adapter name not accepted. VMWare/USB/Bluetooth."
  	End if	
    
  	If config = True then  		
  			
  			If Not IsNull(objNicConfig.DNSServerSearchOrder) Then

					dnsCounter=0
					strDNS=""
    			For Each strDNSServer In objNicConfig.DNSServerSearchOrder
    				dnsCounter = dnsCounter+1
    				strDNS=strDNS & strDNSServer						  
    			Next
    			
    			dns1Ok = False
    			dns2OK = False
    			If dnsCounter=2 Then    				
						dns1OK = (InStr(strDNS, OLD_PrimDNS & OLD_SecDNS)>0)
						dns2OK = (InStr(strDNS, OLD_SecDNS & OLD_PrimDNS)>0)
					Else
						If dnsCounter=1 Then
							Message "  Adapter has only one DNS entry: " & strDNS
							dns1OK = (InStr(strDNS, OLD_PrimDNS)>0) or (InStr(strDNS, OLD_SecDNS)>0)
						Else
							Message "  ERROR: Adapter has a faulty number of DNS servers. Number: " &CStr(dnsCounter)
						End If
					End If
					
					If dns1Ok or dns2OK Then
						If dns1OK Then Message "  Old DNS IP addresses found."
						If dns2OK Then Message "  ERROR: Old DNS IP addresses in reversed order found."
    				Set objNicChanged = objWMIService.Get ("Win32_NetworkAdapterConfiguration.Index=" & objNicConfig.Index)
    				If Not Debug Then 
    				
    					intDNSServers = objNicChanged.SetDNSServerSearchOrder(arrDNSServers)
      				If intDNSServers = 0 Then
        				Message "    Assigned new DNS servers."
      				Else
        				Message "    ERROR: Unable to assign DNS servers."
      				End If
      				Err.Clear	      		
      			Else
      				Message "  ** DEBUG MODE ** DNS IS NOT CHANGED **"
      			End If
      		End If
      	Else
      		Message "  Adapter does not have DNS entries. DNS change skipped!"    			
  			End If
  			
    		blWinsPrim = (InStr(objNicConfig.WINSPrimaryServer, OLD_PrimWins)>0)
    		blWinsSec = (InStr(objNicConfig.WINSSecondaryServer, OLD_SecWins)>0)
    		Wins1ok = (blWinsPrim And blWinsSec)
    		Wins3ok = (blWinsPrim and (not blWinsSec))
    		Wins4Ok = ((not blWinsPrim) and blWinsSec)
    		
    		' Controleer ook of WINS PRIM en SEC verwisselt zijn!!    		
    		blWinsPrim = (InStr(objNicConfig.WINSPrimaryServer, OLD_SecWins)>0)
    		blWinsSec = (InStr(objNicConfig.WINSSecondaryServer, OLD_PrimWins)>0)
    		Wins2ok = (blWinsPrim And blWinsSec)
      
      	If Wins1OK or Wins2OK or Wins3Ok or Wins4OK Then
      		If Wins1OK Then Message "  Old WINS IP addresses found."
      		If Wins2OK Then Message "  Old WINS IP addresses in reversed order found."
      		If Wins3Ok Then Message "  ERROR: Primary WINS was OK. Secondary did not match."
      		If Wins4Ok Then Message "  ERROR: Primary WINS was wrong: Seconday WINS was found."
      		If Not DEBUG then
      			intWINSServers = objNicChanged.SetWINSServer(statPrimWINS, statSecWINS)
      			If intWINSServers = 0 Then
        			Message "    Assigned new WINS servers."
      			Else
        			Message "    ERROR: Unable to assign WINS servers."
      			End If
      			Err.Clear  		
      		Else
      			Message "  ** DEBUG MODE - WINS IS NOT CHANGED **"
      		End IF
      	Else
      			Message "  Adapter does not have default WINS entries. WINS change skipped!"
      	End if
       
  	Else
  		Message "  Adapter is skipped!"  		
  	End if
  		
  Else
  	Message "  ERROR: DHCP is enabled."
  	Message "  ERROR: Adapter is skipped!"
  End If
Next	

Message ""
Message "------------- Settings AFTER operation ------------------"
GetSettings
Message "========================================================="
Message "End setTCPIP script."
Message "========================================================="
 
wscript.quit()
 
 
'******************************************************************************
Sub GetSettings
 
	Set colNicConfigs = objWMIService.ExecQuery("SELECT * FROM " & _
 		"Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")
	
	For Each objNicConfig In colNicConfigs
	  Message ""
		Message "Network Adapter         : " & objNicConfig.Index
		Message "                          " & objNicConfig.Description
  	
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
  	
  		Message ""
  		Message "  DNS Search order." 
  		If Not IsNull(objNicConfig.DNSServerSearchOrder) Then
    		For Each strDNSServer In objNicConfig.DNSServerSearchOrder
    			Message "  DNS Server            : " & strDNSServer
    		Next
  		End If
	
			Message ""
			Message "  WINS Servers."
			Message "  WINS Primary Server   : " & objNicConfig.WINSPrimaryServer
    	Message "  WINS Secondary Server : " & objNicConfig.WINSSecondaryServer
    
 	Next
End Sub

Sub Message(strMessage)
	Wscript.echo Now() & ": " & strMessage
End Sub