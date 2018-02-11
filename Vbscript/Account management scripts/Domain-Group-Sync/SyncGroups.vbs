'=========================================================================
' Version 1.0
' Authored by   Marcel Jussen
'               KPN Telecom/Professional Services
'=========================================================================

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

Const DEBUG_INFO  = True
Const ForReading  = 1
Const ForWriting  = 2
Const ForAppending  = 8

Const ADS_PROPERTY_CLEAR = 1
Const ADS_PROPERTY_APPEND = 3
Const ADS_PROPERTY_DELETE = 4 

Const LOGFILE = "Logboek\GroupSync.log"

Call Main()
wscript.quit()

Function Main()
	Dim strFromGroup, strToGroup
	
	If objArgs.count=2 Then
		strDNFromGroup = SearchDC(objArgs(0))
		strDNToGroup = SearchDC(objArgs(1))
	Else 
		PrintMess "ERROR: Input variables are not correct."
		PrintMess "       Usage: SyncGroups.vbs <source LM groupname> <destination LM groupname>"
	End If
	
	PrintMess String(50, "=")
	If Len(strDNFromGroup)=0 Or Len(strDNToGroup)=0 Then		
		Printmess "Source DN     : " & strDNFromGroup
		Printmess "Destination DN: " & strDNToGroup
		Printmess "ERROR: One of these groups could not be found in the domain."
	Else
		PrintMess "Synchronise members from: " 
		PrintMess strDNFromGroup 

		' create array with members from source group
		arrFromMembers = CreateMemberArray(strDNFromGroup)
		If Not IsArray(arrFromMembers) Then 	
			PrintMess " The source group does not contain any members." 
		Else
			nFromCount = UBound(arrFromMembers)+1
			PrintMess " (member count: " & CStr(nFromCount) & ")"
		End If
		
		PrintMess "to: "
		PrintMess strDNToGroup
		arrToMembers = CreateMemberArray(strDNToGroup)
		If Not IsArray(arrToMembers) Then 	
			PrintMess " The destination group does not contain any members." 
		Else
			nToCount = UBound(arrToMembers)+1
			PrintMess " (member count: " & CStr(nToCount) & ")"
		End If
		
		PrintMess String(50, ".")
		' Check if source group is empty
		If nFromCount = 0 Then
			If nToCount = 0 Then
				PrintMess " Source and destination groups are empty. Nothing to do."
			Else
				PrintMess " Source group is empty. Clearing destination group."
				Call ClearGroupMembers(strDNToGroup)
			End If
		Else
			If nToCount = 0 Then
				PrintMess " Destination group is empty. Adding all members from source group."
				Call AddMembersToGroup(strDNToGroup, arrFromMembers)
			Else
				PrintMess " Searching for group differences."
				
				' Search for new members
				arrNewMembers = getNewMembers(arrFromMembers, arrToMembers)
				If IsArray(arrNewMembers) Then
					PrintMess CStr(UBound(arrNewMembers)+1) & " new members found."
					Call AddMembersToGroup(strDNToGroup, arrNewMembers)
				Else
					PrintMess " No new members found to add to destination group."
				End If
		
				' Search for deleted members
				arrDeletedMembers = GetDeletedMembers(arrFromMembers, arrToMembers)
				If IsArray(arrDeletedMembers) Then
					PrintMess CStr(UBound(arrDeletedMembers)+1) & " members found to delete from destination group."
					Call DeleteMembersFromGroup(strDNToGroup, arrDeletedMembers)
				Else
					PrintMess " No members found to delete from destination group."
				End If
			End If
		End If
		
		PrintMess String(50, ".")
	
	End If
	PrintMess String(50, "=")
End Function

Function getNewMembers(arrFromMembers, arrToMembers)
	Dim arrResult
	If IsArray(arrFromMembers) And IsArray(arrToMembers) Then
		' Search each member from the source array
		' and check if its present in the destination array
		For each FromMember in arrFromMembers		
			bFound = False			
			For each ToMember in arrToMembers
				If Not bFound Then bFound = (StrComp(Trim(ToMember), Trim(FromMember))=0)
			Next
			If Not bFound Then
				If IsArray(arrResult) Then
					ReDim Preserve arrResult(UBound(arrResult)+1)
				Else
					ReDim arrResult(0)
				End If
				nCount = UBound(arrResult)
				arrResult(nCount) = FromMember
			End If
		Next
	End If
	getNewMembers = arrResult
End Function

Function getDeletedMembers(arrFromMembers, arrToMembers)
	Dim arrResult
	If IsArray(arrFromMembers) And IsArray(arrToMembers) Then
		For each ToMember in arrToMembers
			bFound = False
			For each FromMember in arrFromMembers
				If Not bFound Then bFound = (InStr(Trim(FromMember), Trim(ToMember))>0)
			Next
			If Not bFound Then				
				If IsArray(arrResult) Then
					ReDim Preserve arrResult(UBound(arrResult)+1)
				Else
					ReDim arrResult(0)
				End If
				nCount = UBound(arrResult)
				arrResult(nCount) = ToMember
			End If			
		Next
	End If	
	getDeletedMembers = arrResult
End Function

