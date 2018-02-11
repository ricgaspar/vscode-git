#List of computers to be check
$ComputerNames = Get-Content "C:\TempTools\Test scripts\servers.txt"
$Admins = Get-Content "C:\TempTools\Test scripts\users-remove.txt"
foreach ($ComputerName in $ComputerNames) {
    if ( -not(Test-Connection $ComputerName -Quiet -Count 1 -ErrorAction Continue )) {
        Write-Output "Computer $ComputerName not reachable (PING) - Skipping this computer..."
    }
    else {
        Write-Output "Computer $ComputerName"
        $LocalGroupName = "Administrators"
        $Group = [ADSI]("WinNT://$computerName/$localGroupName,group")
        $Group.Members() |
            ForEach-Object {
            $AdsPath = $_.GetType().InvokeMember('Adspath', 'GetProperty', $null, $_, $null)
            $A = $AdsPath.split('/', [StringSplitOptions]::RemoveEmptyEntries)
            $Names = $a[-1]
            $Domain = $a[-2]

            #Gets the list of users to be removed from a TXT that you specify and checks if theres a match in the local group
            foreach ($name in $names) {
                # Write-Output "Verifying the local admin user $name on computer $computerName"
                foreach ($Admin in $Admins) {
                    if ($name -eq $Admin) {
                        #If it finds a match it will notify you and then remove the user from the local administrators group
                        Write-Output "User $Admin found on computer $computerName ... "
                        $Group.Remove("WinNT://$computerName/$domain/$name")
                        Write-Output "Removed"
                    }
                }
            }
        }

        Write-Output "Trigger inventory job on $Computername"
        $Job = "\VNB-System configuration info"
        schtasks.exe /S $computername /Run /I /TN $Job
    }

    #Passes all the information of the operations made into the log file
}
