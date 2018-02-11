'========================================================================#
'#
'#
'# AUTHOR: Marcel Jussen
'#
'========================================================================#

'======================= FORCE CSCRIPT RUN ===============================
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
'======================= FORCE CSCRIPT RUN ===============================

Const blDEBUG	= FALSE

Const ForReading 	= 1
Const ForWriting 	= 2
Const ForAppending 	= 8
Const TristateFalse = 0

Const HKEY_CURRENT_USER = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002

Const LOGFILE = "Logboek\secdump-SysInfo-WMI.log"
Const UDL = "secdump.udl"

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20

' === SET GLOBAL VARIABLES ============
' Get the current User ID, Domain name and Computername
Dim gUSERNAME			' Username (ie. Q055817)
Dim gDOMAIN				' Domain (ie. NEDCAR)
Dim gCOMPUTERNAME	' Computername (ie. B187)

Dim strLogFileName
Dim objFSO, fsoLog

Call Main()

wscript.quit(0)

Function Main
	Call Set_Globals()			' Open log
	
	Dim strUDL, ODBC_conn, intError	
	strUDL = FindUDL(UDL)
	If Len(strUDL) > 0 Then
		On Error Resume next
		Set ODBC_conn = WScript.CreateObject("ADODB.connection")
		ODBC_conn.open "File Name=" & strUDL
		intError = err.number
		If intError<>0 Then
			PrintMess "Error while connecting to database."
			err.clear()
		Else
			Set recset = WScript.CreateObject("ADODB.RecordSet")
			strSQL = "exec QRY_SYSTEMS_NO_WMI"
			If blDEBUG Then PrintMess strSQL
			recset.open strSQL, ODBC_conn
			intError = err.number
			err.clear()
			On Error GoTo 0
			If intError<>0 Then
				PrintError "Execution of query resulted in an error!.", CStr(intError) & ": " & strSQL
			Else
				Do until recset.EOF
					strSystem = recset.Fields("systemname")
					Printmess "Checking WMI connection to " & strSystem
					
					On Error Resume Next
					Set objWMIService = GetObject("winmgmts:\\" & strSystem & "\root\CIMV2")
					If err.number=0 Then					
						Call Send_TimeInfo(strSystem)						' Time and time synchronization information
						Call Send_HPInfo(strSystem)							' HP Proliant information			
						Call Send_WUAUInfo(strSystem)						' Windows Update client information
						Call Send_ShareInfo(strSystem)					' List local shares and their size
						Call Send_Hardware(strSystem)						' Define Windows installation source
					Else
						PrintMess "WMI connection failed!"
					End If
					recset.MoveNext
				Loop
			End If
		End If
	End If	

	'---- Set computer configuration ------

	
	'Call Set_SystemDescription()		' Set computer description in local registry and Active Directory

	Call CloseUp()					' Close log
End Function

'=== Support functions ===========================================

Function Set_Globals
		
	gUSERNAME = Get_UserName
	gDOMAIN = Get_DomainName
	gCOMPUTERNAME = Get_SystemName

	strLogFilename=ExpandVar("%SysInfoLog%")
	If Len(strLogFilename)<=0 Then strLogFilename=Get_SystemDrive & "\" & LOGFILE
	Set objFSO = CreateObject("Scripting.FileSystemObject")	
	Set fsoLog=objFSO.OpenTextFile(strLogFilename, ForWriting, True)
End Function

Function CloseUp()
	' bye bye..	
	PrintMess String(40,"*")
	
	'Close logfile
	fsoLog.close()
End Function

Function ExpandVar(strVar)
  Dim strResult, WshShell, WshSysEnv, strEnvVar
  strResult=strVar
  If InStr(strResult, "%")=1 Then
    strResult = Mid(strResult,2)
    If InStr(strResult, "%") > 0 Then
      strEnvVar = Mid(strResult,1, InStr(strResult, "%")-1)
      Set WshShell = WScript.CreateObject("WScript.Shell")
      Set WshSysEnv = WshShell.Environment("PROCESS")
      strResult = WshSysEnv(strEnvVar) & Mid(strResult,InStr(strResult, "%")+1)
    End If
  End If
  ExpandVar = strResult
End Function

Sub PrintMess(strMessage)
  Dim strOutText, nDate, cTime
  nDate = Date()
  cTime = Time()
  strOutText = CStr(Year(nDate))
  strOutText = strOutText & String( 2-Len(CStr(Month(nDate))),"0" ) & CStr(Month(nDate))
  strOutText = strOutText & String( 2-Len(CStr(Day(nDate))),"0" ) & CStr(Day(nDate))
  strOutText = strOutText & "-"
  strOutText = strOutText & String( 2-Len(CStr(Hour(cTime))),"0" ) & CStr(Hour(cTime))
  strOutText = strOutText & String( 2-Len(CStr(Minute(cTime))),"0" ) & CStr(Minute(cTime))
  strOutText = strOutText & String( 2-Len(CStr(Second(cTime))),"0" ) & CStr(Second(cTime))
  strOutText = strOutText & ": " & strMessage
  wscript.echo strOutText
  fsoLog.writeline strOutText
