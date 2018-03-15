'Function which will load the picture from AD on DOMAIN\username for the logged on user
Function LoadPictureFromAD(szADsPath, szSaveFileName)
  Dim objUser, bytesRead, adoStreamWrite
  Const adTypeBinary = 1, adSaveCreateOverWrite = 2

  Set objUser = GetObject(szADsPath)
  bytesRead = objUser.Get("thumbnailPhoto")

  Set adoStreamWrite = CreateObject("ADODB.Stream")
  adoStreamWrite.Type = adTypeBinary
  adoStreamWrite.Open
  adoStreamWrite.Write(bytesRead)
  adoStreamWrite.SaveToFile szSaveFileName, adSaveCreateOverWrite
  adoStreamWrite.Close
End Function

'Function which will check the running OS Version
Function getOSVersion()
  strComputer = "."
  Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
  Set colOperatingSystems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
  For Each objOperatingSystem in colOperatingSystems
    getOSVersion = objOperatingSystem.Version
  Next
End Function

'Function which will get the SID of the logged on user from AD
Private Function getSid()
  strComputer = "."
  Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

  Set objAccount = objWMIService.Get("Win32_UserAccount.Name='" & strUsername & "',Domain='" & strDomain & "'")
  getSID = objAccount.SID
End Function

'Set the variables for the script
Set wshShell = CreateObject("WScript.Shell")
Set wshNetwork = WScript.CreateObject("WScript.Network")
Set objSysInfo = CreateObject("ADSystemInfo")
set oFSO = CreateObject("Scripting.FileSystemObject")

workingdir = Replace(wscript.scriptfullname, Wscript.scriptname, "")
username = wshNetwork.UserDomain & "\" & wshNetwork.UserName
strUserName = objSysInfo.UserName
dn = "LDAP://" & strUserName

path = wshShell.ExpandEnvironmentStrings("%temp%") & "\"
filename = path & "uap.jpg"

'Store AD Picture in %temp%\uap.jpg
LoadPictureFromAD dn, filename

'Run the useraccountpicture.exe for changing the User Account Picture on Windows 7 systems (W7 & W7sp1)
if ((getOSVersion() = "6.1.7600") Or (getOSVersion() = "6.1.7601")) Then
  wshshell.run workingdir & "useraccountpicture.exe " & username & " " & filename, 0, true
Else
  'Call UAC rights if not having admin rights
  Call ElevateUAC

  'find current user & domain
  strUsername = wshShell.ExpandEnvironmentStrings("%USERNAME%")
  strDomain = wshShell.ExpandEnvironmentStrings("%USERDOMAIN%")
  Wscript.sleep 1000

  strFileName = oFSO.GetTempName
  set oFile = oFSO.CreateTextFile(strFileName)    

  'Change right on Registry key for changing the path which will look for the uap.jpg
  oFile.WriteLine "HKLM\Software\Microsoft\Windows\CurrentVersion\AccountPicture\Users\"& getSid() &" [1 7 17]"
  oFile.Close

  WshShell.Run "regini " & strFileName, 8, true

  'Write the registry changes to the Register (GetSID is current User SID, filename is %temp%\uap.jpg)  
  WshShell.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\AccountPicture\Users\" & getSid() &"\Image200", filename, "REG_SZ"
  WshShell.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\AccountPicture\Users\" & getSid() &"\Image240", filename, "REG_SZ"
  WshShell.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\AccountPicture\Users\" & getSid() &"\Image400", filename, "REG_SZ"
  WshShell.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\AccountPicture\Users\" & getSid() &"\Image448", filename, "REG_SZ"
  WshShell.RegWrite "HKLM\Software\Microsoft\Windows\CurrentVersion\AccountPicture\Users\" & getSid() &"\Image960", filename, "REG_SZ"

  oFSO.DeleteFile strFileName

  Sub ElevateUAC
    If Not WScript.Arguments.Named.Exists("elevated") Then
      'Launch the script again as administrator
      With CreateObject("Shell.Application")
        .ShellExecute "wscript.exe", """" & _
        WScript.ScriptFullName & """ /elevated", "", "runas", 1
        WScript.Quit
      End With
    End If
  End Sub

End If