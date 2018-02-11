'=============================================================================== 
' 
'=============================================================================== 
 
 
' -------------------------------------------------------------------------------- 
' Usage 
' -------------------------------------------------------------------------------- 
 
Sub ShowUsage 
   Wscript.Echo "USAGE: Get-BitLockerRecoveryInfo [Optional Computer Name]" 
   Wscript.Echo "If no computer name is specified, the local computer is assumed." 
   WScript.Quit 
End Sub 
 
' -------------------------------------------------------------------------------- 
' Parse Arguments 
' -------------------------------------------------------------------------------- 
 
Set args = WScript.Arguments 
 
Select Case args.Count 
   
  Case 0 
      ' Get the name of the local computer       
      Set objNetwork = CreateObject("WScript.Network") 
      strComputerName = objNetwork.ComputerName 
     
  Case 1 
    If args(0) = "/?" Or args(0) = "-?" Then 
      ShowUsage 
    Else 
      strComputerName = args(0) 
    End If 
   
  Case Else 
    ShowUsage 
 
End Select 
 
' -------------------------------------------------------------------------------- 
' Helper function: Convert the octet GUID string (byte array) to a hex string 
' -------------------------------------------------------------------------------- 
 
'Reference:  
 
Function HexByte(b) 
      HexByte = Right("0" & Hex(b), 2) 
End Function  
 
Function ConvertOctetGuidToHexString(ByteArray) 
  Dim Binary, S 
  Binary = CStr(ByteArray) 
 
  On Error Resume Next 
 
  S = "{" 
  S = S & HexByte(AscB(MidB(Binary, 4, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 3, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 2, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 1, 1))) 
  S = S & "-"   
  S = S & HexByte(AscB(MidB(Binary, 6, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 5, 1))) 
  S = S & "-"   
  S = S & HexByte(AscB(MidB(Binary, 8, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 7, 1))) 
  S = S & "-"   
  S = S & HexByte(AscB(MidB(Binary, 9, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 10, 1))) 
  S = S & "-"   
  S = S & HexByte(AscB(MidB(Binary, 11, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 12, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 13, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 14, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 15, 1))) 
  S = S & HexByte(AscB(MidB(Binary, 16, 1))) 
  S = S & "}" 
 
  On Error GoTo 0 
 
  ConvertOctetGuidToHexString = S 
End Function  
 
 
' -------------------------------------------------------------------------------- 
' Get path to Active Directory computer object associated with the computer name 
' -------------------------------------------------------------------------------- 
 
Function GetStrPathToComputer(strComputerName)  
 
    ' Uses the global catalog to find the computer in the forest 
    ' Search also includes deleted computers in the tombstone 
 
    Set objRootLDAP = GetObject("LDAP://rootDSE") 
    namingContext = objRootLDAP.Get("defaultNamingContext") ' e.g. string dc=fabrikam,dc=com     
 
    strBase = "<GC://" & namingContext & ">" 
  
    Set objConnection = CreateObject("ADODB.Connection")  
    Set objCommand = CreateObject("ADODB.Command")  
    objConnection.Provider = "ADsDSOOBject"  
    objConnection.Open "Active Directory Provider"  
    Set objCommand.ActiveConnection =  objConnection  
 
    strFilter = "(&(objectCategory=Computer)(cn=" &  strComputerName & "))" 
    strQuery = strBase & ";" & strFilter  & ";distinguishedName;subtree"  
 
    objCommand.CommandText = strQuery  
    objCommand.Properties("Page Size") = 100  
    objCommand.Properties("Timeout") = 100 
    objCommand.Properties("Cache Results") = False  
 
    ' Enumerate all objects found.  
 
    Set objRecordSet = objCommand.Execute  
    If objRecordSet.EOF Then 
      WScript.echo "The computer name '" & strComputerName & "' cannot be found." 
      WScript.Quit 1 
    End If 
 
    ' Found object matching name 
 
    Do Until objRecordSet.EOF  
      dnFound = objRecordSet.Fields("distinguishedName") 
      GetStrPathToComputer = "LDAP://" & dnFound 
      objRecordSet.MoveNext  
    Loop  
 
 
    ' Clean up.  
    Set objConnection = Nothing  
    Set objCommand = Nothing  
    Set objRecordSet = Nothing  
 
End Function 
 
 
' -------------------------------------------------------------------------------- 
' Securely access the Active Directory computer object using Kerberos 
' -------------------------------------------------------------------------------- 
 
 
Set objDSO = GetObject("LDAP:") 
strPathToComputer = GetStrPathToComputer(strComputerName) 
 
WScript.Echo "Accessing object: " + strPathToComputer 
 
Const ADS_SECURE_AUTHENTICATION = 1 
Const ADS_USE_SEALING = 64 '0x40 
Const ADS_USE_SIGNING = 128 '0x80 
 
 
' -------------------------------------------------------------------------------- 
' Get all BitLocker recovery information from the Active Directory computer object 
' ------------------------------------------------------------------------------- 
 
' Get all the recovery information child objects of the computer object 
 
Set objFveInfos = objDSO.OpenDSObject(strPathToComputer, vbNullString, vbNullString, _ 
                                   ADS_SECURE_AUTHENTICATION + ADS_USE_SEALING + ADS_USE_SIGNING) 
 
objFveInfos.Filter = Array("msFVE-RecoveryInformation") 
 
' Iterate through each recovery information object  
 
For Each objFveInfo in objFveInfos 
 
   strName = objFveInfo.Get("name")  
   strRecoveryGuidOctet = objFveInfo.Get("msFVE-RecoveryGuid") 
   strRecoveryGuid = ConvertOctetGuidToHexString(strRecoveryGuidOctet) 
 
   strRecoveryPassword = objFveInfo.Get("msFVE-RecoveryPassword") 
 
   WScript.echo   
   WScript.echo "name: " + strName  
   WScript.echo "msFVE-RecoveryGuid: " + strRecoveryGuid 
   WScript.echo "msFVE-RecoveryPassword: " + strRecoveryPassword 
 
   If len(strRecoveryGuid) <> 38 Then 
      WScript.echo "WARNING: '" & strRecoveryGuid & "' does not appear to be a valid GUID." 
   End If 
 
Next 
 
WScript.Quit 