End Sub

Sub PrintError(strErrorString, strText)
  PrintMess "** ERROR: " & strErrorString
  PrintMess "**        " & strText
End Sub

Function FindUDL(strUDL)
	Dim strResult, WshShell, strPath, intPos
	Dim strFolder, FSO, strTemp

	Set FSO = CreateObject ("Scripting.FileSystemObject")
	strResult = ""
	set WshShell = WScript.CreateObject("WScript.Shell")
	strPath = WshShell.ExpandEnvironmentStrings("%Path%")
	intPos = InStr(strPath, ";")
	Do While intpos > 0 And Len(strResult)=0
		strFolder = Mid(strPath,1,intPos-1)
		If Right(strFolder,1) = "\" Then strFolder=Left(strFolder, Len(strFolder)-1)
		strTemp = strFolder & "\" & strUDL		
		if FSO.FileExists(strTemp) Then strResult = strTemp
		strPath = Mid(strPath,intPos+1)		
		intPos = InStr(strPath, ";")
		if intPos=0 then
			strTemp = strPath & "\" & strUDL
			if FSO.FileExists(strTemp) Then strResult = strTemp
		End If
	Loop
	If blDEBUG Then PrintMess strResult
	FindUDL = strResult
End Function

Function Exec_SQL_Query(strSQL)
	Dim strUDL, ODBC_conn, intError
	'Save gathered information to SQL database
	strUDL = FindUDL(UDL)
	If Len(strUDL) > 0 Then
		On Error Resume next
		Set ODBC_conn = WScript.CreateObject("ADODB.connection")
		ODBC_conn.open "File Name=" & strUDL
		intError = err.number
		If intError<>0 Then
			PrintMess "Error while connecting to database."
			err.clear()
		Else
			Set recset = WScript.CreateObject("ADODB.RecordSet")
			If blDEBUG Then PrintMess strSQL
			recset.open strSQL, ODBC_conn
			intError = err.number
			err.clear()
			On Error GoTo 0
			If intError<>0 Then
				PrintError "Execution of query resulted in an error!.", CStr(intError) & ": " & strSQL
			End If
		End If
	End If
End Function

Function Get_IE_Version
	'Determine Internet Explorer version
	Set objSh=wscript.createobject("Wscript.Shell")
	Get_IE_Version=objSh.RegRead("HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer\version")
End Function

Function Get_OS_Version
	Dim objWMIService, osVer
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
	Set osVer = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
  For Each objItem in osVer
    strVersion=Mid(objItem.version,1,3)
  Next
  Get_OS_Version = strVersion
End Function

Function Get_SystemName
	Dim objWMIService, colComputer
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
  Set colComputer = objWMIService.ExecQuery("Select * from Win32_ComputerSystem")
  For Each objComputer in colComputer
    glbSYSTEMNAME = objComputer.Caption
  Next
  Get_SystemName = glbSYSTEMNAME
End Function

Function Get_UserName
	Set WSHNetwork = WScript.CreateObject("WScript.Network")
	Get_UserName = WSHNetwork.UserName	
End Function

Function Get_DomainName
	Set WSHNetwork = WScript.CreateObject("WScript.Network")
	Get_DomainName = WshNetwork.UserDomain
End Function

Function Get_SystemDrive
	Set objSh=wscript.createobject("Wscript.Shell")
	Get_SystemDrive = objSh.ExpandEnvironmentStrings("%SYSTEMDRIVE%")
End Function

Function Get_SystemRoot
	Set objSh=wscript.createobject("Wscript.Shell")
	Get_SystemRoot = objSh.ExpandEnvironmentStrings("%SYSTEMROOT%")
End Function

Function ad_Get_SysInfo
	On Error Resume Next
	Set objSysInfo = CreateObject("ADSystemInfo")
	ad_Get_SysInfo = "LDAP://" & UCase(objSysInfo.ComputerName)
	On Error GoTo 0
End Function

Function ad_Get_Description(strAd)
	Dim strDesc
	On Error Resume Next
	Set objComputer = GetObject(strAd)
	If err.number=0 Then
		strDesc = objComputer.Get("Description")
	End If
	On Error GoTo 0
	ad_Get_Description = strDesc
End Function

Function ad_Set_Description(strAd, strDesc)
	On Error Resume Next
	Set objComputer = GetObject(strAd)
	If err.number=0 Then
		objComputer.Put "Description" , strDesc
		objComputer.SetInfo
		If err.number=0 Then PrintMess "AD description set to: " & strDesc
	End If
	On Error GoTo 0
