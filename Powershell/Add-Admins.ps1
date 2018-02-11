$ComputerNames = Get-Content "C:\TempTools\Test scripts\servers.txt"
$Admins = Get-Content "C:\TempTools\Test scripts\users-add.txt"
foreach ($ComputerName in $ComputerNames) {
    if ( -not(Test-Connection $ComputerName -Quiet -Count 1 -ErrorAction Continue )) {
        Write-Output "Computer $ComputerName not reachable (PING) - Skipping this computer..."
    }
    else {
        Write-Output "Computer $ComputerName"
        $LocalGroupName = "Administrators"
        $Domain = 'NEDCAR'

        $Group = [ADSI]("WinNT://$computerName/$localGroupName,group")
        $found = $false
        $Group.Members() |
            ForEach-Object {
            $AdsPath = $_.GetType().InvokeMember('Adspath', 'GetProperty', $null, $_, $null)
            $A = $AdsPath.split('/', [StringSplitOptions]::RemoveEmptyEntries)
            $Names = $a[-1]

            foreach ($name in $names) {
                foreach ($Admin in $Admins) {
                    if ($name -eq $Admin) {
                        Write-Output "  User $Admin already found in group $LocalGroupName on computer $computerName"
                        $found = $true
                    }
                }
            }
        }

        if (!$found) {
            foreach ($Admin in $Admins) {
                Write-Output "-> Adding $Admin"
                try {
                    $Group.psbase.Invoke("Add", ([ADSI]"WinNT://$domain/$Admin").path)
                }
                catch {
                    Write-Output "ERROR: Failed to add '$Admin' to Administrators on $Computername"
                }
            }
            Write-Output "Trigger inventory job on $Computername"
            $Job = "\VNB-System configuration info"
            schtasks.exe /S $computername /Run /I /TN $Job
        }
    }
}