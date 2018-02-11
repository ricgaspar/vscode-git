Option Explicit

Dim strTextMemMonFile
Dim objFSO, stdOut,strData, strLine, arrLines, arrFields
Dim args, arg1, arg2, arg3, arg4
Dim UsedMem, TotalMem, strOutput, rtCode
Dim wThreshold, cThreshold
Dim UsedMemPercentage
Dim bFound
' Define file actions, used in OpenTextFile Method
CONST ForReading = 1

on error goto 0

strTextMemMonFile = "E:\Apollo\data\freemem\current.out"

'Create a File System Object
Set objFSO = CreateObject("Scripting.FileSystemObject")

'==============================================================================
' Read the command line arguments
'  arg1 = Clustergroup
'  arg2 = Heapsize (max memory)
'  arg3 = Warning level , in percentage tov heapsize
'  arg4 = Critical Threshold , in percentage tov heapsize
'==============================================================================


args = WScript.Arguments.Count
rtCode=1
If args >= 2 then
		
		arg1 = Wscript.Arguments.Item(0)
		arg2 = Wscript.Arguments.Item(1)
		If IsNumeric(WScript.Arguments.Item(2)) Then
			arg3=WScript.Arguments.Item(2)
		Else
			arg3 = 75
		End If
		If IsNumeric(WScript.Arguments.Item(3)) Then
			arg4=WScript.Arguments.Item(3)
		Else
			arg4 = 85
		End If
		
		wThreshold = arg2 * arg3 / 100
		cThreshold = arg2 * arg4 / 100
					
		'==============================================================================
		' Read memory logfile , search for string, if found, echo output to the console
		'==============================================================================
		
		if arg1<>"" and arg2 <> "" then

			if objFSO.FileExists(strTextMemMonFile) then
				strData = objFSO.OpenTextFile(strTextMemMonFile,ForReading).ReadAll
				
				'Split the text file into lines
				arrLines = Split(strData,vbCrLf)
				
				'Step through the lines and output the data preceded by timestamp to the MemMon_new file
				
				For Each strLine in arrLines
                                        bFound=False
					if Trim(strLine) <> "" then
						if instr(strLine, arg1) <> 0 then
							' gevonden
                                                        bFound=True
							arrFields=Split(strLine, ",")
							UsedMem = Round((arrFields(2) - arrFields(3)) / 1024 / 1024)
							TotalMem = Round(arrFields(2) / 1024 / 1024)
							UsedMemPercentage = Round(UsedMem/arg2 * 100)
							If UsedMem > cThreshold Then 
								rtCode=2
							Else
								If UsedMem > wThreshold Then
									rtCode = 1
								Else
									rtCode = 0
								End If
							End If
							strOutput="Used memory=" & UsedMem &  "MB (" & UsedMemPercentage & "%), Max memory: " & arg2 & "MB, Warning at: " & wThreshold & "MB, Critical at : " & cThreshold & "MB|usedmemory=" & usedmem & "MB;" & wThreshold & ";" & cThreshold 
							wscript.echo strOutput 
						  exit for
						end if
					end if
				Next
				if not bFound then
                                        rtCode=1
					wscript.echo arg1 & " not found in " & strTextMemMonFile
				end if
			end if
		end if
end if

'=================================================================================
' Cleanup
'=================================================================================

Set objFSO = Nothing
wscript.quit rtCode