End Function

Function wmi_Get_Description
	Dim strDesc
	Const wbemFlagReturnImmediately = &h10
	Const wbemFlagForwardOnly = &h20

	On Error Resume Next
	Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
	Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
	If err.number=0 Then
		For Each objItem In colItems
			strDesc = objItem.Description
		Next
	End If
	On Error GoTo 0
	wmi_Get_Description = strDesc
End Function

Function wmi_Set_Description(strDesc)
	Const HKEY_LOCAL_MACHINE = &H80000002
	strComputer = "."
	Set objRegistry = GetObject("winmgmts:\\.\root\default:StdRegProv")
	strKeyPath = "System\CurrentControlSet\Services\lanmanserver\parameters"
	strValueName = "srvcomment"
	objRegistry.SetStringValue HKEY_LOCAL_MACHINE, strKeyPath, strValueName, strDesc
	If err.number=0 Then PrintMess "WMI description set to: " & strDesc
End Function

Function WMIDateStringToDate(dtmDate)
WScript.Echo dtm:
	WMIDateStringToDate = CDate(Mid(dtmDate, 5, 2) & "/" & _
	Mid(dtmDate, 7, 2) & "/" & Left(dtmDate, 4) _
	& " " & Mid (dtmDate, 9, 2) & ":" & Mid(dtmDate, 11, 2) & ":" & Mid(dtmDate,13, 2))
End Function

'=== End Support functions ====================================

'=== Main functions ===========================================

Function Set_SystemDescription
	Dim strAd, strAdDesc, strWmiDesc

	PrintMess String(40,"*")
	PrintMess "Setting description process on system " & gCOMPUTERNAME & " has started."
	
	strAd = ad_Get_SysInfo
	If Not IsNull(strAd) Then
		strAdDesc = ad_Get_Description(strAd)
		strWmiDesc = wmi_Get_Description

		PrintMess "Active directory description for this computer: " & strAdDesc
		PrintMess "Local WMI/Lanman description for this computer: " & strWmiDesc

		'WMI string is leading
		If Len(strWmiDesc)>0 Then
			If Len(strAdDesc)<=0 Then
				'WMI string	filled, AD string empty, set AD=WMI
				Call ad_Set_Description(strAd, strWmiDesc)
			Else
			  'WMI string filled, AD string filled, overwrite AD=WMI
		  	If StrComp(strWmiDesc, strAdDesc)=0 Then
		  		PrintMess"Active Directory and local WMI descriptions are equal. No changes made."
			  Else
			  	Call ad_Set_Description(strAd, strWmiDesc)
			  End If
			End If
		Else
			If Len(strAdDesc)<=0 Then
				'WMI string	not filled, AD string empty, set both to new
				strDesc = "Vrij"
				Call ad_Set_Description(strAd, strDesc)
				Call wmi_Set_Description(strDesc)
			Else
		  	'WMI string notfilled, AD string filled, overwrite WMI=AD
				Call wmi_Set_Description(strAdDesc)
			End If
		End If
	End If
End Function

'==============================================================

Function Send_WindowsInstaller
	
	PrintMess String(40,"*")
	PrintMess "Gathering WinInstaller info on system " & gCOMPUTERNAME & " has started."

	' Delete previous Records from this machine
	strSQL = "delete from softwareproducts where systemname like '" & gCOMPUTERNAME & "'"
	Call Exec_SQL_query(strSQL)
	
	Call Send_WI_Specific("IBM", "IBM Tivoli Storage Manager Client")

End Function

Function Send_WI_Specific(strVendorSearch, strNameSearch)

	PrintMess "Vendor: " & strVendorSearch
	PrintMess "Name  : " & strNameSearch

	Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
  Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_Product", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
                                          
  For Each objItem In colItems
  	' Check installs from IBM
  	If InStr(Trim(objitem.Vendor), strVendorSearch)=1 Then
  		If InStr(Trim(objitem.Name), strNameSearch)=1 Then
  			strCaption = Trim(objItem.Caption)
  			strDescription = Trim(objItem.Description)
  			strInstallDate = Trim(objItem.InstallDate)
  			strInstallLocation = Trim(objItem.InstallLocation)
  			strInstallState = Trim(objItem.InstallState)
  			strName = Trim(objItem.Name)
  			strVendor = Trim(objItem.Vendor)
  			strVersion = Trim(objItem.Version)
  		End If
  		
  		' Add record to DB
			strSQL = "insert into softwareproducts"& _
				"(systemname, domainname, poldatetime," & _
				"caption, description, installdate, installlocation, installstate, name, vendor, version)" & _
				" VALUES (" & _
				"'" & gCOMPUTERNAME & "'," & _
				"'" & gDOMAIN & "'," & _
				"GetDate()," & _
				"'" & strCaption & "'," & _
				"'" & strDescription & "'," & _
				"'" & strInstallDate & "'," & _
				"'" & strInstallLocation & "'," & _
				"'" & strInstallState & "'," & _
				"'" & strName & "'," & _
				"'" & strVendor & "'," & _
				"'" & strVersion & "'" & _
				")"
			PrintMess strCaption & " : " & strVersion
			Call Exec_SQL_query(strSQL)  		
  	End If  	
   Next

