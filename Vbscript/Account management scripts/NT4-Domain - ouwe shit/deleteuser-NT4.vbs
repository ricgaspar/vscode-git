strDomainName = "NEDCAR"

Dim objArgs, objCount, strArgs
Set objArgs = Wscript.Arguments
strUsername = objArgs(0)

Call deleteUser(strUsername)

wscript.quit()
	
Sub DeleteUser(strUsername)
	if (chkUIDExists(strDomainName, strUserName) = True) then
			' Add log entry
			AddToLog("Deleting account " & strDomainName & "\" & strUserName)
			call deleteUID(strDomainName, strUserName)			
	End if				
end Sub

'- ADSI ----------------------------------------------
'function to check if a UID exists in the domain
Function chkUIDExists(strDomainName, strUserName)
	dim bResult, UsrObj
	On Error Resume Next
	err.clear()
	Set UsrObj = GetObject("WinNT://" & strDomainName & "/" & strUserName & ",user")
	if err.number<0 then	
		AddToLog("ERROR: Account " & strDomainName & "\" & strUserName & " does not exist !")
		bResult = False
		err.Clear
	Else
		bResult = True
	end If
	usrobj = Nothing
	chkUIDExists = bResult
End Function

Sub deleteUID(strDomainName, strUserName)
	dim DomainObj
	
	On Error Resume Next
	err.clear()
	' Connect to domain
	Set DomainObj = GetObject("WinNT://" & strDomainName)
	if err.number<0 then	
		' Show an error message 
		AddToLog("Could not bind to domain " & strDomainName) 
		err.Clear
	else
		' Delete account
		call DomainObj.Delete("user", strUserName)	
		if err.number<0 then	
			' Show an error message 
			AddToLog("Could not delete account " & strUserName & " in domain " & strDomainName) 
			err.Clear
		end if
	end If
		
	' Done so clear variables
	Set DomainObj = Nothing
End Sub

Sub AddToLog(strText)
	const	ForAppend 	= 8
	const	LogFile		= "\\S100\LOGBOEK\NEDCARUM2\opruimen.log"
	const	htmSource	= "UserDelete"
	
	dim WshNetwork, fsoObj, f, strTemp
	dim strDomain, strComputer, strUsername
	dim strTime
	
	Set WshNetwork = CreateObject("WScript.Network")
	strComputer = WshNetwork.ComputerName
  strUsername = WshNetwork.UserName
	strTime = Now()
	
	Set fsoObj = CreateObject("Scripting.FileSystemObject")
   	Set f = fsoObj.OpenTextFile(LogFile, ForAppend, True)
   	strTemp = strTime & Chr(32) & htmSource & Chr(9) & strComputer & Chr(9) & strUsername & chr(9) & strText
   	f.WriteLine strTemp
   	f.Close
   	
  wscript.echo strTemp
End Sub