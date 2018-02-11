'*******************************************************************************
'
' Script: NTFSPERMS.VBS
' Author: Marcel Jussen
' Version: 2.0 (20-11-2007)
'
'*******************************************************************************
Option Explicit

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

Const ForReading = 1, ForWriting = 2, ForAppending = 8

		'When working with NTFS Security, we use constants that match the API documentation
    '********************* ControlFlags *********************
    CONST ALLOW_INHERIT  			= 33796		'Used in ControlFlag to turn on Inheritance
								'Same as: 
								'SE_SELF_RELATIVE + SE_DACL_AUTO_INHERITED + SE_DACL_PRESENT
    CONST DENY_INHERIT   			= 37892		'Used in ControlFlag to turn off Inheritance
								'Same as: 
								'SE_SELF_RELATIVE + SE_DACL_PROTECTED + SE_DACL_AUTO_INHERITED + SE_DACL_PRESENT
    Const SE_OWNER_DEFAULTED 			= 1		'A default mechanism, rather than the the original provider of the security 
								'descriptor, provided the security descriptor's owner security identifier (SID). 

    Const SE_GROUP_DEFAULTED 			= 2		'A default mechanism, rather than the the original provider of the security
								'descriptor, provided the security descriptor's group SID. 

    Const SE_DACL_PRESENT 				= 4		'Indicates a security descriptor that has a DACL. If this flag is not set, 
								'or if this flag is set and the DACL is NULL, the security descriptor allows 
								'full access to everyone.

    Const SE_DACL_DEFAULTED 			= 8		'Indicates a security descriptor with a default DACL. For example, if an 
								'object's creator does not specify a DACL, the object receives the default 
								'DACL from the creator's access token. This flag can affect how the system 
								'treats the DACL, with respect to ACE inheritance. The system ignores this 
								'flag if the SE_DACL_PRESENT flag is not set. 

    Const SE_SACL_PRESENT 				= 16		'Indicates a security descriptor that has a SACL. 

    Const SE_SACL_DEFAULTED 			= 32		'A default mechanism, rather than the the original provider of the security 
								'descriptor, provided the SACL. This flag can affect how the system treats 
								'the SACL, with respect to ACE inheritance. The system ignores this flag if 
								'the SE_SACL_PRESENT flag is not set. 

    Const SE_DACL_AUTO_INHERIT_REQ 	= 256		'Requests that the provider for the object protected by the security descriptor 
								'automatically propagate the DACL to existing child objects. If the provider 
								'supports automatic inheritance, it propagates the DACL to any existing child 
								'objects, and sets the SE_DACL_AUTO_INHERITED bit in the security descriptors 
								'of the object and its child objects.

    Const SE_SACL_AUTO_INHERIT_REQ 		= 512		'Requests that the provider for the object protected by the security descriptor 
								'automatically propagate the SACL to existing child objects. If the provider 
								'supports automatic inheritance, it propagates the SACL to any existing child 
								'objects, and sets the SE_SACL_AUTO_INHERITED bit in the security descriptors of 
								'the object and its child objects.

    Const SE_DACL_AUTO_INHERITED 		= 1024		'Windows 2000 only. Indicates a security descriptor in which the DACL is set up 
								'to support automatic propagation of inheritable ACEs to existing child objects. 
								'The system sets this bit when it performs the automatic inheritance algorithm 
								'for the object and its existing child objects. This bit is not set in security 
								'descriptors for Windows NT versions 4.0 and earlier, which do not support 
								'automatic propagation of inheritable ACEs.

    Const SE_SACL_AUTO_INHERITED 		= 2048		'Windows 2000: Indicates a security descriptor in which the SACL is set up to 
								'support automatic propagation of inheritable ACEs to existing child objects. 
								'The system sets this bit when it performs the automatic inheritance algorithm 
								'for the object and its existing child objects. This bit is not set in security 
								'descriptors for Windows NT versions 4.0 and earlier, which do not support automatic 
								'propagation of inheritable ACEs.

    Const SE_DACL_PROTECTED 			= 4096		'Windows 2000: Prevents the DACL of the security descriptor from being modified 
								'by inheritable ACEs. 

    Const SE_SACL_PROTECTED 				= 8192		'Windows 2000: Prevents the SACL of the security descriptor from being modified 
								'by inheritable ACEs. 

    Const SE_SELF_RELATIVE 				= 32768		'Indicates a security descriptor in self-relative format with all the security 
								'information in a contiguous block of memory. If this flag is not set, the security 
								'descriptor is in absolute format. For more information, see Absolute and 
								'Self-Relative Security Descriptors in the Platform SDK topic Low-Level Access-Control.

    '********************* ACE Flags *********************
    CONST OBJECT_INHERIT_ACE  			= 1 	'Noncontainer child objects inherit the ACE as an effective ACE. For child 
							'objects that are containers, the ACE is inherited as an inherit-only ACE 
							'unless the NO_PROPAGATE_INHERIT_ACE bit flag is also set.

    CONST CONTAINER_INHERIT_ACE 		= 2 	'Child objects that are containers, such as directories, inherit the ACE
							'as an effective ACE. The inherited ACE is inheritable unless the 
							'NO_PROPAGATE_INHERIT_ACE bit flag is also set.  

    CONST NO_PROPAGATE_INHERIT_ACE 	= 4 	'If the ACE is inherited by a child object, the system clears the 
							'OBJECT_INHERIT_ACE and CONTAINER_INHERIT_ACE flags in the inherited ACE. 
							'This prevents the ACE from being inherited by subsequent generations of objects.  

    CONST INHERIT_ONLY_ACE	 			= 8 	'Indicates an inherit-only ACE which does not control access to the object
							'to which it is attached. If this flag is not set, the ACE is an effective
							'ACE which controls access to the object to which it is attached. Both 
							'effective and inherit-only ACEs can be inherited depending on the state of
							'the other inheritance flags. 

    CONST INHERITED_ACE		 			= 16 	'Windows NT 5.0 and later, Indicates that the ACE was inherited. The system sets
							'this bit when it propagates an inherited ACE to a child object. 

    CONST ACEFLAG_VALID_INHERIT_FLAGS = 31 	'Indicates whether the inherit flags are valid.  


    'Two special flags that pertain only to ACEs that are contained in a SACL are listed below. 

    CONST SUCCESSFUL_ACCESS_ACE_FLAG 	= 64 	'Used with system-audit ACEs in a SACL to generate audit messages for successful
							'access attempts. 

    CONST FAILED_ACCESS_ACE_FLAG 		= 128 	'Used with system-audit ACEs in a SACL to generate audit messages for failed
							'access attempts. 

    '********************* ACE Types *********************
    CONST ACCESS_ALLOWED_ACE_TYPE 	= 0 	'Used with Win32_Ace AceTypes
    CONST ACCESS_DENIED_ACE_TYPE 		= 1 	'Used with Win32_Ace AceTypes
    CONST AUDIT_ACE_TYPE 				= 2 	'Used with Win32_Ace AceTypes


    '********************* Access Masks *********************

    Dim Perms_LStr, Perms_SStr, Perms_Const
    'Permission LongNames
    Perms_LStr=Array("Synchronize"			, _
		"Take Ownership"					, _
		"Change Permissions"				, _
		"Read Permissions"					, _
		"Delete"							, _
		"Write Attributes"					, _
		"Read Attributes"					, _
		"Delete Subfolders and Files"			, _
		"Traverse Folder / Execute File"		, _
		"Write Extended Attributes"			, _
		"Read Extended Attributes"			, _
		"Create Folders / Append Data"		, _
		"Create Files / Write Data"			, _
		"List Folder / Read Data"	)
    'Permission Single Character codes
    Perms_SStr=Array("E"		, _
		"D"		, _
		"C"		, _
		"B"		, _
		"A"		, _
		"9"		, _
		"8"		, _
		"7"		, _
		"6"		, _
		"5"		, _
		"4"		, _
		"3"		, _
		"2"		, _
		"1"		)
    'Permission Integer
    Perms_Const=Array(&H100000	, _
		&H80000		, _
		&H40000		, _
		&H20000		, _
		&H10000		, _
		&H100		, _
		&H80		, _
		&H40		, _
		&H20		, _
		&H10		, _
		&H8			, _
		&H4			, _
		&H2			, _
		&H1		)

