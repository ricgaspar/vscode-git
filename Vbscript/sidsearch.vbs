strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

Set objAccount = objWMIService.Get _
    ("Win32_SID.SID='S-1-5-21-8915387-1091650625-1897138802-1105'")
Wscript.Echo objAccount.AccountName
Wscript.Echo objAccount.ReferencedDomainName
