'=========================================================================
' Version	1.0
' Authored by   Marcel Jussen
'               Getronics
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

Const DEBUG_INFO	= True
Const ForReading 	= 1
Const ForWriting 	= 2
Const ForAppending 	= 8

Const PwdExpiredDays = 90

Const ADS_UF_SCRIPT = &H0001
Const ADS_UF_ACCOUNTDISABLE = &H0002
Const ADS_UF_HOMEDIR_REQUIRED = &H0008
Const ADS_UF_LOCKOUT = &H0010
Const ADS_UF_PASSWD_NOTREQD = &H0020
Const ADS_UF_PASSWD_CANT_CHANGE = &H0040
Const ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED = &H0080
Const ADS_UF_DONT_EXPIRE_PASSWD = &H10000
Const ADS_UF_SMARTCARD_REQUIRED = &H40000
Const ADS_UF_PASSWORD_EXPIRED = &H800000

Const LOGFILE = "ForcePasswordChange.log"
Const ADS_PROPERTY_CLEAR = 1

If objArgs.Count() < 1 Then
	PrintMess "Wrong parameters!"
	PrintMess "Use calcdays.vbs <username>"
	wscript.quit()
End If

Dim strUsername
strUsername = objArgs(0)

strDN = QueryAD_User(strUsername)
If Len(strDN) > 0 Then
	PrintMess strDN
	If GetPasswordNeverExpires(strDN) = True Then
		PrintMess "This account has the 'Password never expires' option set"
		PrintMess "Password expiration calculation is skipped."
	Else
		If GetPwdChangeAtNextLogon(strDN) = True Then
			PrintMess "Password change at next logon was already set."
		Else
			nDays = CalcPwdDays(strDN)
			If nDays >= PwdExpiredDays Then
				' SetPwdChangeAtNextLogon(strDN)
			Else
				PrintMess "Password expiry not set."			
			End If
		End If
	End If
Else
	PrintMess "ERROR: Could not find " & strUsername & " in the domain!"
End If

'----------------------------------------------------------
Function CalcPwdDays(strDN)
	Dim nError, dPwdLastSet, objUser,dExpires,DaysToExpiration
	nError = 0
	nDaysLastPwdSet = -1

	On Error Resume Next
	Set objUser = GetObject("LDAP://" & strDN)
	nError=err.number
  If nError=0 Then
  	dPwdLastSet = objUser.PasswordLastChanged
  	
  	nError=err.number
  	If nError=0 Then
  		PrintMess "The password was last set on " & _
             DateValue(dPwdLastSet) & " at " & TimeValue(dPwdLastSet)
  		dtmPwdLastSet = DateValue(dPwdLastSet)
			nDaysLastPwdSet= DateDiff("d", dtmPwdLastSet, Now)
			PrintMess "Days since last password change: " & CStr(nDaysLastPwdSet)
  	Else  		
  		PrintMess "Could not retrieve password last set date value."  		
			err.clear()
		End If
	Else
		PrintMess "ERROR: Could not connect to: " & strDN
		err.clear()
	End If
	CalcPwdDays = nDaysLastPwdSet
End Function

Function GetPwdChangeAtNextLogon(strDN)
	Dim nError,objUser
	nError = 0
	On Error Resume Next
	
	Set objUser = GetObject("LDAP://" & strDN)
  
  ' Determine domain maximum password age policy in days.
	Set objRootDSE = GetObject("LDAP://RootDSE")
	strDNSDomain = objRootDSE.Get("DefaultNamingContext")
	Set objDomain = GetObject("LDAP://" & strDNSDomain)
	Set objMaxPwdAge = objDomain.MaxPwdAge
  
  ' Account for bug in IADslargeInteger property methods.
	lngHighAge = objMaxPwdAge.HighPart
	lngLowAge = objMaxPwdAge.LowPart
	If (lngLowAge < 0) Then
    lngHighAge = lngHighAge + 1
	End If
	intMaxPwdAge = -((lngHighAge * 2^32) + lngLowAge)/(600000000 * 1440)
	PrintMess "Domain password expiry: " & CStr(intMaxPwdAge) & " days."

	' Retrieve user password information.
	' The pwdLastSet attribute should always have a value assigned,
	' but other Integer8 attributes representing dates could be "Null".
	If (TypeName(objUser.pwdLastSet) = "Object") Then
    Set objDate = objUser.pwdLastSet
    dtmPwdLastSet = Integer8Date(objDate, lngBias)
	Else
  	dtmPwdLastSet = #1/1/1601#
	End If
	lngFlag = objUser.Get("userAccountControl")
	
	blnPwdExpire = True
	If ((lngFlag And ADS_UF_PASSWD_CANT_CHANGE) <> 0) Then
    blnPwdExpire = False
	End If
	If ((lngFlag And ADS_UF_DONT_EXPIRE_PASSWD) <> 0) Then
    blnPwdExpire = False
	End If

	' Determine if password expired.
	blnExpired = False
	If (blnPwdExpire = True) Then
    If (DateDiff("d", dtmPwdLastSet, Now()) > intMaxPwdAge) Then
        blnExpired = True
    End If
	End If		
 
  GetPwdChangeAtNextLogon = blnPwdExpired
