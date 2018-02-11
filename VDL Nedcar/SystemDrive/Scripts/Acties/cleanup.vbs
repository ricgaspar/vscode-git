'*******************************************************************************
'
' Script: CLEANUP.VBS
' Author: Marcel Jussen
' Version: 2.1.11 (29-3-2013)
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

'------- SET VALUE TO TRUE For DEBUGGING PURPOSES ------------------------

Const blDEBUG = False

'------- SET VALUE TO TRUE For DEBUGGING PURPOSES ------------------------

Const ForReading = 1, ForWriting = 2, ForAppending = 8
Const cSpacer = "   "
Const cReq    = "-> "
Const cWarn   = "@@ "
Const cErr    = "** "

Const cLOGFILE        = 0
Const cFILE           = 1
Const cFILES          = 2
Const cFOLDERS        = 4
Const cALLCONTENT     = 8 ' NOT USED
Const cFOLDER         = 16
Const cWUARCHIVES     = 32
Const cZIP            = 64
Const cZIPFOLDER      = 128
Const cZIP_FOLDERS    = 256
Const cZIP_SNGLFLS    = 512

Const strOpt_LOGFILE      = "$LOGFILE$"
Const strOpt_FILE         = "$FILE$"
Const strOpt_FILES        = "$FILES$"
Const strOpt_FOLDER       = "$FOLDER$"
Const strOpt_FOLDERS      = "$FOLDERS$"
Const strOpt_ALLCONTENT   = "$ALLCONTENT$"
Const strOpt_WUARCHIVES   = "$UDPATEARCHIVES$"
Const strOpt_FILEZIP      = "$ZIPFILES$"
Const strOpt_FOLDERZIP    = "$ZIPFILESFOLDERS$"
Const strOpt_FOLDERS_ZIP  = "$ZIPSUBFOLDERSONLY$"
Const strOpt_SNGLFLS_ZIP  = "$ZIPSINGLEFILES$"

Const cARCHIVE        = "archive.zip"

' Open Cleanup log and append messages.
Dim strLogFileName, strLogFileMode
Dim objFSOlog, fsoLog
Set objFSOlog = CreateObject("Scripting.FileSystemObject")

Dim dblTimerGlb, dblTimer
Dim nFlsScanned, nFldrScanned
Dim nFlsDeleted, nFldrDeleted
Dim nFlsAttempted, nFldrAttempted
Dim nFlsError, nFldrError

nFlsScanned = 0
nFldrScanned = 0
nFlsDeleted = 0
nFlsError = 0
nFlsAttempted = 0
nFldrDeleted = 0
nFldrError = 0
nFldrAttempted = 0

Call main()

' bye bye..
fsoLog.close()
wscript.quit()

Sub Main
	Dim objArgs, strPath, strConfigFile

	' Start Cleanup wih default logfile
	Call CreateLogFile("","")

	dblTimerGlb = Timer()

	Set objArgs = WScript.Arguments
	If objArgs.Count >= 1 then
		strConfigFile = objArgs(0)
	Else
		strPath = Mid(wscript.scriptfullname, 1, InStr(wscript.scriptfullname, wscript.scriptname)-1)
		strConfigFile = strPath & "cleanup.ini"
	End If

	PrintMess String(70,"-")
	Call ParseConfigFile(strConfigFile)

	PrintMess String(70,"-")
	PrintMess "Statistics."
	PrintMess String(70,"-")
	PrintMess "Folders scanned             : " & CStr(nFldrScanned)
	PrintMess "Folders attempted to delete : " & CStr(nFldrAttempted)
	printMess "Folders actually deleted    : " & CStr(nFldrDeleted)
	If nFldrError>0 Then
		PrintMess ""
		PrintMess cSpacer & String(70,"*")
		PrintMess "Folders failed to delete : " & CStr(nFldrError)
		PrintMess cSpacer & String(70,"*")
		PrintMess ""
		PrintMess String(70,"*")
	End If

	PrintMess ""
	PrintMess "Files scanned               : " & CStr(nFlsScanned)
	PrintMess "Files attempted to delete   : " & CStr(nFlsAttempted)
	PrintMess "Files actually deleted      : " & CStr(nFlsDeleted)
	If nFlsError>0 Then
		PrintMess ""
		PrintMess cSpacer & String(70,"*")
		PrintMess cSpacer & "Files failed to delete : " & CStr(nFlsError)
		PrintMess cSpacer & String(70,"*")
		PrintMess ""
	End If

	PrintMess String(70,"-")
	PrintMess "Script running time: " & PrintTimer(dblTimerGlb)
	PrintMess "Cleanup procedure ended."
	PrintMess String(70,"=")
End Sub

