Set oWMI = GetObject("winmgmts:\\.\root\cimv2")
Set colItems = oWMI.ExecQuery("Select ChassisTypes from Win32_SystemEnclosure",,48)
Set oShell = WScript.CreateObject("Wscript.Shell")
For Each oItem in colItems
 sChassisType = oItem.ChassisTypes(0)
Next
'Check to see if it's a laptop
Select Case sChassisType
Case 8, 9, 10
 Set colItems = oWMI.ExecQuery("Select Caption, Version from Win32_OperatingSystem",,48)
 For Each oItem In colItems
  sOSVersion = Left(oItem.Version, 3)
 Next

 'Evaluate Windows Vista, 7 or 8
 If sOSVersion = "6.0" Then
  sCaption = "Windows Vista detected - non-compliant!"
 ElseIf sOSVersion = "6.1" Or sOSVersion = "6.2" Then
  bEncrypted = False
  sCaption = ""
  Set colItems = oWMI.ExecQuery("Select OperatingSystemSKU from Win32_OperatingSystem",,48)
  For Each oItem In colItems
   sOSSKU = oItem.OperatingSystemSKU
  Next
 
  If sOSVersion = "6.1" Then
   Select Case sOSSKU
   Case 2,3,5,6,11,16,19,48
    bBitLockerAvailable = False
   Case Else
    bBitLockerAvailable = True
   End Select
  Else
   bBitLockerAvailable = True
  End If
   
  'Check to see if BitLocker is enabled
  If bBitLockerAvailable Then
   On Error Resume Next
   Set oBitLocker = GetObject("winmgmts:\\.\root\CIMV2\Security\MicrosoftVolumeEncryption")
   If Err.Number = -2147217394 Then
    oShell.Run "mofcomp.exe C:\Windows\System32\wbem\win32_encryptablevolume.mof", 0, True
    Set oBitLocker = GetObject("winmgmts:\\.\root\CIMV2\Security\MicrosoftVolumeEncryption")
   End If
   On Error Goto 0
     
   Set volumes = oBitLocker.InstancesOf("Win32_EncryptableVolume")
   For each volume In volumes
    drv = volume.DriveLetter
    If drv="C:" Then
     psval = volume.GetProtectionStatus(ps)
     csval = volume.GetConversionStatus(cs)
     Select Case cs
     Case 0
      bEncrypted = False
     Case 1
      If ps = 1 Then
       bEncrypted = True
       sCaption ="Compliant - Bitlocker enabled."
      Else
       bEncrypted = True
       sCaption = "BitLocker is suspended!"
      End If
     Case 2
      bEncrypted = True
      sCaption = "Encryption is in progress."
     Case 3
      bEncrypted = True
      sCaption = "Decryption is in progress!"
     Case 4
      bEncrypted = True
      sCaption = "Encryption is paused!"
     Case 5
      bEncrypted = True
      sCaption = "Decryption is paused!"
     End Select
    End If
   Next
  End If
    
  If Not(bEncrypted) Then
   bEncrypted=False
   sCaption = "Win7 without BitLocker!"
  End If
 End If

Case Else
 bEncrypted = False
 sCaption = "Compliant - System is not a laptop."
End Select
wscript.echo sCaption