End Function

Function chkString(strString)
	If Len(strString)>0 Then strString = Trim(Replace(strString, "'", Chr(32)))
	chkString = strString
End Function

'==============================================================

Function Send_WUAUInfo(strSystemname)
	Dim strUDL, intError
	Dim strWUAUname, strWUAUstarted, strWUAUstartmode
	Dim strWUAUstartname, strWUAUstate, strWUAUstatus

	PrintMess String(40,"*")
	PrintMess "Gathering WUAU Info on system " & strSystemname& " has started."
	On Error Resume Next
	err.clear()
	' Check status of local WUAU service
	Set objWMIService = GetObject("winmgmts:\\" & strSystemname & "\root\cimv2")
	intError = err.number
	If intError<>0 Then
		PrintMess "Error while connecting to WMI"
		err.clear()
	Else
		err.clear()
		Set colItems = objWMIService.ExecQuery("Select * from Win32_Service where Caption=" & Chr(39) & "Automatic Updates" & Chr(39),,48)
		intError = err.number
		If intError<>0 Then
			PrintMess "Error while performing a query on WMI."
			err.clear()
		Else
			For Each objItem in colItems
				strWUAUname = objItem.Name
				strWUAUstarted = objItem.Started
				strWUAUstartmode = objItem.StartMode
    		strWUAUstartname = objItem.StartName
    		strWUAUstate = objItem.State
	    	strWUAUstatus = objItem.Status
    	Next
    End If
  End If
	On Error GoTo 0

	On Error Resume Next
  Set Sh = CreateObject("WScript.Shell")
	key = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
	'strWUAUserver = Sh.RegRead(key & "WUServer")
	'strWUAUstatusserver = Sh.RegRead(key & "WUStatusServer")
	'strTargetGroup = Sh.RegRead(key & "TargetGroup")

	key =  "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Update\"
	'strPolicy = Sh.RegRead(key & "NetworkPath")

	key = "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\"
	'strWUAUoptions = Sh.RegRead(key & "AUOptions")
	'strWUAUreboot = Sh.RegRead(key & "NoAutoRebootWithLoggedOnUsers")

	key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\"
	'strWUAUoptions2 = Sh.RegRead(key & "AUOptions")
	'strWUAUstate2 = Sh.RegRead(key & "AUState")

	if len(Trim(strWUAUstate2))=0 then
		'strWUAUState2="999"
	End if

	' Correct value if returned string is not numerical!
	On error resume next
	err.clear()
	tmpVal = CInt(strWUAUState2)
	tmpStr = Trim(CStr(tmpVal))
	If InStr(tmpStr, trWUAUState2)<>1 then
		' Presume status is disabled.
		'strWUAUState2="999"
	end If
	err.clear()
	'strWUAUschedule = Sh.RegRead(key & "ScheduledInstallDate")
	On Error GoTo 0

	'Display gathered information and log.
	If intError=0 Then
		PrintMess "WUAU service name      : " & strWUAUname
		PrintMess "WUAU service started   : " & strWUAUstarted
		PrintMess "WUAU service start mode: " & strWUAUstartmode
		PrintMess "WUAU service start name: " & strWUAUstartname
		PrintMess "WUAU service state     : " & strWUAUstate
		PrintMess "WUAU service status    : " & strWUAUstatus
		PrintMess "WUAU update server     : " & strWUAUserver
		PrintMess "WUAU status server     : " & strWUAUstatusserver
		PrintMess "WUAU target group      : " & strTargetGroup
		PrintMess "WUAU policy            : " & strPolicy
		PrintMess "WUAU AU options        : " & strWUAUoptions
		PrintMess "WUAU AU reboot         : " & strWUAUreboot
		PrintMess "WUAU AU options 2      : " & strWUAUoptions2
		PrintMess "WUAU AU state          : " & strWUAUstate2
		PrintMess "WUAU AU schedule       : " & strWUAUschedule
	Else
		PrintError "WUAU info gathering process ended in error ", CStr(intError)
	End If

	'Save gathered information to SQL database
	On Error GoTo 0
	
	' Delete previous Records from this machine
	strSQL = "delete from updateservice where servername like '" & gCOMPUTERNAME & "'"
	Call Exec_SQL_Query(strSQL)

	' Add record to DB
	strSQL = "insert into updateservice "& _
				"(servername, domainname, poldatetime, policy, servicename, started, startmode," & _
				" startname, state, status, updateserver, statusserver," & _
				" auoptions, aureboot, auoptions2, austate, auschedule, targetgroup)" & _
				" VALUES (" & _
				"'" & strSystemname & "'," & _
				"'" & gDOMAIN & "'," & _
				"GetDate()," & _
				"'" & strPolicy & "'," & _
				"'" & strWUAUname & "'," & _
				"'" & strWUAUstarted & "'," & _
				"'" & strWUAUstartmode & "'," & _
				"'" & strWUAUstartname & "'," & _
				"'" & strWUAUstate & "'," & _
				"'" & strWUAUstatus & "'," & _
				"'" & strWUAUserver & "'," & _
				"'" & strWUAUstatusserver & "'," & _
				"'" & strWUAUoptions & "'," & _
				"'" & strWUAUreboot & "'," & _
				"'" & strWUAUoptions2 & "'," & _
				"'" & strWUAUstate2 & "'," & _
				"'" & strWUAUschedule & "'," & _
				"'" & strTargetGroup & "')"
	Call Exec_SQL_Query(strSQL)