Function CreateLogFile(strAltLogFile, strAltLogFileMode)
	Dim strDate
	If Len(strAltLogFile)<=0 Then
		' Logfile can be set by declaring a system environment variable CleanupLog.
		strLogFileName=ExpandVar("%CleanupLog%")
		' Determine log file append/overwrite modus
		strLogFileMode=UCase(ExpandVar("%CleanupLogMode%"))

		' Default name for the logfile if the environment variable does not exist.
		strDate=CStr(Now())
		strDate=Replace(strDate, "-","")
		strDate=Replace(strDate, ":","")
		strDate=Replace(strDate, "/"," ")
		strDate=Replace(strDate, " ","-")
		If Len(strLogFileName)<=0 Then strLogFileName="cleanup-" & strDate & ".log"
	Else
		PrintMess "All loging is diverted to alternate logfile: " & strAltLogFile
		PrintMess String(70,"=")
		strLogFileName=strAltLogFile
		strLogFileMode=strAltLogFileMode
	End If

	' Default mode for the logfile is to overwrite the file
	If (Len(strLogFileMode)<=0) Then
		Wscript.echo strLogFileName
		Set fsoLog=objFSOlog.CreateTextFile(strLogFileName)
	Else
		If (InStr(strLogFileMode, "APPEND")>0) Then
			Set fsoLog=objFSOlog.OpenTextFile(strLogFileName, ForAppending, True)
		End If
		If (InStr(strLogFileMode, "OVERWRITE")>0) Then
			Set fsoLog=objFSOlog.CreateTextFile(strLogFileName)
		End If

		If (InStr(strLogFileMode, "APPEND")<=0) And (InStr(strLogFileMode, "OVERWRITE")<=0) Then
			Set fsoLog=objFSOlog.CreateTextFile(strLogFileName)
		End If
	End If

	PrintMess String(70,"=")
	PrintMess "Cleanup procedure is started. Logging output: " & strLogFileMode
	If blDEBUG Then
			PrintMess String(70,"-")
			PrintMess ""
			PrintMess "  *** No files are actually deleted. blDEBUG=True ***"
			PrintMess ""
			PrintMess String(70,"-")
	End If

End Function

Function ParseConfigFile(strConfigFile)
	Dim intFolder, intTextLinenr, intPos
	Dim objFSO, fsoCfg, intOptions, strBuf
	Dim strTextLine, strText, strOption, strFoldername, strAge, strMask, intAge, strKeep, intKeep
	Dim arrRecord

	Printmess "Config.file: " & strConfigFile
	PrintMess String(70,"-")

	set objFSO = CreateObject("Scripting.FileSystemObject")
	If objFSO.FileExists(strConfigFile) Then
		Set fsoCfg=objFSO.OpenTextFile(strConfigFile, ForReading, True)
		Do While fsoCfg.AtEndOfStream <> True
			' Read line from config file
			strTextLine = fsoCfg.Readline()
			strBuf = Trim(strTextLine)
			intTextLineNr = intTextLineNr + 1

			' Strip comments from line
			intPos = InStr(strTextLine, ";")
			If intPos>1 Then strTextLine=Mid(strTextLine,1,intPos-1)
			If intPos=1 Then strTextLine=""
			strText = Trim(strTextLine)
			strBuf = strText

			' Skip empty lines
			If Len(strText) > 0 Then

				strOption=""
				strFolderName=""
				strAge=""
				strMask=""
				strKeep=""

				' Create array of option line text
				arrRecord = split(strText, ",")
				' Retrieve mandatory options
				If UBound(arrRecord) >= 2 Then

					' Mandatory!!!
					strOption = Trim(arrRecord(0))
					strFolderName = Trim(arrRecord(1))
					strAge = Trim(arrRecord(2))

					PrintMess String(70,"-")
					If blDebug Then PrintMess cReq & "Option   : [" & strOption & "]"
					If blDebug Then PrintMess cReq & "Name     : [" & strFolderName & "]"
					If blDebug Then PrintMess cReq & "Max age  : [" & strAge & "]"

					If UBound(arrRecord) >= 3 Then
						strMask = Trim(arrRecord(3))
						If StrComp(strMask, "*", vbTextCompare)=0 Then strMask=""
						If StrComp(strMask, "*.*", vbTextCompare)=0 Then strMask=""
						If Len(strMask)>0 Then
							If blDebug Then PrintMess cReq & "Mask:   [" & strMask & "]"
						End if
					Else
						If blDebug Then PrintMess cReq & "Mask     : not used."
					End If

					intKeep=-1
					If UBound(arrRecord) >= 4 Then
						strKeep = Trim(arrRecord(4))
						If blDebug Then PrintMess cReq & "Keep:   [" & strKeep & "]"

						On Error Resume Next
						intKeep=CInt(strKeep)
						If Err.Number<>0 Then
							Call PrintError("Parse error in line #" & CStr(intTextLineNr) & ": " & strTextLine,"Keep value not numerical!")
							intKeep=-1
							err.clear()
						End If
						On Error GoTo 0
					Else
						If blDebug Then PrintMess cReq & "Keep     : not used."
					End If
				Else
					Call PrintError("Parse error in line #" & CStr(intTextLineNr) & ": " & strTextLine,"Mandatory options in line are not met!")
				End If

				If Len(strOption)>0 And Len(strFolderName)>0 And Len(strAge)>0 Then
					If blValidCommand(strOption) Then
						On Error GoTo 0
						strFoldername = ExpandVar(strFoldername)

						intOptions = -1
						Select Case strOption
							Case strOpt_LOGFILE
								intOptions = cLOGFILE
							Case strOpt_FILE
								intOptions = cFILE
							Case strOpt_FILES
								intOptions = cFILES
							Case strOpt_FOLDERS
								intOptions = cFOLDERS
							Case strOpt_ALLCONTENT
								intOptions = cALLCONTENT
							Case strOpt_FOLDER
								intOptions = cFOLDER
							Case strOpt_WUARCHIVES
								intOptions = cWUARCHIVES
							Case strOpt_FILEZIP
									intOptions = cZIP
							Case strOpt_FOLDERZIP
								intOptions = cZIPFOLDER
							Case strOpt_FOLDERS_ZIP
								intOptions = cZIP_FOLDERS
							Case strOpt_SNGLFLS_ZIP
								intOptions = cZIP_SNGLFLS
							Case Else
								PrintMess "Nothing to do. Option " & strOption & " is not implemented yet."
						End Select

						intAge=-1
						If intOptions <> cLOGFILE Then
							On Error Resume Next
							intAge=CInt(strAge)
							If Err.Number<>0 Then
								Call PrintError("Parse error in line #" & CStr(intTextLineNr) & ": " & strTextLine,"Age value not numerical!")
								intAge=-1
								err.clear()
							End If
							On Error GoTo 0
						End If

						If intOptions>0 And intAge>=0 Then
							Call Cleanup(intOptions, strFoldername, intAge, strMask, intKeep)
						Else
							If intOptions = cLOGFILE Then
								Call CreateLogFile(strFolderName, strAge)
								Printmess "Using configuration file " & strConfigFile
							End If
						End If

					Else
						PrintMess "Option " & strOption & " is unknown."
					End If
				Else
					Call PrintError("Parse error in line #" & CStr(intTextLineNr) & ": " & strTextLine, "Invalid or unknown option was used!")
				End If
			End If
		Loop
		fsoCfg.close()
	Else
		Call PrintError(strConfigFile & " was not found!","Script aborted.")
	End If
