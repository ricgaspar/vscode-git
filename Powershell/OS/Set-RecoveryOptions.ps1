
$Computername = "VDLNC01443"
Invoke-Command -Computername $Computername -ScriptBlock {
    & wmic recoveros set WriteToSystemLog = False
    & wmic recoveros set SendAdminAlert = False
    & wmic recoveros set AutoReboot = True
    & wmic recoveros set DebugInfoType = 0
    & whoami
}

