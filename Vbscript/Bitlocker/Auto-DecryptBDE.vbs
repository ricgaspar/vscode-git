sUsername = "nedcar\svcAddComp2Domain"
sPassword = "AddComp2Domain"
sDCfqdn = "dc07.nedcar.nl"
 
Function Write_Log(msg)
    Wscript.Echo msg
End Function
 
Function Get_RecoveryKeysFromDN(dn,sDCfqdn,sUsername,sPassword)
    Set objDSO = GetObject("LDAP:")
    strPathToComputer = "LDAP://" & sDCfqdn & "/" & dn
 
    Const ADS_SECURE_AUTHENTICATION = 1
    Const ADS_USE_SEALING = 64 '0x40
    Const ADS_USE_SIGNING = 128 '0x80
 
    '--------------------------------------------------------------------------------
    'Get all BitLocker recovery information from the Active Directory computer object
    '--------------------------------------------------------------------------------
    'Get all the recovery information child objects of the computer object
    Set objFveInfos = objDSO.OpenDSObject(strPathToComputer, sUsername, sPassword, _
        ADS_SECURE_AUTHENTICATION + ADS_USE_SEALING + ADS_USE_SIGNING)
    objFveInfos.Filter = Array("msFVE-RecoveryInformation")
 
    'Iterate through each recovery information object and save any existing key packages
    Dim aKeys()
    Redim aKeys(0)
    i = 0
    bFoundKey = False
    For Each objFveInfo in objFveInfos
        bFoundKey = True
        If uBound(aKeys) < i Then
            Redim Preserve aKeys(i)
        End If
        strName = objFveInfo.Get("name")
        strRecoveryPassword = objFveInfo.Get("msFVE-RecoveryPassword")
        sNamePass = strName & "|" & strRecoveryPassword
        aKeys(i) = sNamePass
        i = i + 1
    Next
 
    If bFoundKey = True Then
        retval = aKeys
    Else
        retval = null
    End If
 
    Get_RecoveryKeysFromDN = retval
End Function
 