'---------------------------------------------------------
Function PrintMess(strMsg)
  Dim strMessage, strQfr, wshShell, strPath
  Dim strLogFile

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

  strMessage = strOutText & " : " & strMsg
  wscript.echo strMessage

  On Error Resume Next
  err.clear()
  Dim FSO, OutFileObj
  Set FSO = CreateObject ("Scripting.FileSystemObject")

  set WshShell = WScript.CreateObject("WScript.Shell")
  strPath = WshShell.ExpandEnvironmentStrings("%SystemDrive%")
  strLogFile = strPath & "\" & LOGFILE
  if FSO.FileExists(strLogFile) then
    Set OutFileObj = FSO.OpenTextFile(strLogFile, ForAppending)
  Else
    Set OutFileObj = FSO.CreateTextFile(strLogFile)
  End If
  If err.number<>0 Then
    wscript.echo "Foutje..."
    err.clear()
  Else
    OutFileObj.WriteLine(strMessage)
    OutFileObj.close()
  End if
End Function

'---------------------------------------------------------
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
  FindUDL = strResult
End Function

Function GetMemberCount(strDN)
	members = 0
	On Error Resume Next
	Set objGroup = GetObject(strDN)
	objGroup.GetInfo
	arrMemberOf = objGroup.GetEx("member")
	members=UBound(arrMemberOf)+1
	GetMemberCount = members
End Function

Function CreateMemberArray(strDN)
	Dim nCount, arrMembers
	nCount = GetMemberCount(strDN)	
	If nCount > 0 Then
		Set objGroup = GetObject(strDN)
		objGroup.GetInfo
		arrMembers = objGroup.GetEx("member")
	End If
	CreateMemberArray = arrMembers
End Function

Function ClearGroupMembers(strDN)
	On Error Resume Next
	PrintMess "Removing members from destination group:"
	PrintMess " " & strDN
	Set objGroup = GetObject(strDN) 
	objGroup.PutEx ADS_PROPERTY_CLEAR, "member", 0
	objGroup.SetInfo
End Function

Function AddMembersToGroup(strDN, arrMembers)
	If IsArray(arrMembers) Then
		On Error Resume Next
		PrintMess "Adding members to group:"
		PrintMess " " & strDN
		PrintMess "Members:"
		For each member in arrMembers
			If Len(member) > 0 Then
				PrintMess " " & member		
				Set objGroup = GetObject(strDN)
				objGroup.PutEx ADS_PROPERTY_APPEND, "member", Array(member)
				objGroup.SetInfo
				If Err.number <> 0 Then
					PrintMess "ERROR: Adding member to group " 
					PrintMess "      " & strDN & " ended in error."
				End If
			End If
		Next	
		Printmess "Done."	
	End If
End Function

Function DeleteMembersFromGroup(strDN, arrMembers)
	If IsArray(arrMembers) Then
		PrintMess "Removing " & CStr(UBound(arrMembers)+1) & " members from group:"
		PrintMess " " & strDN
		PrintMess "Members:"
		On Error Resume Next
		Set objGroup = GetObject(strDN)
		For each member in arrMembers
			If Len(member) > 0 Then
				PrintMess " " & member
				objGroup.PutEx ADS_PROPERTY_DELETE, "member", Array(member)
				objGroup.SetInfo
				If Err.number <> 0 Then
					PrintMess "ERROR: Removing member from group " 
					PrintMess "      " & strDN & " ended in error."
				End If
			End If
		Next	
		Printmess "Done."
	End If
End Function


Function SearchDC(strGroup)
'Declare variables
Dim strSearch
Dim strAdsPath
Dim strServerName
Dim strDefaultDomainNC
Dim strADSQuery
Dim objQueryResultSet
Dim objADOConn
Dim objADOCommand
Dim objUser
Dim intCount

	Const adStateOpen = 1

  strGroup = Trim(strGroup)
	
	'Get the Default Domain Naming Context
	strDefaultDomainNC = GetObject("LDAP://RootDSE").Get("DefaultNamingContext")	
	If (IsEmpty(strDefaultDomainNC)) Then  	
	  PrintMess "Error: Did not get the Default Naming Context"
	End If

	'Set up the ADO connection required to implement the search.
	Set objADOConn = CreateObject("ADODB.Connection")

	objADOConn.Provider = "ADsDSOObject"
	'Connect using current user credentials
	objADOConn.Open "Active Directory Provider"

	Set objADOCommand = CreateObject("ADODB.Command")
	Set objADOCommand.ActiveConnection = objADOConn

	'Format search criteria using SQL syntax
	strADSQuery = "SELECT AdsPath FROM 'LDAP:// " & _
  	strDefaultDomainNC & "' WHERE samAccountName = '" & strGroup & "'"
  objADOCommand.CommandText = strADSQuery

	'Execute the search
	Set objQueryResultSet = objADOCommand.Execute

	intCount = 0
	While Not objQueryResultSet.EOF
  	strAdsPath = objQueryResultSet.Fields("AdsPath")
  	intCount = intCount + 1
  	objQueryResultSet.MoveNext
	Wend
	objADOConn.Close
	Set objADOConn = Nothing
	Set objADOCoCommand = Nothing	
	SearchDC = strAdsPath
End Function 