End Function

'==============================================================

Sub Send_TimeInfo(strSystemname)
	PrintMess String(40,"*")
	PrintMess "Gathering time information on system " & strSystemname & " has started."
	
	strSQL = "delete from timeinfo where systemname='" & strSystemname & "'"
  Call Exec_SQL_Query(strSQL)
	
	On Error Resume Next
	Set objWMIService = GetObject("winmgmts:\\" & strSystemname & "\root\CIMV2")
	If err.number = 0 Then 
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
   	For Each objItem In colItems
			strLocalTime = objItem.LocalDateTime
  	  strDay = Mid(strLocalTime, 7, 2)
    	strMonth = Mid(strLocalTime, 5, 2)
	    strYear = Left(strLocalTime, 4)
  	  strHour = Mid(strLocalTime, 9, 2)
    	strMinute = Mid(strLocalTime, 11, 2)
    	strSecond = Mid(strLocalTime, 13, 2)
  	Next

		PrintMess strLocalTime

		Set objWMIService = GetObject("winmgmts:\\" & strSystemname & "\root\CIMV2")
  	Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_TimeZone", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)  	
  	
  	For Each objItem In colItems
			strBias = objItem.Bias
			strCaption = Chr(39) & objItem.Caption & Chr(39)
			strDaylightBias = objItem.DaylightBias
			strDaylightDay = objItem.DaylightDay
			strDaylightDayOfWeek = objItem.DaylightDayOfWeek
			strDaylightHour = objItem.DaylightHour
			strDaylightMillisecond = objItem.DaylightMillisecond
			strDaylightMinute = objItem.DaylightMinute
			strDaylightMonth = objItem.DaylightMonth
			strDaylightName = Chr(39) & objItem.DaylightName & Chr(39)
			strDaylightSecond = objItem.DaylightSecond
			strDaylightYear = objItem.DaylightYear
			strDescription = Chr(39) & objItem.Description & Chr(39)
			strSettingID = "0"
			strStandardBias = objItem.StandardBias
			strStandardDay = objItem.StandardDay
			strStandardDayOfWeek = objItem.StandardDayOfWeek
			strStandardHour = objItem.StandardHour
			strStandardMillisecond = objItem.StandardMillisecond
			strStandardMinute = objItem.StandardMinute
			strStandardMonth = objItem.StandardMonth
			strStandardName = Chr(39) & objItem.StandardName & Chr(39)
			strStandardSecond = objItem.StandardSecond
			strStandardYear = objItem.StandardYear
   	Next

   	strRecord =  strDay & "," & _
   		strHour & "," & _
   		strMinute & "," & _
   		strMonth & "," & _
   		strSecond & "," & _
   		strYear & "," & _
   		strBias & "," & _
   		strCaption & "," & _
   		strDaylightBias & "," & _
   		strDaylightDay & "," & _
   		strDaylightDayOfWeek & "," & _
   		strDaylightHour & "," & _
   		strDaylightMillisecond & "," & _
   		strDaylightMinute & "," & _
   		strDaylightMonth & "," & _
   		strDaylightName & "," & _
   		strDaylightSecond & "," & _
   		strDaylightYear & "," & _
   		strDescription & "," & _
   		strSettingID & "," & _
   		strStandardBias & "," & _
   		strStandardDay & "," & _
   		strStandardDayOfWeek & "," & _
   		strStandardHour & "," & _
   		strStandardMillisecond & "," & _
   		strStandardMinute & "," & _
   		strStandardMonth & "," & _
   		strStandardName & "," & _
   		strStandardSecond & "," & _
   		strStandardYear

		strTimeChk = "'" & strSystemname & "',GetDate()," & strRecord
   	strTimeChk = Replace(strTimeChk,",,",",0,")   	
  
  	' Add record to DB  	

  	strSQL = "insert into timeinfo "& _
      "(systemname, poldatetime, " & _
      "sysDay, sysHour, sysMinute, sysMonth, sysSecond, sysYear, " & _
      "Bias, Caption, DaylightBias, DaylightDay, DaylightDayOfWeek, DaylightHour, DaylightMillisecond, DaylightMinute, " & _
      "DaylightMonth, DaylightName, DaylightSecond, DaylightYear, Description, SettingID, StandardBias, StandardDay, StandardDayOfWeek, " & _
      "StandardHour, StandardMillisecond, StandardMinute, StandardMonth, StandardName, StandardSecond, StandardYear" & _
      ") VALUES (" & _
      strTimeChk &_
      ")"
  	Call Exec_SQL_Query(strSQL)
  End If