Function Find_ADRecoveryKey(sBDEPassword,sDCfqdn,sUsername,sPassword)
    'Search for all computer objects
    strBase = "<GC://" & sDCfqdn & ">"
    strFilter = "(&(objectCategory=computer))"
    strQuery = strBase & ";" & strFilter  & ";distinguishedName;subtree"
 
    ''create connection
    Set oConnection = CreateObject("ADODB.Connection")
    oConnection.Provider = "ADsDSOObject"
    oConnection.Properties("User ID") = sUsername
    oConnection.Properties("Password") = sPassword
    oConnection.Properties("Encrypt Password") = True
    oConnection.Properties("ADSI Flag") = ADS_SERVER_BIND Or ADS_SECURE_AUTHENTICATION
    Set oCommand = CreateObject("ADODB.Command")
    oConnection.Open "Active Directory Provider"
    Set oCommand.ActiveConnection = oConnection
    oCommand.CommandText = strQuery
    oCommand.Properties("Page Size") = 100
    oCommand.Properties("Timeout") = 100
    oCommand.Properties("Cache Results") = False
 
  Set objRecordSet = oCommand.Execute
  If objRecordSet.EOF Then
    WScript.echo "The domain could not be contacted."
    WScript.Quit 1
  End If
  
  Wscript.Echo "The domain was contacted."
 
  'For each computer object found look through it's keys for the one we want.
  bKeyFound = False
  Do Until objRecordSet.EOF
    dnFound = objRecordSet.Fields("distinguishedName")
    Dim aRecoveryKeys
    aRecoveryKeys = Get_RecoveryKeysFromDN(dnFound,sDCfqdn,sUsername,sPassword)
 
    If IsArray(aRecoveryKeys) = True Then
        If Ubound(aRecoveryKeys) > 0 Then
            For Each sKey In aRecoveryKeys
                    If instr(sKey,sBDEPassword) Then
                        msg = "Matching key found under computer dn: """ & dnfound & """."
                        write_log msg
                        strTempString = Split(sKey,"|")
                    sRecoveryKey = strTempString(1)
                    bKeyFound = True
                    End If
                Next
            End If
 
        End If
 
    If bKeyFound = True Then
        Exit Do
    Else
            objRecordSet.MoveNext
        End If
  Loop
  ' Clean up.
  Set objConnection = Nothing
  Set objCommand = Nothing
  Set objRecordSet = Nothing
 
  If bKeyFound = True Then
    retval = sRecoveryKey
  Else
    retval = false
  End If
 
  Find_ADRecoveryKey = retval
End Function
 
Function Unlock_AllDrivesWithAD(sDCfqdn,sUsername,sPassword)
    On Error Resume Next
    'foreach encrypted drive
    Set oDrivesPasswords = CreateObject("Scripting.Dictionary")
    Set oWMIService = GetObject("winmgmts:\\.\root\CIMV2\Security\MicrosoftVolumeEncryption")
    Set oVolumes = oWMIService.InstancesOf("Win32_EncryptableVolume")
 
    For each volume In oVolumes
        bDecryptNeeded = False
        'check for encryption
        'ref: http://msdn.microsoft.com/en-us/library/windows/desktop/aa376434(v=vs.85).aspx
        volume.GetEncryptionMethod iBdeMethod
        volume.GetLockStatus iBDEStatus
        volume.GetKeyProtectors 0,VolumeKeyProtectorID
        sDriveLetter = volume.DriveLetter
 
        If iBDEStatus <> 0 Then
            msg = "Found locked volume. Drive letter: """ & sDriveLetter & """."			
            Write_Log msg
            For Each objId in VolumeKeyProtectorID
                msg = "KeyProtector for drive letter """ & sDriveLetter & """: """ & objId & """."
                write_log msg
			Next
			bDecryptNeeded = True
        End If
 
        If bDecryptNeeded = True Then
            'loop through all key protectors
            For Each BDEPassword in VolumeKeyProtectorID
                sADRecoveryKey = null
                'search AD for corresponding recovery keys
                sADRecoveryKey = Find_ADRecoveryKey(BDEPassword,sDCfqdn,sUsername,sPassword)
                    'attempt unlock
                If sADRecoveryKey <> False Then
                    msg = "Unlocking drive with AD key"
                    write_log msg
                    volume.UnlockWithNumericalPassword sADRecoveryKey
                    volume.GetProtectionStatus iBDEStatus
                    If iDBEstatus = 0 Then
                        msg = "Drive unlocked."
                        write_log msg
                    Else
                        msg = "Failed to unlock the drive."
                        write_log msg
                        Wscript.Quit(100)
                    End If
                End If
            Next
        End If
    Next
End Function
 
Function Unlock_AllDrivesWithManualKey(sUsername,sPassword)
    On Error Resume Next
		
    'foreach encrypted drive
    Set oDrivesPasswords = CreateObject("Scripting.Dictionary")
    Set oWMIService = GetObject("winmgmts:\\.\root\CIMV2\Security\MicrosoftVolumeEncryption")
    Set oVolumes = oWMIService.InstancesOf("Win32_EncryptableVolume")
 
    For each volume In oVolumes
        bDecryptNeeded = False
        'check for encryption
        'ref: http://msdn.microsoft.com/en-us/library/windows/desktop/aa376434(v=vs.85).aspx
        volume.GetEncryptionMethod iBdeMethod
        volume.GetLockStatus iBDEStatus
        volume.GetKeyProtectors 0,VolumeKeyProtectorID
        sDriveLetter = volume.DriveLetter		
 
        If iBDEStatus <> 0 Then
            msg = "Failed to unlock all volumes with AD recovery keys. Asking user for manual key input."
            Write_Log msg
            msg = "Found locked volume. Drive letter: """ & sDriveLetter & """."
            Write_Log msg
            For Each objId in VolumeKeyProtectorID
                msg = "KeyProtector for drive letter """ & sDriveLetter & """: """ & objId & """."
                write_log msg
          Next
                bDecryptNeeded = True
        End If
 
        If bDecryptNeeded = True Then
            'loop through all key protectors
            bContinue = True
            For Each BDEPassword in VolumeKeyProtectorID
                If bContinue = False Then
                    Exit For
                End If
                'Ask the user for one repeatedly until the drive unlocks or the user presses cancel.
                bContinue = True
                While bContinue = True
                    msg = "No key was found in AD for volume " & sDriveLetter & " with public key " & BDEPassword & ". Please enter a password to unlock the drive. Type ""next"" to attempt skipping to the next BDEPassword (if available). Press cancel to quit."
                    sUserKey = InputBox(msg)
                    If sUserKey = Null Or sUserKey = "" Then
                        Wscript.Quit(100)
                    ElseIf LCase(sUserKey) = "next" Then
                        bContinue = False
                    Else
                        volume.UnlockWithNumericalPassword sUserKey
                        volume.GetLockStatus iBDEStatus
                        If iBDEstatus = 0 Then
                            msg = "Drive unlocked."
                            write_log msg
                            bContinue = False
                        Else
                            msg = "Failed to unlock the drive."
                            msgbox msg
                        End If
                    End If
                Wend
            Next
        End If
    Next
End Function
 
Unlock_AllDrivesWithAD sDCfqdn,sUsername,sPassword
Unlock_AllDrivesWithManualKey sUsername,sPassword