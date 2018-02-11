'========================================================================#
'#
'# AUTHOR: Marcel Jussen
'# Save Bitlocker recovery informatation of all volumes to AD
'# 8-4-2014
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


Set objWMI = GetObject("winmgmts:\\.\root\cimv2")
Set colItems = objWMI.ExecQuery("Select * from Win32_Volume where DriveType=3")
For Each objItem In colItems
	strDriveLetter = objItem.DriveLetter		

	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate," _
		& "authenticationLevel=pktPrivacy}!\\." _
		& "\root\cimv2\security\microsoftvolumeencryption") 

	If Err.Number <> 0 Then
		WScript.Echo "Failed to connect to the BitLocker interface (Error 0x" & Hex(Err.Number) & ")."
		Wscript.Echo "Ensure that you are running with administrative privileges."
		WScript.Quit -1
	Else
		
		If(Len(strDriveLetter) > 0) then						
	
			Set colTargetVolumes = objWMIService.ExecQuery("Select * from Win32_EncryptableVolume where DriveLetter='" & strDriveLetter & "'")

			If colTargetVolumes.Count = 0 Then
				WScript.Echo "FAILURE: Unable to find BitLocker-capable drive " & strDriveLetter & " on this computer "
			Else
		
				For Each objFoundVolume in colTargetVolumes
					set objVolume = objFoundVolume
					strEncDriveLetter = objVolume.DriveLetter
					WScript.Echo "Encryptable Volume found :" & strEncDriveLetter
					intRC = objVolume.GetProtectionStatus(nPStatus)

					If nPStatus = 1 Then
						WScript.Echo "Drive is encrypted"
						
						nKeyProtectorType = 3 'Numerical Password
						insKey = objVolume.GetKeyProtectors(nKeyProtectorType,vProtectors)

						For each vFoundKeyProtectorID in vProtectors
							vKeyProtectorID = vFoundKeyProtectorID
							WScript.Echo "Key Protector: ", vKeyProtectorID					
						Next
				
						insKey = objVolume.GetKeyProtectorNumericalPassword(vKeyProtectorID,numPWD)

						If insKey <> 0 Then
							WScript.Echo "Password Get Failed"
						Else
							WScript.Echo "Numerical PW: " & numPWD
							WScript.Echo "For key Protector: ", vKeyProtectorID
					
							iBackupSuccessful = objVolume.BackupRecoveryInformationToActiveDirectory(vKeyProtectorID)

							If iBackupSuccessful <> 0 Then
								WScript.Echo "Password Storage to ADS failed."	
							Else
								WScript.Echo "Successfully stored password in ADS."
							End If	
					
						End If
	
					Else
						WScript.Echo "Drive Not Encrypted"
					End If				
				
				Next
		
			End If
			
		End If

	End If

Next