Dim objWMIService
Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2") 

Dim objFSO, strInFile, fsoCfg, strFolderPath
Dim objFSOout, strOutFile, fsoOut
Dim objFSOchk, strText

set objFSO = CreateObject("Scripting.FileSystemObject")
set objFSOout = CreateObject("Scripting.FileSystemObject")
set objFSOchk = CreateObject("Scripting.FileSystemObject")
strInFile = objArgs(0)
strOutFile = objArgs(1)

If objFSOout.FileExists(strOutFile) Then
	Set fsoOut=objFSO.OpenTextFile(strOutFile, ForAppending, True)
Else
	Set fsoOut=objFSO.OpenTextFile(strInFile, ForWriting, True)
End If

If objFSO.FileExists(strInFile) Then
	Set fsoCfg=objFSO.OpenTextFile(strInFile, ForReading, True)
	Do While fsoCfg.AtEndOfStream <> True
  	' Read line from config file
    strFolderPath = fsoCfg.Readline()
    If objFSOchk.FolderExists(strFolderPath) Then
    	Call DisplayNTFSPerms(strFolderPath)
    Else
    	strText = strFolderPath & Chr(9) & "Everyone" & Chr(9) & "ERROR" & Chr(9) & "Invalid character in foldername!" & Chr(9) & "This folder" & Chr(9)
    	fsoOut.Writeline(strText)
    End If
  Loop