End Sub

Function TimeChk(strSystemname)
  

  
End Function

'==============================================================

Function Send_Hardware(strSystemname)
	strComputer=strSystemname
	PrintMess String(40,"*")
	PrintMess "Gathering hardware info on system " & strSystemname & " has started."
	
	strSQL = "delete from osinfo where systemname='" & strSystemname & "'"
  Call Exec_SQL_Query(strSQL)
	
	On Error Resume Next
	Set objWMIService = GetObject("winmgmts:\\" & strSystemname & "\root\CIMV2")
	If err.number=0 Then
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)

		For each objItem in colItems
			strVersion = objItem.Version
			strOSProdSuite = objItem.OSProductSuite
			strOSType = objItem.OSType
			strSPMaj = objItem.ServicePackMajorVersion
			strSPMin = objItem.ServicePackMinorVersion
			PrintMess "OSProductSuite         : " & strOSProdSuite
	  	PrintMess "OSType                 : " & strOSType
		

			If InStr(strVersion, "5.0")=1 Then
				PrintMess "Version                : Windows 2000"
				If CheckEnterpriseEdition(CInt(strOSProdSuite))	Then
					PrintMess "Advanced server      : True"
					strOS="w50as"
					strOSEdition = "Windows 2000 Advanced"
				Else
					strOs="w50s"
					strOSEdition = "Windows 2000 Standard"
			End If
			End If
  		If InStr(strVersion, "5.2")=1 Then
  			PrintMess "Version                : Windows 2003 Server"
  			If CheckEnterpriseEdition(CInt(strOSProdSuite))	Then
  				PrintMess "Enterprise edition   : True"
	  			strOS="w52e"
	  			strOSEdition = "Windows 2003 Enterprise"
  			Else
  				strOS="w52s"
  				strOSEdition = "Windows 2003 Standard"
	  		End If
  		End If
  		PrintMess "OS Edition             : " & strOSEdition
  	
  		PrintMess "ServicePackMajorVersion: " & strSPMaj
	  	PrintMess "ServicePackMinorVersion: " & strSPMin
		Next

		Set colItems = objWMIService.ExecQuery("Select * from Win32_Processor",,48)
		For each objItem in colItems
			strArch = Trim(objItem.Architecture)
			strCPUSpeed = Trim(objItem.CurrentClockSpeed)
			strCPUManufacturer = Trim(objItem.Manufacturer)
			strCPUName = Trim(objItem.Name)
		Next
	
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_BIOS", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)
		For each objItem in colItems
			strSerialNumber = Trim(objItem.SerialNumber)		
		Next
		PrintMess "System serial number   : " & strSerialNumber
		
		If CheckArchitectureX64(CInt(strArch)) Then
			' Adapt path to conform to Altiris folder structure
			strOS = strOS & ".64"		
			strArch = "x64"
		Else		
			strArch = "x86"
		End If
		PrintMess "Architecture           : " & strArch
	
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)		
		For each objItem in colItems
			strModel = Trim(objitem.Model)
			strMemory = Trim(objItem.TotalPhysicalMemory)
		Next	  

		strSourcePath = "\\S100\osdist$\" & strOS 
		PrintMess "Setting sourcepath on system " & strSystemname
		PrintMess "SourcePath             : " & strSourcePath
		Const HKEY_LOCAL_MACHINE = &H80000002
		' Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strSystemname & "\root\default:StdRegProv")

		strKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Setup"
		strValueName = "SourcePath"
		' oReg.SetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strSourcePath
	
		strSQL = "insert into osinfo "& _
      "(systemname, domainname, poldatetime, " & _
      "serialnumber, systemmodel, memorysize, version, osprodsuite, ostype, osedition, spmaj, spmin, architecture, " & _ 
      "cpumanufacturer, cpuname, cpuspeed, sourcepath" & _
      ") VALUES (" & _
      "'" & strSystemname & "','" & gDOMAIN & "',GetDate()," & _
      "'" & strSerialNumber & "','" & strModel & "'," & strMemory & "," & _
      "'" & strVersion & "','" & strOSProdSuite & "','" & strOSType & "','" & strOSEdition & "','" & strSPMaj & "','" & strSPMin& "'," & _
      "'" & strArch& "','" & strCPUManufacturer & "','" & strCPUName & "','" & strCPUSpeed & "','" & strSourcePath & "'" &_
      ")"
  	Call Exec_SQL_Query(strSQL)
  End If