End Function

Function blValidCommand(strOption)
	Dim blResult
	strOption = Trim(strOption)
	Select Case strOption
		Case strOpt_LOGFILE
			blResult = True
		Case strOpt_FILE
			blResult = True
		Case strOpt_FILES
			blResult = True
		Case strOpt_FOLDER
			blResult = True
		Case strOpt_FOLDERS
			blResult = True
		Case strOpt_ALLCONTENT
			blResult = True
		Case strOpt_WUARCHIVES
			blResult = True
		Case strOpt_FILEZIP
			blResult = True
		Case strOpt_FOLDERZIP
			blResult = True
		Case strOpt_FOLDERS_ZIP
			blResult = True
		Case strOpt_SNGLFLS_ZIP
			blResult = True
		Case Else
			blResult = False
	End Select
	blValidCommand = blResult
End Function


Sub CleanUp(intOptions, strCleanupFolder, intMaxAge, strMask, intKeep)
	Dim objCurrFolder, intBound
	Dim objFilesList, objSubFoldersList, objSubFolder
	Dim objFile, objFolder, strFilename, strFilepath
	Dim objBaseFolder, objBaseSubFolderList, strFoldername
	Dim strBaseFolder, objBaseSubFolder
	Dim intAge, objFSO, objFSOtemp, intError
	Dim intAttributes, intFilesCount, intSubFoldersCount
	Dim strZIPfile, strCleanupFile
	Dim kTemp, strNameMask, nChecked
	Dim arrFiles, arrFolders, strFolderpath
	Dim dictObj, arrTemp, nCount, bCheck
	Dim strHistoryFolder

	If Len(Trim(strCleanupFolder)) > 0 Then
		Set objFSO = CreateObject("Scripting.FileSystemObject")

		If StrComp(Right(strCleanupFolder,1),"\")=0 Then strCleanupFolder=Left(strCleanupFolder, Len(strCleanupFolder)-1)

		' Check if folder exists
		If objFSO.folderexists(strCleanupFolder) Then

			On Error Resume Next
			'Retrieve folder
			Set objCurrFolder = objFSO.GetFolder(strCleanupFolder)
			intError = err.number
			If intError <> 0 Then PrintError "An error occurred while opening a folder.", CStr(intError)
			err.clear()

			'Create file collection of this folder
			set objFilesList = objCurrFolder.files
			intFilesCount = objFilesList.count
			intError = err.number
			If intError <> 0 Then
				PrintError "An error occurred while retrieving a files collection.", CStr(intError)
				err.clear()
				intFilesCount=-1
			Else
				nFlsScanned = nFlsScanned + intFilesCount
			End If

			'Create sub-folder collection of this folder
			set objSubFoldersList = objCurrFolder.subfolders
			intSubFoldersCount = objSubFoldersList.count
			intError = err.number
			If intError <> 0 Then
				PrintError "An error occurred while retrieving a folders collection.", CStr(intError)
				err.clear()
				intSubFoldersCount=-1
			Else
				nFldrScanned = nFldrScanned + intSubFoldersCount
			End If

			PrintMess cReq & "Cleanup started in: [" & strCleanupFolder & "]"
			PrintMess cSpacer & "Directory scan found " & CStr(intFilesCount) & " files and " & CStr(intSubFoldersCount) & " subfolders."

			If (intFilesCount <= 0) And (intSubFoldersCount <= 0) Then
				PrintMess cSpacer & "Nothing to do."
				Exit Sub
			End If
			
			' Create array of option line strMask
			Dim arrMasks
			arrMasks = split(strMask, Chr(32))
			If UBound(arrMasks)>=0 and Len(strMask)>0 Then
				PrintMess cSpacer & "Names mask: " & strMask
			End If

			intOptions = CInt(intOptions)
			If (intOptions And cFILES) Then
				' -------------------------------------------------------
				' Cleanup files in a folder and subfolders by age.

				PrintMess cSpacer & "$FILES$: Deleting files in folder."
				If intMaxAge >= 0 Then PrintMess cSpacer & "Maximum age: " & CStr(intMaxAge) & " days."
				If intKeep > 0 Then PrintMess cSpacer & "Must keep newest files: " & CStr(intKeep)

				If intFilesCount>0 Then
					nCount = 0					
					ReDim arrTemp(objFilesList.count,2)					
					For each dictObj in objFilesList
						arrTemp(nCount, 0) = dictObj.path
						arrTemp(nCount, 1) = Int(Date - dictObj.DateLastModified)+1						
						nCount = nCount + 1
					Next

					If intKeep>0 Then						
						arrFiles = SortArrayDesc(arrTemp)
					Else
						arrFiles = arrTemp
					End If

					'If blDEBUG Then
					'	PrintMess cSpacer & "[listing sorted array] "
					'	For nTemp = 0 To UBound(arrFiles,1)-1
					'		PrintMess cSpacer & "[sorted] " & arrFiles(nTemp,0) & vbTAb & CStr(arrFiles(nTemp,1))
					'	Next
					'	PrintMess cSpacer & "[done listing sorted array] "
					'End If

					' Adjust for array boundary
					intBound=0
					If intKeep>0 Then intBound=intKeep+1
					If intKeep<=0 Then intBound=1

					Dim nTemp
					For nTemp = 0 To UBound(arrFiles,1)-intBound
						strFilepath = arrFiles(nTemp,0)
						intAge = arrFiles(nTemp,1)

						If blDEBUG Then PrintMess cReq & "   Filepath: " & strFilePath & " (" & CStr(intAge) & " days)"

						' get filename from filepath
						Set objFile = objFSO.GetFile(strFilepath)
						strFilename = objFile.name

						If blDEBUG Then PrintMess cReq & "   Filename: " & strFilename

						' Skip own logfile.
						If StrComp(UCase(strFilepath), UCase(strLogFileName))=0 Then
								If blDEBUG Then PrintMess cReq & strLogFileName & " is skipped."
						Else
							'Check ik masks are included
							If UBound(arrMasks)>=0 and Len(strMask)>0 Then
								nChecked = 0
								For kTemp = 0 to UBound(arrMasks)
									strNameMask = arrMasks(kTemp)

									' Check what the mask must be used for
									If StrComp(Left(strNameMask,1), "-") = 0 Then
										If blDEBUG Then PrintMess cReq & "   Exclusion name mask: " & strNameMask
										strNameMask=Mid(strNameMask,2)
										If InStr(UCase(strFileName), UCase(strNameMask)) > 0 Then
											nChecked = nChecked - 1
											PrintMess cSpacer & "Do not include:" & strNameMask & cSpacer & strFilename & vbTab & CStr(nChecked)
										End If
									Else
										If blDEBUG Then PrintMess cReq & "   Inclusion name mask: " & strNameMask
										If InStr(UCase(strFilename), UCase(strNameMask)) > 0 Then
											nChecked = nChecked + 1
											PrintMess cSpacer & "Include:" & strNameMask & cSpacer & strFilename & vbTab & CStr(nChecked)
										 Else
											If blDEBUG Then PrintMess cReq & "   Mask not found in filename."
										End If
									End If
								Next
								If nChecked > 0 Then Call DeleteFile(strFilepath, intAge, intMaxAge)
							Else
								' There are no selection masks.
								Call DeleteFile(strFilepath, intAge, intMaxAge)
							End If
						End If
					Next
				Else
					PrintMess cSpacer & "No files found to delete."
				End If

				' Recurse all subfolders
				For each objSubFolder in objSubFoldersList
					Call CleanUp(cFILES, objSubFolder.path, intMaxAge, strMask, intKeep)
				Next
			End If

			'-------------------------------------------------------
			' Cleanup folders in a folder by age
			If(intOptions And cFOLDERS) Then
				PrintMess cSpacer & "$FOLDERS$: Deleting subfolders in folder " & strCleanupFolder
				If intMaxAge >= 0 Then PrintMess cSpacer & "Maximum age: " & CStr(intMaxAge) & " days."
				If intKeep > 0 Then PrintMess cSpacer & "Must keep newest files: " & CStr(intKeep)				

				If intSubFoldersCount>0 Then
					nCount = 0
					ReDim arrTemp(objSubFoldersList.count,2)
					'If blDEBUG Then PrintMess cReq & "Unsorted array."
					For each dictObj in objSubFoldersList
						arrTemp(nCount, 0) = dictObj.path
						arrTemp(nCount, 1) = Int(Date - dictObj.DateLastModified)+1
						' If blDEBUG Then PrintMess cReq & arrTemp(nCount, 0) & vbTAb & arrTemp(nCount, 1)
						nCount = nCount + 1
					Next

					If intKeep>0 Then
						arrFolders = SortArrayDesc(arrTemp)
					Else
						arrFolders = arrTemp
					End If

					'Check results of sort
					'If blDEBUG Then
					'	PrintMess cSpacer & "[listing sorted array] "
					'	For nTemp = 0 To UBound(arrFolders,1)-1
					'		PrintMess cSpacer & "[sorted] " & arrFolders(nTemp,0) & vbTAb & CStr(arrFolders(nTemp,1))
					'	Next
					'	PrintMess cSpacer & "[done listing sorted array] "
					'End If

					' Adjust for array boundary
					intBound=0
					If intKeep>0 Then intBound=intKeep+1
					If intKeep<=0 Then intBound=1

					For nTemp = 0 To UBound(arrFolders,1)-intBound
						strFolderpath = arrFolders(nTemp,0)
						intAge = arrFolders(nTemp,1)

						If blDEBUG Then PrintMess cReq & "   Folder path: " & strFolderPath & " (" & CStr(intAge) & " days)"
						Set objFolder = objFSO.GetFolder(strFolderPath)
						strFoldername = objFolder.name

						' Check if a name mask is applied.
						If UBound(arrMasks)>=0 Then
							bCheck = CheckMask(strFoldername, arrMasks)
						Else
							bCheck = True
						End If
						If bCheck Then Call DeleteFolder(strFolderPath, intAge, intMaxAge)
					Next
				Else
					PrintMess cSpacer & "No subfolders found to delete."
				End If
			End If

			'-------------------------------------------------------
			' Cleanup contents of a folder by age
			If (intOptions And cALLCONTENT) Then
				PrintMess cSpacer & "$ALLCONTENT$: Deleting all contents in folder " & strCleanupFolder
				If Not (objCurrFolder.IsRootFolder) Then
					Call CleanUp(cFILES, strCleanupFolder, intMaxAge, strMask, intKeep)
					Call CleanUp(cFOLDERS, strCleanupFolder, intMaxAge, strMask, intKeep)
				Else
					PrintMess cSpacer & "Folder " & strCleanupFolder & " is a root folder!. Skipped"
				End If
			End If

			'-------------------------------------------------------
			If (intOptions And cFOLDER) And Not (objCurrFolder.IsRootFolder) Then
				' Delete the contents of a folder and the folder itself by age
				PrintMess cSpacer & "$FOLDER$: Deleting folder " & strCleanupFolder & " if older than " & CStr(intMaxAge) & " days."
				intAge=Int(Date - objCurrFolder.DateLastModified)				
				Call DeleteFolder(strCleanupFolder, intAge, intMaxAge)
			End If

			'-------------------------------------------------------
			If(intOptions And cWUARCHIVES) Then
				' Cleanup archive/update folders
				PrintMess cSpacer & "$UDPATEARCHIVES$: Deleting WU archive folders in folder " & strCleanupFolder
				For each objSubFolder in objSubFoldersList
					intAttributes = objSubFolder.attributes
					' Check foldername if it as an archive folder
					If blValidArchiveFolder(objSubFolder.name) Then
						intAge=Int(Date - objSubFolder.DateLastModified)
						strFoldername = strCleanupFolder & "\" & objSubFolder.name
						Call DeleteFolder(strFoldername, intAge, intMaxAge)
					End If
				Next
			End If

			'-------------------------------------------------------
			If(intOptions And cZIP) Then
				' ZIP contents of folder
				PrintMess cSpacer & "$ZIPFILES$: Move contents of folder " & strCleanupFolder & " into ZIP archive."
				If Not (objCurrFolder.IsRootFolder) Then
					strFoldername = strCleanupFolder
					strZIPfile = strFoldername & "\" & cARCHIVE
					Call FileZip(strFoldername, strZIPfile, intMaxAge, strMask, "M")
				Else
					PrintMess cSpacer & "Folder " & strCleanupFolder & " is a root folder!. Skipped"
				End If
			End If

			'-------------------------------------------------------
			If(intOptions And cZIPFOLDER) Then
				' ZIP contents of folder and subfolders
				PrintMess cSpacer & "$ZIPFILESFOLDERS$: Move all contents of folder " & strCleanupFolder & " and all subfolders into ZIP archive."
				If Not (objCurrFolder.IsRootFolder) Then
					strFoldername = strCleanupFolder
					strZIPfile = strFoldername & "\" & cARCHIVE
					Call FileZip(strFoldername, strZIPfile, intMaxAge, strMask, "M -r")
				Else
					PrintMess cSpacer & "Folder " & strCleanupFolder & " is a root folder!. Skipped"
				End If
			End If

			'-------------------------------------------------------
			If (intOptions And cZIP_FOLDERS) Then
				If Not (objCurrFolder.IsRootFolder) Then
					' ZIP contents of subfolders
					PrintMess cSpacer & "$ZIPSUBFOLDERSONLY$: Move all contents of subfolders " & strCleanupFolder & " into ZIP archive per subfolder."
					Set objBaseFolder=objFSO.GetFolder(strCleanupFolder)
					set objBaseSubFolderList=objBaseFolder.subfolders
					intSubFoldersCount = objBaseSubFolderList.count
					If intSubFoldersCount > 0 Then
						For each objBaseSubFolder in objBaseSubFolderList
							strFoldername = UCase(strCleanupFolder & "\" & objBaseSubFolder.name)
							strZIPfile = strFoldername & "\" & cARCHIVE
							Call FileZip(strFoldername, strZIPfile, intMaxAge, strMask, "M -r")
						Next
					Else
						PrintMess cSpacer & "No subfolders found!"
					End If
				End If
			End If
			
			'-------------------------------------------------------
			If (intOptions And cZIP_SNGLFLS) Then
				If Not (objCurrFolder.IsRootFolder) Then
					' ZIP contents of single file located in a folder to a single zip file in that same folder
					PrintMess cSpacer & "$ZIPSINGLEFILES$: Zip files in " & strCleanupFolder & " into a ZIP archive per file."
					
					strHistoryFolder = strCleanupFolder & "\history"						
					If Not objFSO.folderexists(strHistoryFolder) Then					
						PrintMess cSpacer & "Creating history folder."
						objFSO.CreateFolder(strHistoryFolder)						
						If Not (objFSO.folderexists(strHistoryFolder)) Then
							PrintMess cErr & "History folder could not be created. Abort."
							Exit Sub
						End If
					End If					
					
					nCount = 0					
					ReDim arrTemp(objFilesList.count,2)					
					For each dictObj in objFilesList
						arrTemp(nCount, 0) = dictObj.path
						arrTemp(nCount, 1) = Int(Date - dictObj.DateLastModified)+1						
						nCount = nCount + 1
					Next
					arrFiles = arrTemp
																				
					For nTemp = 0 To UBound(arrFiles,1)-1
						strFilepath = arrFiles(nTemp,0)
						intAge = arrFiles(nTemp,1)

						If blDEBUG Then PrintMess cReq & "   Filepath: " & strFilePath & " (" & CStr(intAge) & " days)"

						' get filename from filepath
						Set objFile = objFSO.GetFile(strFilepath)
						strFilename = objFile.name

						If blDEBUG Then PrintMess cReq & "   Filename: " & strFilename

						' Skip own logfile.
						If StrComp(UCase(strFilepath), UCase(strLogFileName))=0 Then
								If blDEBUG Then PrintMess cReq & strLogFileName & " is skipped."
						Else
							'Check ik masks are included
							If UBound(arrMasks)>=0 and Len(strMask)>0 Then
								nChecked = 0
								For kTemp = 0 to UBound(arrMasks)
									strNameMask = arrMasks(kTemp)

									' Check what the mask must be used for
									If StrComp(Left(strNameMask,1), "-") = 0 Then
										If blDEBUG Then PrintMess cReq & "   Exclusion name mask: " & strNameMask
										strNameMask=Mid(strNameMask,2)
										If InStr(UCase(strFileName), UCase(strNameMask)) > 0 Then
											nChecked = nChecked - 1
											PrintMess cSpacer & "Do not include:" & strNameMask & cSpacer & strFilename & vbTab & CStr(nChecked)
										End If
									Else
										If blDEBUG Then PrintMess cReq & "   Inclusion name mask: " & strNameMask
										If InStr(UCase(strFilename), UCase(strNameMask)) > 0 Then
											nChecked = nChecked + 1
											PrintMess cSpacer & "Include:" & strNameMask & cSpacer & strFilename & vbTab & CStr(nChecked)
										 Else
											If blDEBUG Then PrintMess cReq & "   Mask not found in filename."
										End If
									End If
								Next
								If nChecked > 0 Then 									
									Call FileSnglZip(strHistoryFolder, strFilePath)
								End If
							Else
								' There are no selection masks.
								PrintMess cSpacer & "There is no selection mask. Cannot continue."
							End If
						End If
					Next
										
				End If
			End If

		Else
			PrintMess cSpacer & "*** Folder does not exist: " & strCleanupFolder
			strCleanupFile = strCleanupFolder
			'-------------------------------------------------------
			' Delete a single file
			If (intOptions And cFILE) Then
				PrintMess cSpacer & "$FILE$: Delete a single file."
				PrintMess cSpacer & "Delete file " & strCleanupFile
				If (objFSO.FileExists(strCleanupFile)) Then
					Set objFile = objFSO.GetFile(strCleanupFile)
					intAge = Int(Date - objFile.DateLastModified)
					Call DeleteFile(strCleanupFile, intAge, intMaxAge)
				Else
					PrintMess cSpacer & "*** File does not exist: " & strCleanupFile
				End If
			End If			
			
		End If
		PrintMess cReq & "Cleanup ended for: [" & strCleanupFolder & "]"
	End If
End Sub

Function CheckMask(strPath, arrMasks)
	Dim bResult, nChecked, kTemp, strNameMask

	bResult = False

	nChecked = 0
	If UBound(arrMasks)>=0 Then
		For kTemp = 0 to UBound(arrMasks)
			strNameMask = arrMasks(kTemp)

			' Check what the mask must be used for
			If StrComp(Left(strNameMask,1), "-") = 0 Then
				strNameMask=Mid(strNameMask,2)
				If blDEBUG Then PrintMess cReq & "   Exclusion name mask: " & strNameMask

				If InStr(UCase(strPath), UCase(strNameMask)) > 0 Then
					nChecked = nChecked - 1
					PrintMess cSpacer & "Do not include:" & strNameMask & cSpacer & strPath & vbTab & CStr(nChecked)
				Else
					nChecked = nChecked + 1
				End If

			Else

				If blDEBUG Then PrintMess cReq & "   Inclusion name mask: " & strNameMask
				If InStr(UCase(strPath), UCase(strNameMask)) > 0 Then
					nChecked = nChecked + 1
					PrintMess cSpacer & "Include:" & strNameMask & cSpacer & strPath & vbTab & CStr(nChecked)
				Else
					nchecked = nChecked - 1
				End If

			End If
		Next
		If blDEBUG Then PrintMess cReq & "Check val: " & CStr(nChecked)
	End If
	bResult = (nChecked > 0)
	CheckMask = bResult
End Function

Function DeleteFile(strFullFilePath, intAge, intMaxAge)
	Dim objFSO, intError
	intError=0

	On Error Resume Next
	If intAge >= intMaxAge Or IntMaxAge<=0 Then
		nFlsAttempted = nFlsAttempted + 1
		Set objFSO = CreateObject("Scripting.FileSystemObject")
		' Delete file forcefully.

		If Not blDEBUG Then
			PrintMess cWarn & "Deleting file " & strFullFilePath & " (" & CStr(intAge) & " days)"
			objFSO.deletefile strFullFilePath, True
			intError = err.number
			err.clear()
			On Error GoTo 0

			If intError<>0 Then
				Call PrintError("Deleting file " & strFullFilePath & " failed!", "Return value: #", CStr(intError))
				nFlsError = nFlsError + 1
			Else
				PrintMess cSpacer & "Deleting file " & strFullFilePath & " succeeded."
				nFlsDeleted = nFlsDeleted + 1
			End If
		Else
			PrintMess cWarn & "Deleting file " & strFullFilePath & " (" & CStr(intAge) & " days) DEBUG MODE:not deleted"
		End If
	End If

	DeleteFile = intError
End Function

Function DeleteFolder(strFullFolderPath, intAge, intMaxAge)
	Dim objFSO, intError
	intError=0
	If intAge >= intMaxAge Or IntMaxAge<=0 Then
		nFldrAttempted = nFldrAttempted + 1
		Set objFSO = CreateObject("Scripting.FileSystemObject")
		If Not blDEBUG Then
			PrintMess cWarn & "Deleting folder " & strFullFolderPath & " (" & CStr(intAge) & " days)"
			On Error Resume Next
			objFSO.DeleteFolder strFullFolderPath, True
			intError = err.number
			err.clear()
			If intError<>0 Then
				Call PrintError("Deleting folder " & strFullFolderPath & " failed!", "Return value: #", CStr(intError))
			Else
				PrintMess cSpacer & "Deleting folder succeeded."
				nFldrDeleted = nFldrDeleted + 1
			End If
			On Error GoTo 0
		Else
			PrintMess cWarn & "Deleting folder " & strFullFolderPath & " (" & CStr(intAge) & " days) DEBUG MODE:not deleted"
			intError=-1
		End If
	Else
		' PrintMess cSpacer & strFullFolderPath & " is " & intAge & " days old. Skipped"
	End If
	DeleteFolder = intError
End Function

Function FileZip(strFoldername, strZIPfile, intMaxAge, strMask, strAction)
	Dim wshShell, strCommand, dMaxDate, strMaxDate
	Dim objFSO
	
	On Error GoTo 0

	set objFSO = CreateObject("Scripting.FileSystemObject")
	PrintMess cSpacer & "Folder to process : " & strFoldername
	If objFSO.folderexists(strFoldername) Then
		If Len(strMask)>0 Then
			strFoldername = strFoldername & "\" & strMask
		Else
			strFoldername = strFoldername & "\*.*"
		End If

		strFoldername = QuoteFileName(strFoldername)
		strZIPfile = QuoteFileName(strZIPfile)

		If blDebug Then PrintMess cReq & "Archive file      : " & strZIPfile
		If blDebug Then PrintMess cReq & "Max age           : " & CStr(intMaxAge)
		If blDebug Then PrintMess cReq & "Action command    : " & strAction

		' create shell and run command in RUNAS environment.
		strMaxDate = ""		
		dMaxDate = (Date - intMaxAge)		
		strMaxDate = CStr(Year(dMaxDate)) + "-" 
		
		dim dTemp
		dTemp = CStr(Month(dMaxDate))
		if(Len(dTemp)<2) then dTemp = "0" + dTemp
		strMaxDate = strMaxDate + dTemp + "-"
		
		dTemp = CStr(Day(dMaxDate))
		if(Len(dTemp)<2) then dTemp = "0" + dTemp
		strMaxDate = strMaxDate + dTemp		
		
		If(Len(strMaxDate)>0) Then
			strCommand = "C:\Program Files\Winrar\winrar.exe"
			strCommand = QuoteFileName(strCommand)
			strCommand = strCommand + " " & strAction & _
							 " -tb" & strMaxDate & _
							 " -ilogC:\Logboek\winrar.log -inul " & _ 
							 strZIPfile & " " & strFoldername 							 
		End If

		If Not blDEBUG Then
			PrintMess "Executing: " + strCommand
			set wshShell = CreateObject("WScript.Shell")
			Call wshShell.run(strCommand, 0, True)
		Else 
			PrintMess "DEBUG: " + strCommand
		End If
	Else
		PrintMess "INFO: " & strFoldername & " does not exist."
	End If

End Function

Function FileSnglZip(strHistoryFolder, strFilePath)
	Dim wshShell, strCommand, strBasename, strAction, strMaxDate
	Dim objFSO, objFile, strFilename, strZIPfile		
	
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFSO.GetFile(strFilePath)	
	
	strFilename = objFSO.GetFileName(objFile)
	strBasename = objFSO.GetBaseName(objFile)
	strZIPFile = strHistoryFolder & "\" & strBasename & ".zip"
	
	PrintMess cSpacer & "File to process        : " & strFilePath	
	strAction = " M -ep "
	
	If objFSO.FileExists(strFilePath) Then		

		strFilename = QuoteFileName(strFilename)
		strZIPfile = QuoteFileName(strZIPfile)

		PrintMess cSpacer & "Folder to move zip into: " & strHistoryFolder									
			
		strCommand = "C:\Program Files\Winrar\winrar.exe"
		strCommand = QuoteFileName(strCommand)
		strCommand = strCommand & strAction & "-ilogC:\Logboek\winrar.log -inul " & strZIPfile & " " & strFilePath
		
		PrintMess cSpacer & "Archive file           : " & strZIPfile							
		
		If Not blDEBUG Then
			PrintMess "Executing: " + strCommand
			set wshShell = CreateObject("WScript.Shell")
			Call wshShell.run(strCommand, 0, True)
		End If
	Else
		PrintMess "INFO: " & strFilePath & " does not exist."
	End If
	
End Function

Function QuoteFileName(strFilepath)
	strFilepath = Trim(strFilepath)
	If Mid(strFilepath,1,1) <> Chr(34) Then strFilepath = Chr(34) & strFilepath
	If Mid(strFilepath, Len(strFilepath),1) <> Chr(34) Then strFilepath = strFilepath & Chr(34)
	QuoteFilename = strFilepath
End Function

Function blValidArchiveFolder(strFoldername)
	Dim blResult
	blResult = False
	strFoldername = UCase(Trim(strFoldername))
	' Archive folders start with $ sign
	If InStr(Left(strFoldername,1), "$")=1 Then
		' Archive folders End with $ sign
		If InStr(Right(strFoldername,1), "$")=1 Then
			' Windows OS patches
			If Not blResult Then blResult = (InStr(strFoldername, "$NTUNINSTALL")=1)
			' Service Pack
			If Not blResult Then blResult = (InStr(strFoldername, "$NTSERVICEPACKUNINSTALL$")=1)
			' SQL, MSI patches
			If Not blResult Then blResult = (InStr(strFoldername, "UNINSTALL")>1)
		End If
	End If
	blValidArchiveFolder = blResult
End Function

Sub PrintMess(strMessage)
	Dim strOutText, nDate, cTime
	nDate = Date()
	cTime = Time()

	strOutText = CStr(Year(nDate))
	strOutText = strOutText & String( 2-Len(CStr(Month(nDate))),"0" ) & CStr(Month(nDate))
	strOutText = strOutText & String( 2-Len(CStr(Day(nDate))),"0" ) & CStr(Day(nDate))
	strOutText = strOutText & "-"
	strOutText = strOutText & String( 2-Len(CStr(Hour(cTime))),"0" ) & CStr(Hour(cTime))
	strOutText = strOutText & String( 2-Len(CStr(Minute(cTime))),"0" ) & CStr(Minute(cTime))
	strOutText = strOutText & String( 2-Len(CStr(Second(cTime))),"0" ) & CStr(Second(cTime))

	strOutText = strOutText & " " & strMessage
	wscript.echo strOutText
	fsoLog.writeline strOutText
End Sub

Sub PrintError(strErrorString, strText)
	PrintMess cERR & "ERROR: " & strErrorString
	PrintMess cERR & "       " & strText
End Sub

Function ExpandVar(strVar)
	Dim strResult, WshShell, WshSysEnv, strEnvVar
	strResult=strVar
	If InStr(strResult, "%")=1 Then
		strResult = Mid(strResult,2)
		If InStr(strResult, "%") > 0 Then
			strEnvVar = Mid(strResult,1, InStr(strResult, "%")-1)
			Set WshShell = WScript.CreateObject("WScript.Shell")
			Set WshSysEnv = WshShell.Environment("PROCESS")
			strResult = WshSysEnv(strEnvVar) & Mid(strResult,InStr(strResult, "%")+1)
		End If
	End If
	ExpandVar = strResult
End Function

Function SortArrayDesc(aTempArray)
	Dim nCount, objFile, nTemp, tmpDict

	On Error GoTo 0

		If blDEBUG Then PrintMess cReq & "Sorting ascending temp array on date last modified."
		Dim iTemp, jTemp, kTemp, strTemp
		For iTemp = 0 To UBound(aTempArray,1)-1
			For jTemp = 0 To iTemp
				If aTempArray(jTemp, 1) < aTempArray(iTemp, 1)Then
					For kTemp = 0 To UBound(aTempArray,2)-1
						strTemp = aTempArray(jTemp, kTemp)
						aTempArray(jTemp,kTemp) = aTempArray(iTemp,kTemp)
						aTempArray(iTemp,kTemp) = strTemp
					Next
				End If
			Next
		Next
		If blDEBUG Then PrintMess cReq & "Done sorting temp array."

	SortArrayDesc = aTempArray
End Function

Function SortArrayAsc(aTempArray)
	Dim nCount, objFile, nTemp, tmpDict

	On Error GoTo 0

		If blDEBUG Then PrintMess cReq & "Sorting descending temp array on date last modified."
		Dim iTemp, jTemp, kTemp, strTemp
		For iTemp = 0 To UBound(aTempArray,1)-1
			For jTemp = 0 To iTemp
				If aTempArray(jTemp, 1) > aTempArray(iTemp, 1)Then
					For kTemp = 0 To UBound(aTempArray,2)-1
						strTemp = aTempArray(jTemp, kTemp)
						aTempArray(jTemp,kTemp) = aTempArray(iTemp,kTemp)
						aTempArray(iTemp,kTemp) = strTemp
					Next
				End If
			Next
		Next
		If blDEBUG Then PrintMess cReq & "Done sorting temp array."

	SortArrayAsc = aTempArray
End Function

Function PrintTimer(byVal dblTimer)
	Dim dblTimer2
	dblTimer2 = Timer()

' Check for the midnight rollover.
	If dblTimer2 < dblTimer Then
		dblTimer2 = dblTimer2 + 86400
	End If

' Call the function that will give us a pretty result.
	PrintTimer = PrintInterval(dblTimer2 - dblTimer)
End Function

Function PrintInterval(byVal dblMilliSecond)
	Dim intMilliSecond, intSecond, intMinute, intHour
	Dim strReturn

	strReturn =""

' Determine the number of milliseconds.
	intMilliSecond = Int(dblMilliSecond*1000) mod 1000

' Determine the number of seconds. This is not the second value
' yet, just the number of seconds.
	intSecond = Int(dblMilliSecond)

' Determine the number of minutes, simply divide the total number
' of seconds by 60 and get the real number result.
	intMinute = Int(intSecond / 60)

' Now we modulus the seconds by 60 to form the seconds value.
	intSecond = intSecond mod 60

' Compute the Hours value by dividing the minutes by 60.
	intHour = Int(intMinute / 60)

' Compute the actual minute value by getting the modulus of the
' total number of minutes and 60.
	intMinute = intMinute mod 60

' If the timer took more then a hour then display the hours.
	If intHour > 0 Then
		If intHour = 1 Then
			strReturn = strReturn & intHour &" hour "
		Else
			strReturn = strReturn & intHour &" hours "
		End If
	End If

' If the timer took more then a minute then display the minutes.
	If intMinute > 0 Then
		If intMinute = 1 Then
			strReturn = strReturn & intMinute &" minute "
		Else
			strReturn = strReturn & intMinute &" minutes "
		End If
	End If

' If the timer took more then a second then display the seconds.
	If intSecond > 0 Then
		If intSecond = 1 Then
			strReturn = strReturn & intSecond &" second "
		Else
			strReturn = strReturn & intSecond &" seconds "
		End If
	End If

' If the timer took more then a millisecond then display the
' milliseconds. Also, if the script took no time then display 0
' milliseconds.

	If strReturn ="" OR intMilliSecond > 0 Then
		If intMilliSecond = 1 Then
			strReturn = strReturn & intMilliSecond &" millisecond"
		Else
			strReturn = strReturn & intMilliSecond &" milliseconds"
		End If
	End If

	PrintInterval = strReturn
End Function