End If

Wscript.quit()

Function DisplayNTFSPerms(strPath)

	Dim colItems
	strPath = replace(strPath, "\", "\\")
	Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_LogicalFileSecuritySetting WHERE Path=""" & strPath & """",,48) 

	Dim objOutParams, objSecDescriptor, numControlFlags
	Dim TempSecString, ReturnAceFlags, objDACL_Member
	Dim strAceType, objTrustee, numAceFlags, strAceFlags
	Dim objItem
	Dim strDomain, strTrustee
	For Each objItem in colItems 
		
		
		Set objOutParams = objItem.ExecMethod_("GetSecurityDescriptor")
		set objSecDescriptor = objOutParams.Descriptor			
		numControlFlags = objSecDescriptor.ControlFlags
		If IsArray(objSecDescriptor.DACL) Then
			
			For Each objDACL_Member in objSecDescriptor.DACL
					TempSECString = ""
					ReturnAceFlags = 0
					Select Case objDACL_Member.AceType
						Case ACCESS_ALLOWED_ACE_TYPE
							strAceType = "Allowed"
						Case ACCESS_DENIED_ACE_TYPE
							strAceType = "Denied"
						Case else
							strAceType = "Unknown"
					End select
			
					Set objtrustee = objDACL_Member.Trustee
					numAceFlags = objDACL_Member.AceFlags
					strAceFlags = StringAceFlag(numAceFlags, numControlFlags, SE_DACL_AUTO_INHERITED, FALSE, ReturnAceFlags)
					TempSECString = SECString(objDACL_Member.AccessMask,TRUE)
					If ReturnAceFlags = 2 then
						If TempSECString = "Read and Execute" then
							TempSECString = "List Folder Contents"
						End if
					End If
			
					strDomain = objtrustee.Domain
					strTrustee = objtrustee.Name
					If Len(strDomain)>0 Then strTrustee = strDomain & "\" & strTrustee
					
					' wscript.echo objItem.Path & ";" & strTrustee & ";" & strAceType & ";" & CStr(numAceFlags) & ";" & TempSECString & ";" & strAceFlags
					Dim strOutText
					strOutText = objItem.Path & Chr(9) & strTrustee & Chr(9) & strAceType & Chr(9) & TempSECString & Chr(9) & strAceFlags & Chr(9)
					
					'**************************************************************************
					' Filter ongewenste accounts uit het overzicht
					'**************************************************************************
					
					If (InStr(strTrustee, "Domain Admins") =0) And _
						(InStr(strTrustee, "NEDCAR\adm1") =0) And _
						(InStr(strTrustee, "NAS-NTFS-Full-Access") =0) And _
						(InStr(strTrustee, "CREATOR OWNER") =0) And _
						(InStr(strTrustee, "NT AUTHORITY\SYSTEM") =0) And _
						(InStr(strTrustee, "BUILTIN\Users") = 0) And _
						(InStr(strTrustee, "BUILTIN\Administrators") = 0) Then
						 	
						If (InStr(TempSECString, "Unknown") = 0) Then 
							fsoOut.Writeline(strOutText)
							wscript.echo ObjItem.Path
						End If
					End If
					
					Set objtrustee = Nothing
				Next
				
			End If
	Next

End Function

'********************************************************************
'*
'* Function StringAceFlag()
'* Purpose: Changes the AceFlag into a string
'* Input:   numAceFlag =      This items ACEFlag
'*          numControlFlags = This Descriptors AceFlag
'*          FlagToCheck =     This lists Auto_Inherited bit to check for
'*          ReturnShort =     If True then we will return a short version
'*          ReturnAceFlags =  Final numAceFlags value after changes (leaves real one alone
'* Output:  String of our codes
'*
'********************************************************************

Function StringAceFlag(ByVal numAceFlags, ByVal numControlFlags, ByVal FlagToCheck, ByVal ReturnShort, ByRef ReturnAceFlags)

    On Error Resume Next    

    Dim TempShort, TempLong

    Do
	If numAceFlags = 0 then 
		TempShort = "Implicit"
		TempLong = "This Folder Only"
		Exit Do
	End if
	If numAceFlags > FAILED_ACCESS_ACE_FLAG then
		numAceFlags = numAceFlags - FAILED_ACCESS_ACE_FLAG
	End if
	If numAceFlags > SUCCESSFUL_ACCESS_ACE_FLAG then
		numAceFlags = numAceFlags - SUCCESSFUL_ACCESS_ACE_FLAG
	End if
	If ((numAceFlags And INHERITED_ACE) = INHERITED_ACE) then
		TempShort = "Inherited"
		numAceFlags = numAceFlags - INHERITED_ACE
		TempLong = "Inherited"
	Else
		TempShort = "Implicit"
		TempLong = "Implicit"
	End If

	ReturnAceFlags = numAceFlags 

	If numControlFlags > DENY_INHERIT then
		numControlFlags = numControlFlags - DENY_INHERIT
	End if
	If numControlFlags > ALLOW_INHERIT then
		numControlFlags = numControlFlags - ALLOW_INHERIT
	End if

	Select Case numAceFlags 
	Case 0
		TempLong = "This Folder Only"
	Case 1							'OBJECT_INHERIT_ACE
		TempLong = "This Folder and Files"
	Case 2							'CONTAINER_INHERIT_ACE
		TempLong = "This Folder and Subfolders"
	Case 3
		TempLong = "This Folder, Subfolders and Files"
	Case 9
		TempLong = "Files Only"
	Case 10
		TempLong = "Subfolders only"
	Case 11
		TempLong = "Subfolders and Files only"
	Case Else
		If ((numControlFlags And FlagToCheck) = FlagToCheck) then
			TempShort = "Inherited"
			TempLong = "Inherited"
		End if
	End Select
	Exit Do
    Loop

    If ReturnShort then
	StringAceFlag = TempShort
    Else
	StringAceFlag = TempLong
    End If    

End Function

'********************************************************************
'*
'* Function SECString()
'* Purpose: Converts SEC bitmask to a string
'* Input:   intBitmask - integer and ReturnLong - Boolean
'* Output:  String Array
'*
'********************************************************************

Function SECString(byval intBitmask, byval ReturnLong)

    On Error Resume Next
    Dim LongName, X    

    SECString = ""

    Do	
		
	For X = LBound(Perms_LStr) to UBound(Perms_LStr)
    		If ((intBitmask And Perms_Const(X)) = Perms_Const(X)) then
			If Perms_SStr(X) <> "" then
				SECString = SECString & Perms_SStr(X)
			End if
    		End if
	Next
	
	Select Case SECString
	Case "DCBA987654321", "EDCBA987654321"
		SECString = "F"								'Full control
		LongName = "Full Control"	
	Case "BA98654321", "EBA98654321"
		SECString = "M"								'Modify
		LongName = "Modify"
	Case "B98654321", "EB98654321"
		SECString = "XW"								'Read, Write and Execute
		LongName = "Read, Write and Execute"
	Case "B9854321", "EB9854321"
		SECString = "RW"								'Read and Write
		LongName = "Read and Write"
	Case "B8641", "EB8641"
		SECString = "X"								'Read and Execute
		LongName = "Read and Execute"
	Case "B841", "EB841"
		SECString = "R"								'Read
		LongName = "Read"
	Case "9532", "E9532"
		SECString = "W"								'Write
		LongName = "Write"
	Case Else
		If SECString = "" then
			LongName = "Special (Unknown)"
			If debug_on then
				LongName = "Unknown (" & intBitmask & ")"
			End if
		Else
			If LEN(SECString) = 1 then
				For X = LBound(Perms_SStr) to UBound(Perms_SStr)
					If StrComp(SECString,Perms_SStr(X),1) = 0 Then
						LongName = "Advanced (" & Perms_LStr(X) & ")"
						Exit For
					End if
				Next
			Else
				LongName = "Special (" & SECString & ")"
			End if
		End if
	End Select

	Exit Do
    Loop

    If ReturnLong Then SECString = LongName

End Function