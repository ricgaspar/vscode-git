'==========================================================================
'
' VBScript Source File -- Created with SAPIEN Technologies PrimalScript 2012
'
' NAME: Script for adding/removing all domain based namespaces to/from a DFS server
'
' AUTHOR: Windows User , VDL Nedcar
' DATE  : 28-10-2013
'
' COMMENT: 
'
'==========================================================================

'Init
Dim objShell, fso, Scriptpath
Set objShell = WScript.CreateObject( "WScript.Shell" )
Set fso = CreateObject("Scripting.FileSystemObject") 
Scriptpath = fso.GetParentFolderName(wscript.ScriptFullName)

'Global Variables
Dim DFS_Array() 'Array containg all the DFS Namespaces
Dim strDFSRootDrive : strDFSRootDrive = "D"
Dim strDFSfolder : strDFSfolder = "DFSRoots"
Dim strDFSRootfolder : strDFSRootfolder = strDFSRootDrive & ":\" & strDFSfolder

Dim NewDC1 : NewDC1 = "DC08" 'The New Domain Controllers with DFS role
Dim OldDC1 : OldDC1 = "TDC01" 'The Old Domain Controllers with DFS that will be removed from DFS as root target

'Main
	GetDFS_Namespace
	' Create_and_Share_Folder
	Add_Root_Target
	' Remove_Root_Target
'End Main

Sub GetDFS_Namespace	
	Dim i : i = 0
	Dim objItem
	
	Set colItems = GetObject ("LDAP://cn=Dfs-Configuration, cn=system, dc=nedcar, dc=nl")
	' Set colItems = GetObject ("LDAP://cn=Dfs-Configuration, cn=system, dc=domain, dc=local")

	For Each objItem in colItems
	    ReDim Preserve DFS_Array(i)
	    DFS_Array(i)= objItem.CN
	    Wscript.Echo "Got Namespace for AD with name: " & objItem.CN
	    i=i+1 
	Next
End Sub 'GetDFS_Namespace

Sub Create_and_Share_Folder
	Const MaxConnections = 0
	Dim filesys, newfolder, objNewFolder 
	Dim counter : counter = 0
	
	set filesys=CreateObject("Scripting.FileSystemObject") 
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & NewDC1 & "\root\cimv2")
	Set objNewShare = objWMIService.Get("Win32_Share")
	Set objNewFolder = objWMIService.Get("Win32_Process")	
		
	For counter = 0 To UBound(DFS_Array)
		Set ColFolders = objWMIService.execquery ("Select * from Win32_Directory Where " & "Name =" & Chr(39) & strDFSRootDrive & ":\\" & strDFSfolder & "\\" & DFS_Array(counter) & Chr(39))
		Dim strFolder : strFolder = strDFSRootfolder & "\" & DFS_Array(counter)

		objNewFolder.create "cmd.exe /c md " & strFolder, Null, Null, IntprocessID 'Create the folder	
		WScript.echo ("Created folder: " & strFolder)
		
		Do While ColFolders.count = 0 
			WScript.Echo ("Folder: " & strFolder & " not created yet. Looping....")
		 	Set ColFolders = objWMIService.execquery ("Select * from Win32_Directory Where " & "Name =" & Chr(39) & strDFSRootDrive & ":\\" & strDFSfolder & "\\" & DFS_Array(counter) & Chr(39))
		 	WScript.sleep 1000
		Loop
		
		objNewShare.Create strFolder, DFS_Array(counter), MaxConnections 'Share the folder
		WScript.Echo ("Create share: " & strFolder)		
	Next
End Sub 'Create_and_Share_Folder

Sub Add_Root_Target
	Dim counter : counter = 0
	Dim DFS_AddRootTargetCMD, Exitcode
		
	For counter = 0 To UBound(DFS_Array)	
		DFS_AddRootTargetCMD = ("dfsutil target add \\" & NewDC1 & "\" & DFS_Array(counter))
		WScript.echo ("Running: " & DFS_AddRootTargetCMD)
		'Exitcode = objShell.Run ("%comspec% /k" & DFS_AddRootTargetCMD,1, True)
		Exitcode = objShell.Run (DFS_AddRootTargetCMD,1, True)
		
		If Exitcode <>0 Then 
			WScript.Echo "Error running DFSUtil. Exit code: " & Exitcode
		Else
			WScript.Echo "Succes running DFSUtil"
		End If
	Next
	
	Set objShell = Nothing
End Sub 'Add_Root_Target

Sub Remove_Root_Target
	Dim counter : counter = 0
	Dim DFS_RemoveRootTargetCMD, Exitcode
	
	For counter = 0 To UBound(DFS_Array)	
		DFS_RemoveRootTargetCMD = ("dfsutil target remove \\" & OldDC1 & "\" & DFS_Array(counter))
		WScript.echo ("Remove: " & DFS_RemoveRootTargetCMD)
		Exitcode = objShell.Run (DFS_RemoveRootTargetCMD,0,True)
		
		If Exitcode <>0 Then 
			WScript.Echo "Error running DFSUtil. Exit code: " & Exitcode
		Else
			WScript.Echo "Succes running DFSUtil"
		End If
	Next
	
	Set objShell = Nothing
End Sub 'Remove_Root_Target



