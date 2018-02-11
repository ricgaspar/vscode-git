'================================================================================= 
'  
'================================================================================= 
 
 
' -------------------------------------------------------------------------------- 
' Usage 
' -------------------------------------------------------------------------------- 
 
Sub ShowUsage 
   Wscript.Echo "USAGE: Get-TpmOwnerInfo [Optional Computer Name]" 
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
    Set objCommand.ActiveConnection = objConnection  
 
    strFilter = "(&(objectCategory=Computer)(cn=" &  strComputerName & "))" 
    strQuery = strBase & ";" & strFilter  & ";distinguishedName;subtree"  
 
    objCommand.CommandText = strQuery  
    objCommand.Properties("Page Size") = 100  
    objCommand.Properties("Timeout") = 100 
    objCommand.Properties("Cache Results") = False  
 
    ' Enumerate all objects found.  
 
    Set objRecordSet = objCommand.Execute  
    If objRecordSet.EOF Then 
      WScript.echo "The computer name '" &  strComputerName & "' cannot be found." 
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
strPath = GetStrPathToComputer(strComputerName) 
 
 
WScript.Echo "Accessing object: " + strPath 
 
Const ADS_SECURE_AUTHENTICATION = 1 
Const ADS_USE_SEALING = 64 '0x40 
Const ADS_USE_SIGNING = 128 '0x80 
 
Set objComputer = objDSO.OpenDSObject(strPath, vbNullString, vbNullString, _ 
                                   ADS_SECURE_AUTHENTICATION + ADS_USE_SEALING + ADS_USE_SIGNING) 
 
' -------------------------------------------------------------------------------- 
' Get the TPM owner information from the Active Directory computer object 
' -------------------------------------------------------------------------------- 
 
strOwnerInformation = objComputer.Get("msTPM-OwnerInformation") 
WScript.echo "msTPM-OwnerInformation: " + strOwnerInformation