End Function

Function SetPwdChangeAtNextLogon(strDN)
	Dim nError,objUser
	nError = 0
	On Error Resume Next
	Set objUser = GetObject("LDAP://" & strDN)
	nError=err.number
  If nError=0 Then
  	objUser.Put "PwdLastSet", 0
    objUser.SetInfo
		
		nError=err.number
		If nError=0 Then
			PrintMess "Parameter was succesfully changed."
		Else
			PrintMess "ERROR: "& strDN
			PrintMess "ERROR: Could not change parameter: Change password at next logon."
			err.clear()
		End If
	Else
		PrintMess "ERROR: Could not connect to: "	& strDN
		err.clear()
	End If
	PwdChangeAtNextLogon = nError
End Function

Function GetPasswordNeverExpires(strDN)
	Dim objUser,objUserFlags
	Dim nError, bResult
	nError = 0
	bResult = False

	' On Error Resume Next
	Set objUser = GetObject("LDAP://" & strDN)
	nError=err.number
  If nError=0 Then
		objUserFlags = objUser.userAccountControl		
		If (objUserFlags And ADS_UF_DONT_EXPIRE_PASSWD) = ADS_UF_DONT_EXPIRE_PASSWD Then
			PrintMess "Password will never expire."
			bResult = True
		Else
			PrintMess "Password expiration is valid."
		End If
	Else
		PrintMess "ERROR: Could not connect to: "	& strDN
		err.clear()
	End if
	GetPasswordNeverExpires=bResult
End Function

'----------------------------------------------------------
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

  strLogFile = LOGFILE
  if FSO.FileExists(strLogFile) then
    Set OutFileObj = FSO.OpenTextFile(strLogFile, ForWriting)
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

'----------------------------------------------------------
Function QueryAD_User(strUsername)
	Dim Con, Root, Domain, sDomain, sFilter, sAttribsToReturn, sDepth
	Dim rs, i, Path
	Dim oCommand,objArgs,ADsObject,sADsPath
	Dim objName,objClass,objSchema,classObject

	On Error Resume Next

	'--------------------------------------------------------
	'Create the ADO connection object
	'--------------------------------------------------------
	Set Con = CreateObject("ADODB.Connection")
	Con.Provider = "ADsDSOObject"
	Con.Open "Active Directory Provider"

	'Create ADO command object for the connection.
	Set oCommand = CreateObject("ADODB.Command")
	oCommand.ActiveConnection = Con

	'Get the ADsPath for the domain to search.
	Set Root = GetObject("LDAP://rootDSE")

	'---------------------------------------------------------
	'Choose the NC you want to search and build the ADsPath
	'---------------------------------------------------------
	sDomain = root.Get("rootDomainNamingContext")
	Set domain = GetObject("GC://" & sDomain)
	sADsPath = "<" & domain.ADsPath & ">"

	'--------------------------------------------------------
	'Build the search filter
	'--------------------------------------------------------
	sFilter = "(&(objectCategory=person)(objectClass=user)(Name=" & strUsername & "))"
	sAttribsToReturn = "distinguishedName"
	sDepth = "subtree"

	'---------------------------------------------------------
	'Assemble and execute the query
	'---------------------------------------------------------
	oCommand.CommandText = sADsPath & ";" & sFilter & ";" & sAttribsToReturn & ";" & sDepth
	Set rs = oCommand.Execute

	'---------------------------------------------------------
	' Navigate the record set and get the object's DN
	'---------------------------------------------------------
	rs.MoveFirst
	While Not rs.EOF
    For i = 0 To rs.Fields.Count - 1
    	If rs.Fields(i).Name = "distinguishedName" Then
	    	Path = rs.Fields(i).Value
      End If
    Next
    rs.MoveNext
	Wend

	QueryAD_User = Path

End Function