End Function

Function CheckEnterpriseEdition(nOSProdSuite)
	CheckEnterpriseEdition = ((nOSProdSuite And 2) = 2)
End Function

Function CheckArchitectureX64(nArchitecture)
	CheckArchitectureX64 = ((nArchitecture And 9) = 9)
End Function

'==============================================================

Function Send_HPInfo(strSystemname)
	Dim strUDL, intError

	On Error Resume Next
	err.clear()
	PrintMess String(40,"*")
	
	strName = ""
	strVendor = ""
	strVersion = ""
	strIdentifyingNumber = ""
	strManufacturer = ""
	strModel = ""
	strSerialNumber = ""
	strSMBIOSBIOSVersion = ""
	strSMBIOSMajorVersion = ""
	strSMBIOSMinorVersion = ""
	strBiosVersion = ""

	PrintMess "Process gathering HP Info on system " & strSystemname & " has started."
	strComputer = strSystemname
	
	strsql = "delete from SystemInfo where servername like '" & strSystemname & "%'"
	Call Exec_SQL_Query(strSQL)
	
	On Error Resume Next 
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
	If err.number = 0 Then
	
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystemProduct", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
		For Each objItem In colItems
			strName = Trim(objItem.Name)
			strVendor = Trim(objItem.Vendor)
			strVersion = Trim(objItem.Version)
			strIdentifyingNumber = Trim(objItem.IdentifyingNumber)
		Next

		
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
		For Each objItem In colItems
			strManufacturer = Trim(objItem.Manufacturer)
			strModel = Trim(objItem.Model)
		Next
	
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_BIOS", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)

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

		If Len(strSMBIOSBIOSVersion)>0 Then strReturn = strReturn & "Bios " & strSMBIOSBIOSVersion
		If Len(strSMBIOSMajorVersion)>0 Then strReturn = strReturn & " " & strSMBIOSMajorVersion
		If Len(strSMBIOSMinorVersion)>0 Then strReturn = strReturn & "." & strSMBIOSMinorVersion
		If Len(strBIOSVersion)>0 Then strReturn = strReturn & " " & strBIOSVersion

		PrintMess "Manufacturer name      : " & strManufacturer
		PrintMess "Model name             : " & strModel
		PrintMess "Serial                 : " & strSerialNumber
		PrintMess "SMBios version         : " & strSMBIOSBIOSVersion
		PrintMess "SMBios major version   : " & strSMBIOSMajorVersion
		PrintMess "SMBios minor version   : " & strSMBIOSMinorVersion
		PrintMess "Bios version           : " & strBIOSVersion

		Set Sh = CreateObject("WScript.Shell")
		key = "HKEY_LOCAL_MACHINE\SOFTWARE\Compaq\CPQInstall\Version"
		'strHPMgmtVersion = Sh.RegRead(key)

		key = "HKEY_LOCAL_MACHINE\SOFTWARE\Compaq\CPQInstall\Compaq Foundation Agents\Version"
		'strHPCFAVersion = Sh.RegRead(key)

		key = "HKEY_LOCAL_MACHINE\SOFTWARE\Compaq\CPQInstall\Compaq NIC Agents\Version"
		'strHPCNAVersion = Sh.RegRead(key)

		key = "HKEY_LOCAL_MACHINE\SOFTWARE\Compaq\CPQInstall\Compaq Server Agents\Version"
		'strHPCSAVersion = Sh.RegRead(key)

		key = "HKEY_LOCAL_MACHINE\SOFTWARE\Compaq\CPQInstall\Compaq Storage Agents\Version"
		'strHPCSA2Version = Sh.RegRead(key)

		key = "HKEY_LOCAL_MACHINE\SOFTWARE\Compaq\CPQInstall\Compaq Web Agent\Version"
		'strHPWBAVersion = Sh.RegRead(key)

		PrintMess "HP/CPQ PSP version     : " & strHPMgmtVersion
		PrintMess "Foundation agents      : " & strHPCFAVersion
		PrintMess "NIC agents             : " & strHPCNAVersion
		PrintMess "Server agents          : " & strHPCSAVersion
		PrintMess "Storage agents         : " & strHPCSA2Version
		PrintMess "Web agents             : " & strHPWBAVersion

	
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
		For Each objItem In colItems
			strCaption = Trim(objItem.Caption)
			strCSDVersion = Trim(objItem.CSDVersion)
			strOSVersion = Trim(objItem.Version)
			strOrganization = Trim(objItem.Organization)
			strRegisteredUser = Trim(objItem.RegisteredUser)
		Next

		PrintMess "Caption                : " & strCaption
		PrintMess "CSD Version            : " & strCSDVersion
		PrintMess "Version                : " & strOSVersion
		PrintMess "Organization           : " & strOrganization
		PrintMess "Registered user        : " & strRegisteredUser

		

		' Add record to DB
		strsql = "insert into SystemInfo "& _
				"(servername, domainname, poldatetime, manufacturer, model, serial, biosbiosversion," & _
				" biosmajor, biosminor, biosversion," & _
				" HPMgmtVer, HPFoundation, HPNICAgent, HPCSA, HPStorAgent, HPWebAgent," & _
				" caption, csdversion, osversion, organization, registereduser)" & _
				" VALUES (" & _
				"'" & strComputer & "'," & _
				"'" & gDOMAIN & "'," & _
				"GetDate()," & _
				"'" & strManufacturer & "'," & _
				"'" & strModel & "'," & _
				"'" & strSerialNumber & "'," & _
				"'" & strSMBIOSBIOSVersion & "'," & _
				"'" & strSMBIOSMajorVersion & "'," & _
				"'" & strSMBIOSMinorVersion & "'," & _
				"'" & strBIOSVersion & "'," & _
				"'" & strHPMgmtVersion & "'," & _
				"'" & strHPCFAVersion & "'," & _
				"'" & strHPCNAVersion & "'," & _
				"'" & strHPCSAVersion & "'," & _
				"'" & strHPCSA2Version & "'," & _
				"'" & strHPWBAVersion & "'," & _
				"'" & strCaption & "'," & _
				"'" & strCSDVersion & "'," & _
				"'" & strOSVersion & "'," & _
				"'" & strOrganization & "'," & _
				"'" & strRegisteredUser & "')"
		Call Exec_SQL_Query(strSQL)
	End If
