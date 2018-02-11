'<!--********************************************************************
'*
'*  File:           StartHere.vbs
'*  Created:        Augustus 2004
'*  Version:        1.0
'*  Author:         Marcel Jussen
'*
'*  Description:    NedCar user Management scripts.  
'*
'*  Copyright (C) 2004 KPN Telecom
'*
'********************************************************************-->
' Save passed arguments
Dim Argcount, args, newshell, objArgs
Set objArgs = Wscript.Arguments
For Argcount = 0 to objArgs.Count - 1 
 args = args + " " + objArgs(Argcount)
Next

' Check if Wscript was called
if right(ucase(wscript.FullName),11)="WSCRIPT.EXE" then
    Set newshell = WScript.CreateObject("WScript.Shell")
    newshell.Run "cscript.exe " & wscript.ScriptFullName + " " + args, 1
    wscript.quit
end if
'----------------------- FORCE CSCRIPT RUN -------------------------------
Const strFolder 	= "C:\NedCarUM2"
Const strSource 	= "\\S100\d$\NedCarUM2\syncSourceFiles.cmd"

Call CheckEnvironment()

wscript.quit()

Sub startSync
	Dim wshShell, WshSysEnv
	Dim strCommand, strRun
	Dim strSyncCommand 
	Dim objFSO, filespec	
	
	' create shell and run command in RUNAS environment.
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	set wshShell = CreateObject("WScript.Shell")
	Set WshSysEnv = WshShell.Environment("SYSTEM")
			
	strSyncCommand = strFolder & "\syncSourceFiles.cmd"			
	strCommand = WshSysEnv("COMSPEC") & " /C " & strSyncCommand
	If objFso.FileExists(strSyncCommand) Then
		wscript.echo "Starting " & strCommand
		wshShell.Run strCommand, 5, true
	Else
		call MsgBox("Cannot execute " & strSyncCommand, 16, "Error")
	End If
	
End Sub

Sub startNedCarUM
	Dim wshShell, WshSysEnv
	Dim strCommand, strRun
	Dim strSyncCommand 
	Dim objFSO, filespec	
	
	' create shell and run command in RUNAS environment.
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	set wshShell = CreateObject("WScript.Shell")
	Set WshSysEnv = WshShell.Environment("SYSTEM")
			
	strSyncCommand = strFolder & "\user.cmd"			
	strCommand = WshSysEnv("COMSPEC") & " /C " & strSyncCommand & " start"	
	
	If objFso.FileExists(strSyncCommand) Then
		wscript.echo "Starting " & strCommand
		wshShell.Run strCommand, 3, true
	Else
		call MsgBox("Cannot execute " & strSyncCommand, 16, "Error")
	End If	
End Sub

Sub CreateNedCarUM
	Dim wshShell
	Dim strSyncCommand 
	Dim objFSO
	
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	
	strSyncCommand = strFolder & "\syncSourceFiles.cmd"
	' create folder
	If not (objFSO.FolderExists(strFolder)) Then objFSO.CreateFolder(strFolder)
	If not objFSO.FileExists(strSyncCommand) Then
		If objFSO.FileExists(strSource) Then
			Call objFSO.CopyFile(strSource, strSyncCommand)
		Else
			call MsgBox("Cannot create syncfile " & strSource, 16, "Error")
		End If
	End If
End Sub

Function CheckEnvironment
	Dim objWMIService, colItems, strComputer, strVersion
	
	' Select local computer
	strComputer = "."
  Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
  Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem", "WQL", _
                                          wbemFlagReturnImmediately + wbemFlagForwardOnly)
	For Each objItem In colItems                                           
		strVersion = objItem.Version      
	Next
	
	If (Mid(strVersion,1,3)="5.1") Or (Mid(strVersion,1,3)="5.2") Then
		Call CreateNedCarUM()
		Call startSync()
		Call startNedCarUM()		
		
	Else
		call MsgBox("Voor het beheer van Active Directory is minimaal een Windows XP of Windows 2003 Server omgeving vereist!", vbCritical, "Error Windows Version " & strVersion )
		call MsgBox("Gebruik de server DS002 voor het beheer van user accounts.", vbExclamation, "Info")
		
	End If
End Function