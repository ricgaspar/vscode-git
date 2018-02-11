Dim IPAdd
Dim Computer
strComputer = "dc01" 
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\MicrosoftDNS") 
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM MicrosoftDNS_PTRType",,48) 
For Each objItem in colItems 

    CompNameArray = Split(objItem.RecordData ,  ".")
    For i = LBound(CompNameArray) to UBound(CompNameArray)
    Computer = CompNameArray(0)
    Next

    Wscript.Echo "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"
    Wscript.Echo "DNS Info for - " & UCase(Computer)
    Wscript.Echo "////////////////////////////////////" & vbCrLf
    IPAddArray = Split (objItem.OwnerName , ".")  
    For i = LBound(IPAddArray) to UBound(IPAddArray)
    IPAdd = IPAddArray(3) & "." & IPAddArray(2) & "." & IPAddArray(1) & "." & IPAddArray(0)
    Next
    
    WScript.Echo "IP Address: " & IPAdd
    Wscript.Echo "FullyQualifiedDomainName: " & objItem.RecordData
    Wscript.Echo "Timestamp: " & objItem.Timestamp & vbCrLf

Next