End Function

'==============================================================

Function Send_ShareInfo(strSystemname)
	PrintMess String(40,"*")
	
	Dim arrRestrictedSystems, blOk
	blOk=True
	arrRestrictedSystems = Array("C003A","C003B","S034","S060")

	For nTemp=0 to UBound(arrRestrictedSystems)
		If(blOk) Then blOk = (InStr(strSystemname, arrRestrictedSystems(nTemp))=0)
	Next
	If blOk Then
		PrintMess "Gathering Share info on system " & strSystemname& " has started."
		Call Gather_ShareInfo(strSystemname)
	Else
		PrintMess "This computer is on the restricted list. No share usage info is gathered."
	End If
End Function

Function Gather_ShareInfo(strSystemname)
	' Delete previous Records from this machine
	strSQL = "delete from shareuse where servername like '" & strSystemname & "'"
	Call Exec_SQL_query(strSQL)

	On Error Resume Next
	strComputer=strSystemname
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
	If err.number=0 Then		
		Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_Share", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)

		For Each objItem In colItems
			' Only include file shares (type=0)
			If StrComp(Trim(objItem.Type), "0")=0 Then
				PrintMess "Share : [" & objItem.Name & "]"
				' strSize=CStr(GetDirSize(objItem.Path))
				strSize="0"

				' Add record to DB
				strsql = "insert into ShareUse "& _
					"(servername, domainname, poldatetime, sharename, path, description, type, size)" & _
					" VALUES (" & _
					"'" & strSystemname & "'," & _
					"'" & gDOMAIN & "'," & _
					"GetDate()," & _
					"'" & objItem.Name & "'," & _
					"'" & objItem.Path & "'," & _
					"'" & objItem.Description & "'," & _
					"'" & objItem.Type & "'," & _
					strSize & ")"

				Call Exec_SQL_query(strSQL)
			End If
		Next

	End If
End Function

' Checks the Dirsize of a directory
Function GetDirSize(Directory)
	Dim Size, Inline, ErrorFound
	Dim folderso, folder
	On Error Resume Next
  Set folderso = CreateObject("Scripting.FileSystemObject")
  Set folder = folderso.GetFolder(Directory)
	Size = folder.size
	ErrorFound = Err.number
  If ErrorFound <> 0 Then
  	Size = 0-ErrorFound
  Else
  	' Convert to KB
  	' If Size>0 Then Size=Round(Size/(1024))
  End If
	GetDirSize = Size
End Function


Function Get_Hosts
	
End Function