# =========================================================
# Collect system information from domain servers and store
# in SQL database secdump.
#
# Marcel Jussen
# 19-09-2017
#
# Change: Update PS inventory for remote computers
# =========================================================
#Requires -version 3.0

param (
    [string]
    $Computername = $env:COMPUTERNAME
)

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

# ---------------------------------------------------------
# Ensures you only refer to variables that exist (great for typos) and
# enforces some other “best-practice” coding rules.
Set-StrictMode -Version Latest

# ---------------------------------------------------------
# enforces all errors to become terminating unless you override with
# per-command -ErrorAction parameters or wrap in a try-catch block
$script:ErrorActionPreference = "Stop"

#region Show-FreeMemory
# ---------------------------------------------------------
Function Show-FreeMemory {
    # ---------------------------------------------------------
    # Show free memory after trigger of garbage collection
    # ---------------------------------------------------------
    try {
        # Trigger garbage collect
        [System.GC]::Collect()

        $os = Get-Ciminstance Win32_OperatingSystem
        $pctFree = [math]::Round(($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 2)
        $FreeGb = [math]::Round($os.FreePhysicalMemory / 1mb, 2)
        $msg = "Physical Memory free: $FreeGb Gb ($pctFree %) post GC collection"
        echo-Log $msg

        $pctFree = [math]::Round(($os.FreeVirtualMemory / $os.TotalVirtualMemorySize) * 100, 2)
        $FreeGb = [math]::Round($os.FreeVirtualMemory / 1mb, 2)
        $msg = "Virtual Memory free: $FreeGb Gb ($pctFree %)  post GC collection"
        echo-Log $msg
    }
    catch {
        Echo-Log $_.Exception|format-list -force
    }
    Clear-LogCache
}
#endregion

#region Import-DBRecord
# ---------------------------------------------------------
Function Import-DBRecord {
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Computername,
        [ValidateNotNullOrEmpty()]
        [string]$ObjectName,
        [ValidateNotNullOrEmpty()]
        $ObjectData,
        [ValidateNotNullOrEmpty()]
        [bool]$Erase

    )
    if ($ObjectData) {
        # Create the table if needed
        $new = New-VNBObjectTable -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
        if ($new) { Echo-Log "Table $ObjectName was created." }

        # Append record to table
        # $RecCount = $($ObjectData.count)
        # Echo-Log "Update table $ObjectName with $RecCount records."
        Send-VNBObject -UDLConnection $Global:UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
    }
}
#endregion

#region Export-OSInformation
# ---------------------------------------------------------
Function Export-OSInformation {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )
    Echo-Log "Collecting OS info on $Computername."

    # Define erase of previous records of this computer
    $Erase = $True

    # Define name of SQL table
    $ObjectName = 'VNB_SYSINFO_PSVERSIONTABLE'
    # Collect object data
    try {
        if ($Computername -eq $env:COMPUTERNAME) {
            Echo-Log "Collecting Powershell version information."
            $PSTable = $PSVersionTable
        }
        else {
            Echo-Log "Collecting Powershell version information on $Computername"
            $PSTable = Invoke-Command -Computername $Computername -Scriptblock {$PSVersionTable} -ErrorAction SilentlyContinue
        }

        $ObjectData = $PSTable | ConvertTo-Object
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        Echo-Log "ERROR: Cannot initiate a remote PS session on $Computername"
        $ErrorResults = "" | Select-Object PSVersion, WSManStackVersion, SerializationVersion, CLRVersion, PSCompatibleVersion, PSRemotingProtocolVersion
        $ErrorResults.PSVersion = '0.0'
        $ErrorResults.WSManStackVersion = '0.0'
        $ErrorResults.SerializationVersion = '0.0'
        $ErrorResults.CLRVersion = '0.0'
        $ErrorResults.PSCompatibleVersion = '0.0'
        $ErrorResults.PSRemotingProtocolVersion = '0.0'
        $ObjectData = $ErrorResults
        Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
    }

    $ClassArray = @('Win32_ComputerSystemProduct', 'Win32_ComputerSystem', 'Win32_BIOS', 'Win32_OperatingSystem', 'Win32_TimeZone', 'Win32_Processor' )
    ForEach ($ClassName in $ClassArray) {
        # Define name of SQL table
        $ObjectName = "VNB_$ClassName"
        $ObjectName = $ObjectName.ToUpper()
        Echo-Log "Collecting WMI class information from class $ClassName on computer $Computername"
        try {
            # Collect object data
            $ObjectData = Get-WmiObject -ComputerName $Computername -Class $ClassName -ErrorAction SilentlyContinue
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
            }
        }
        catch {
            $ErrorMessage = $_.Exception.Message

            Echo-Log ("Error: Could not retrieve data from object class [$($ClassName)]")
            Echo-Log $ErrorMessage

        }
    }

    $ClassName = 'Win32_Service'
    if ($ClassName) {
        # Define name of SQL table
        $ObjectName = "VNB_$ClassName"
        $ObjectName = $ObjectName.ToUpper()
        Echo-Log "Collecting WMI class information from class $ClassName on computer $Computername"
        try {
            # Collect object data
            $ObjectData = Get-WmiObject -ComputerName $Computername -Class $ClassName -ErrorAction SilentlyContinue | Select-Object Name, DisplayName, PathName, StartMode, State, Status, ProcessId, ExitCode, Caption
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
            }
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Echo-Log ("Error: Could not retrieve data from object class [$($ClassName)]")
            Echo-Log $ErrorMessage

        }
    }
}
#endregion

#region Export-Registry
# ---------------------------------------------------------
Function Export-Registry {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )

    Echo-Log "Collecting registry info on $Computername"
    # Override
    if ($Computername -ne $env:COMPUTERNAME) {
        Echo-Log "This function is not allowed te be run remotely."
        Return 0
    }

    # Define erase of previous records of this computer
    $Erase = $True

    # Define name of SQL table
    try {
        $ObjectName = 'VNB_SYSINFO_REG_WINDOWSUPDATE'
        $RegKey = "hklm:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"
        $ObjectData = Get-ItemProperty $regkey
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        Echo-log "ERROR: Cannot retrieve registry key."
    }

    try {
        $ObjectName = 'VNB_SYSINFO_REG_WINDOWSUPDATE_AU'
        $RegKey = "hklm:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        $ObjectData = Get-ItemProperty $RegKey
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        Echo-log "ERROR: Cannot retrieve registry key."
    }

    try {
        $ObjectName = 'VNB_SYSINFO_REG_WINDOWSUPDATE_AUTOUPDATE'
        $RegKey = "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\"
        $ObjectData = Get-ItemProperty $RegKey
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        Echo-log "ERROR: Cannot retrieve registry key."
    }

    try {
        $ObjectName = 'VNB_SYSINFO_REG_WINDOWSUPDATE_AUTOUPDATE_RESULTSDETECT'
        $RegKey = "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect\"
        $ObjectData = Get-ItemProperty $RegKey
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        Echo-log "ERROR: Cannot retrieve registry key."
    }

    try {
        $ObjectName = 'VNB_SYSINFO_REG_WINDOWSUPDATE_AUTOUPDATE_RESULTSDOWNLOAD'
        $RegKey = "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Download\"
        $ObjectData = Get-ItemProperty $RegKey
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        Echo-log "ERROR: Cannot retrieve registry key."
    }

    try {
        $ObjectName = 'VNB_SYSINFO_REG_WINDOWSUPDATE_AUTOUPDATE_RESULTSINSTALL'
        $RegKey = "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install\"
        $ObjectData = Get-ItemProperty $RegKey
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        Echo-log "ERROR: Cannot retrieve registry key."
    }
}
#endregion

#region Export-Network
# ---------------------------------------------------------
Function Export-Network {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )
    Echo-Log "Collecting network info on $Computername"
    # Define erase of previous records of this computer
    $Erase = $True

    $ObjectData = Get-WmiObject -ComputerName $Computername -Class Win32_NetworkAdapter -ErrorAction SilentlyContinue | Select-Object Availability, Description, DeviceID, Index, Installed, MACAddress, Manufacturer, MaxSpeed, Name, ProductName, ServiceName, Speed, Status
    $ObjectName = 'VNB_WIN32_NETWORKADAPTER'
    if ($ObjectData) {
        Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
    }

    $NACErase = $True
    $NetConfig = Get-WmiObject -ComputerName $Computername -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where {$_.IpEnabled -Match "True"}
    #Inventory NIC interfaces
    foreach ($NIC in $NetConfig) {
        $NIPErase = $True
        $NIPSubErase = $True
        $NIPgwErase = $True
        $NIPdnsErase = $True

        if ($NIC) {
            $ObjectName = 'VNB_WIN32_NETWORKADAPTERCONFIGURATION'
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $NIC -Erase $NACErase
            $NACErase = $False

            # Inventory IP addresses per interface
            try {
                foreach ($IP in $NIC.IPAddress) {
                    $IPParams = @{
                        Caption        = $NIC.Caption
                        Description    = $NIC.Description
                        DHCPEnabled    = $NIC.DHCPEnabled
                        DHCPServer     = $NIC.DHCPServer
                        Index          = $NIC.Index
                        InterfaceIndex = $NIC.InterfaceIndex
                        IPAddress      = $IP
                    }
                    $IPObj = $IPParams | ConvertTo-Object
                    $ObjectName = 'VNB_WIN32_NETWORKADAPTERIPADDRESS'
                    Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $IPObj -Erase $NIPErase
                    $NIPErase = $False
                }
            }
            catch {
                Echo-Log "ERROR: WIN32 Class IPAddress error on computer $Computername"
            }

            # Inventory Subnet masks per interface
            try {
                foreach ($IPsubnet in $NIC.IPSubnet) {
                    $IPSubParams = @{
                        Caption        = $NIC.Caption
                        Description    = $NIC.Description
                        DHCPEnabled    = $NIC.DHCPEnabled
                        DHCPServer     = $NIC.DHCPServer
                        Index          = $NIC.Index
                        InterfaceIndex = $NIC.InterfaceIndex
                        IPSubnet       = $IPsubnet
                    }
                    $ObjectName = 'VNB_WIN32_NETWORKADAPTERIPSUBNET'
                    $IPObj = $IPSubParams | ConvertTo-Object
                    Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $IPObj -Erase $NIPErase
                    $NIPSubErase = $False
                }
            }
            catch {
                Echo-Log "ERROR: WIN32 Class IPSubnet error on computer $Computername"
            }

            # Inventory Gateway addresses per interface
            try {
                foreach ($IPgw in $NIC.DefaultIPGateway) {
                    $IPGWParams = @{
                        Caption        = $NIC.Caption
                        Description    = $NIC.Description
                        DHCPEnabled    = $NIC.DHCPEnabled
                        DHCPServer     = $NIC.DHCPServer
                        Index          = $NIC.Index
                        InterfaceIndex = $NIC.InterfaceIndex
                        Gateway        = $IPgw
                    }
                    $ObjectName = 'VNB_WIN32_NETWORKADAPTERGATEWAY'
                    $IPObj = $IPGWParams | ConvertTo-Object
                    Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $IPObj -Erase $NIPgwErase
                    $NIPgwErase = $False
                }
            }
            catch {
                Echo-Log "ERROR: WIN32 Class IPGateway error on computer $Computername"
            }

            # Inventory DNS addresses per interface
            try {
                foreach ($IPDNS in $NIC.DNSServerSearchOrder) {
                    $IPDNSParams = @{
                        Caption        = $NIC.Caption
                        Description    = $NIC.Description
                        DHCPEnabled    = $NIC.DHCPEnabled
                        DHCPServer     = $NIC.DHCPServer
                        Index          = $NIC.Index
                        InterfaceIndex = $NIC.InterfaceIndex
                        IPSubnet       = $IPDNS
                    }
                    $ObjectName = 'VNB_WIN32_NETWORKADAPTERDNS'
                    $IPObj = $IPDNSParams | ConvertTo-Object
                    Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $IPObj -Erase $NIPdnsErase
                    $NIPdnsErase = $False
                }
            }
            catch {
                Echo-Log "ERROR: WIN32 Class DNSServerSearchOrder error on computer $Computername"
            }

            $key = "SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"
            $suffix = $([String]$NIC.Index).PadLeft(4, "0")

            #get remote registry value of speed/duplex
            $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computername)
            $service = $reg.OpenSubKey("$key\\$suffix\\Ndi").GetValue("Service")
            If ($service -imatch "usb") {
                # This USB device will not have a '*SpeedDuplex' key
                $SpDplx = New-Object PSObject -Property @{
                    "ComputerName"   = $Computername
                    "Device"         = $NIC.Description
                    "Speed/Duplex"   = "USB Device"
                    "Index"          = $NIC.Index
                    "InterfaceIndex" = $NIC.InterfaceIndex
                }
            }
            ElseIf ($service -imatch "netft") {
                # Microsoft Clustered Network will not have a '*SpeedDuplex' key
                $SpDplx = New-Object PSObject -Property @{
                    "ComputerName"   = $Computername
                    "Device"         = $NIC.Description
                    "Speed/Duplex"   = "Cluster Device"
                    "Index"          = $NIC.Index
                    "InterfaceIndex" = $NIC.InterfaceIndex
                }
            }
            Else {
                $speedduplex = $reg.OpenSubKey("$key\\$suffix").GetValue("*SpeedDuplex")
                if ($speedduplex) {
                    $enums = "$key\$suffix\Ndi\Params\*SpeedDuplex\enum"
                    $SpDplx = New-Object PSObject -Property @{
                        "ComputerName"   = $Computername
                        "Device"         = $NIC.Description
                        "Speed/Duplex"   = $reg.OpenSubKey($enums).GetValue($speedduplex)
                        "Index"          = $NIC.Index
                        "InterfaceIndex" = $NIC.InterfaceIndex
                    }
                }
                else {
                    $SpDplx = New-Object PSObject -Property @{
                        "ComputerName"   = $Computername
                        "Device"         = $NIC.Description
                        "Speed/Duplex"   = "Cannot be determined."
                        "Index"          = $NIC.Index
                        "InterfaceIndex" = $NIC.InterfaceIndex
                    }
                }
            }

            $Erase = $true
            $ObjectData = $SpDplx
            $ObjectName = 'VNB_Win32_NetworkAdapterConfiguration_SpeedDuplex'
            $ObjectName = $ObjectName.ToUpper()
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
            }
        }
    }
}
#endregion

#region Export-Shares
# ---------------------------------------------------------
Function Export-Shares {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )
    Echo-Log "Collecting share info on $Computername"

    # Define erase of previous records of this computer
    $ShareErase = $True
    $ObjectName = 'VNB_WIN32_SHARE'

    $ObjectData = Get-WmiObject Win32_Share -ComputerName $Computername -ErrorAction SilentlyContinue | Select-Object Name, Path, Status, Type, Caption, Description, AccessMask, AllowMaximum
    if ($ObjectData) {
        Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $ShareErase
        $ShareErase = $False
        $ShareSecErase = $True

        ForEach ($Share in $ObjectData) {
            $sharename = $Share.Name
            $ShareSec = Get-WmiObject -ComputerName $Computername -Class Win32_LogicalShareSecuritySetting | Where-Object {$_.Name -eq $sharename}
            ForEach ($ShareSecDesc in $ShareSec) {
                $SecurityDescriptor = $ShareSecDesc.GetSecurityDescriptor()
                $myCol = @()
                ForEach ($DACL in $SecurityDescriptor.Descriptor.DACL) {
                    $myObj = "" | Select-Object Name, TrusteeDomain, TrusteeID, AccessMask, AceType
                    $myObj.Name = $sharename
                    $myObj.TrusteeDomain = $DACL.Trustee.Domain
                    $myObj.TrusteeID = $DACL.Trustee.Name

                    Switch ($DACL.AccessMask) {
                        2032127 {$AccessMask = "FullControl"}
                        1179785 {$AccessMask = "Read"}
                        1180063 {$AccessMask = "Read, Write"}
                        1179817 {$AccessMask = "ReadAndExecute"}
                        -1610612736 {$AccessMask = "ReadAndExecuteExtended"}
                        1245631 {$AccessMask = "ReadAndExecute, Modify, Write"}
                        1180095 {$AccessMask = "ReadAndExecute, Write"}
                        268435456 {$AccessMask = "FullControl (Sub Only)"}
                        default {$AccessMask = $DACL.AccessMask}
                    }

                    $myObj.AccessMask = $AccessMask
                    Switch ($DACL.AceType) {
                        0 {$AceType = "Allow"}
                        1 {$AceType = "Deny"}
                        2 {$AceType = "Audit"}
                    }

                    $myObj.AceType = $AceType
                    Clear-Variable AccessMask -ErrorAction SilentlyContinue
                    Clear-Variable AceType -ErrorAction SilentlyContinue
                    $myCol += $myObj
                }

                $ObjectName = 'VNB_WIN32_SHARESECURITY'
                $ObjectData = $myCol
                if ($ObjectData) {
                    Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $ShareSecErase
                    $ShareSecErase = $False
                }
            }
        }
    }
}
#endregion

#region Export-LocalGroups
# ---------------------------------------------------------
Function Export-LocalGroups {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )
    Echo-Log "Collecting local groups info on $Computername"

    # Do not perform this export if this computer is a domain controller
    # Detect domain controllers in the domain
    Echo-Log "Check domain role of computer: $($Computername)"
    Try {
        $Computer = Get-WmiObject Win32_ComputerSystem -ComputerName $Computername -ErrorAction SilentlyContinue
    }
    Catch {
        Echo-Log "ERROR: Cannot connect to WMI class Win32_Computersystem. Aborting function."
        exit 0
    }

    $DCCheck = $true
    if ($Computer) {
        $Role = ($Computer).domainrole
        $DCCheck = (($Role -eq 4) -or ($Role -eq 5))
    }
    if ($DCCheck) {
        Echo-Log "This computer is a domain controller. Skipping local groups inventory."
        return
    }

    # Define erase of previous records of this computer
    $Erase = $True
    $ObjectName = 'VNB_SYSINFO_COMPUTERLOCALGROUPS'

    Echo-Log "Retrieve computer local groups."
    Try {
        $Groups = Get-WmiObject -Class 'Win32_Group' -ComputerName $Computername | Select-Object Name, Description, Path
    }
    Catch {
        Echo-Log "ERROR: Cannot connect to WMI to retrieve class Win32_Group."
        $Groups = $null
    }


    # Export local groups
    foreach ($LocalGroup in $groups) {
        $GroupObj = "" | Select-Object Name, Description, Path
        $GroupObj.Name = $($LocalGroup.Name)
        $GroupObj.Description = $($LocalGroup.Description)
        $GroupObj.Path = $($LocalGroup.Path)

        # Create the table if needed
        $ObjectData = $GroupObj
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
            $Erase = $False
        }
    }

    # Define erase of previous records of this computer
    $Erase = $True
    $ObjectName = 'VNB_SYSINFO_COMPUTERLOCALGROUPSMEMBERS'

    Try {
        $GroupMembers = Get-WmiObject -Class 'Win32_GroupUser' -ComputerName $Computername | Select-Object GroupComponent, PartComponent
    }
    Catch {
        Echo-Log "ERROR: Cannot connect to WMI class Win32_GroupUser."
    }

    ForEach ($Member in $GroupMembers) {
        $GroupComponent = $Member.GroupComponent
        $GroupDet = $GroupComponent -split ','
        $LocalGroupName = (($GroupDet[1] -split '=')[1]) -replace '"', ''

        $PartComponent = $Member.PartComponent
        if ($PartComponent -notmatch 'Win32_SystemAccount') {
            $PartDet = $PartComponent -split ','
            $PartDomain = (($PartDet[0] -split '=')[1]) -replace '"', ''
            $PartName = (($PartDet[1] -split '=')[1]) -replace '"', ''

            If ($PartDomain -eq $Computername) { $PartDomain = 'NEDCAR/' + $PartDomain}
            $Member = 'WinNT://' + $PartDomain + '/' + $PartName

            $MbrObj = "" | Select-Object LocalGroupName, Trusteename
            $MbrObj.LocalGroupName = $localgroupname
            $MbrObj.Trusteename = $Member

            # Create the table if needed
            $ObjectData = $MbrObj
            if ($ObjectData) {
                if ($ObjectData) {
                    Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
                    $Erase = $False
                }
            }
        }
    }
}
#endregion

#region Export-Disks
# ---------------------------------------------------------
Function Export-Disks {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )
    Echo-Log "Collecting disks info on $Computername"

    # Define erase of previous records of this computer
    $Erase = $True

    $ClassArray = @('Win32_DiskDrive', 'Win32_DiskDriveToDiskPartition', 'Win32_LogicalDisk', 'Win32_LogicalDiskToPartition')
    ForEach ($ClassName in $ClassArray) {
        # Define name of SQL table
        $ObjectName = "VNB_$ClassName"
        Echo-Log "Collecting WMI class information from class $ClassName"
        try {
            # Collect object data
            $ObjectData = Get-WmiObject -ComputerName $Computername -Class $ClassName -ErrorAction SilentlyContinue
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
            }
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Echo-Log ("Error: Could not retrieve data from object class [$($ClassName)]")
            Echo-Log $ErrorMessage
        }
    }
}
#endregion

#region Export-PageFile
# ---------------------------------------------------------
Function Export-PageFile {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )

    Echo-Log "Collecting pagefile info on $Computername"
    # Override
    if ($Computername -ne $env:COMPUTERNAME) {
        Echo-Log "This function is not allowed te be run remotely."
        Return 0
    }

    # Define erase of previous records of this computer
    $Erase = $True

    # Define name of SQL table
    $ObjectName = 'VNB_WIN32_PAGEFILEUSAGE'
    # Collect object data
    $ObjectData = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue
    if ($ObjectData) {
        Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
    }
}
#endregion

#region Export-Tasks
# ---------------------------------------------------------
Function Export-Tasks {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )
    Echo-Log "Collecting task scheduler info on $Computername"
    # Define erase of previous records of this computer
    $Erase = $True

    # Define name of SQL table
    $ObjectName = 'VNB_SYSINFO_TASKSCHEDULER'
    # Collect object data
    $ObjectData = Export-ScheduledTasks $Computername
    if ($ObjectData) {
        Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
    }
}
#endregion

#region Export-MPIOInfo
# ---------------------------------------------------------
Function Export-MPIOInfo {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )

    Echo-Log "Collecting MPIO info on $Computername"
    # Override
    if ($Computername -ne $env:COMPUTERNAME) {
        Echo-Log "This function is not allowed te be run remotely."
        Return 0
    }

    # Define erase of previous records of this computer
    $Erase = $True

    # Define name of SQL table
    try {
        Echo-Log "Collecting HBA info on $Computername"
        $ObjectName = 'VNB_SYSINFO_HOSTBUSADAPTER'
        $ObjectData = Get-HBAInfo $Computername
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Echo-Log ("Error: Could not retrieve HBA data.")
        Echo-Log $ErrorMessage
    }

    try {
        # Define name of SQL table
        Echo-Log "Collecting MPIO Disk info on $Computername"
        $Erase = $True
        $ObjectName = 'VNB_SYSINFO_MPIODISKINFO'
        $ClassData = GWMI -Namespace "root\wmi" -Class mpio_disk_info -ErrorAction SilentlyContinue | Select DriveInfo
        ForEach ($ClassObj in $ClassData.DriveInfo) {
            $ObjectData = $ClassObj | Select DsmName, Name, NumberPaths, SerialNumber
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
                $Erase = $False
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Echo-Log ("Error: Could not retrieve data from object class [mpio_disk_info]")
        Echo-Log $ErrorMessage

        return
    }

    try {
        Echo-Log "Collecting MPIO Disk health info on $Computername"
        $Erase = $True
        $ObjectName = 'VNB_SYSINFO_MPIODISKINFO'
        $ClassData = gwmi -NameSpace root\WMI -Class MPIO_DISK_HEALTH_INFO -ErrorAction SilentlyContinue | Select DiskHealthPackets
        ForEach ($ObjData in $ClassData.DiskHealthPackets) {
            $ObjectData = $ObjData
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
                $Erase = $False
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Echo-Log ("Error: Could not retrieve data from object class [MPIO_DISK_HEALTH_INFO]")
        Echo-Log $ErrorMessage
    }

    try {
        Echo-Log "Collecting MPIO Path info on $Computername"
        $Erase = $True
        $ObjectName = 'VNB_SYSINFO_MPIOPATHINFO'
        $ClassData = GWMI -Namespace "root\wmi" -Class mpio_path_information -ErrorAction SilentlyContinue | Select PathList
        ForEach ($ClassObj in $ClassData.PathList) {
            $ObjectData = $ClassObj | Select AdapterName, BusNumber, DeviceNumber, FunctionNumber, Pad, PathId
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
                $Erase = $False
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Echo-Log ("Error: Could not retrieve data from object class [mpio_path_information]")
        Echo-Log $ErrorMessage
    }

    try {
        Echo-Log "Collecting MPIO Path health info on $Computername"
        $Erase = $True
        $ObjectName = 'VNB_SYSINFO_MPIOPATHHEALTHINFO'
        $ClassData = gwmi -NameSpace root\WMI -Class MPIO_PATH_HEALTH_INFO -ErrorAction SilentlyContinue | Select PathHealthPackets
        ForEach ($ObjData in $ClassData.PathHealthPackets) {
            $ObjectData = $ObjData
            if ($ObjectData) {
                Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
                $Erase = $False
            }
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Echo-Log $ErrorMessage
        Echo-Log ("Error: Could not retrieve data from object class [MPIO_PATH_HEALTH_INFO]")
    }
}
#endregion

#region Export-Eventlog
# ---------------------------------------------------------
Function Export-Eventlog {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )

    Echo-Log "Collecting eventlog info on $Computername"
    # Override
    if ($Computername -ne $env:COMPUTERNAME) {
        Echo-Log "This function is not allowed te be run remotely."
        Return 0
    }

    $logname = 'system'
    $maxeventcount = 20

    # Define erase of previous records of this computer
    $Erase = $True
    $ObjectName = 'VNB_SYSINFO_EVENTS'

    # Define name of SQL table
    $eventid = 1074
    try {
        $ObjectData = get-eventlog -LogName $logname -ErrorAction SilentlyContinue | Select-Object EventId, Source, Index, EntryType, Message, TimeGenerated, TimeWritten | where-object { $_.eventid -eq $eventid } | select -first $maxeventcount
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
        $Erase = $False
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Echo-Log $ErrorMessage
        Echo-Log "ERROR: Could not retrieve eventlog records."
    }

    # Additional eventlog records are appended to the table
    $eventid = 6009
    try {
        $ObjectData = get-eventlog -LogName $logname -ErrorAction SilentlyContinue | Select-Object EventId, Source, Index, EntryType, Message, TimeGenerated, TimeWritten | where-object { $_.eventid -eq $eventid } | select -first $maxeventcount
        if ($ObjectData) {
            Import-DBRecord -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $Erase
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Echo-Log $ErrorMessage
        Echo-Log "ERROR: Could not retrieve eventlog records."
    }
}
#endregion

#region Get-Inventory
Function Get-Inventory {
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [string]$Computername = $env:COMPUTERNAME
    )

    # Export-OSInformation $Computername
    # Export-Registry $Computername
    Export-Network $Computername
    # Export-Shares $Computername
    # Export-LocalGroups $Computername
    # Export-Disks $Computername
    # Export-PageFile $Computername
    # Export-MPIOInfo $Computername
    # Export-Tasks $Computername
    # Export-Eventlog $Computername
}
#endregion

# ---------------------------------------------------------
Clear-Host

$Sysinfolog = "$env:SYSTEMDRIVE\Logboek\Secdump-SysInfo.log"
$Global:glb_EVENTLOGFile = $Sysinfolog
[void](Init-Log -LogFileName $Sysinfolog $False -alternate_location $True)
Echo-Log ("=" * 80)
Echo-Log "Start of script on computer $($env:COMPUTERNAME)"
Show-FreeMemory

# Create MSSQL connection
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

$SQLconn = New-UDLSQLconnection -UDLConnection $Global:UDLConnection
$query = "select Systemname from vw_VNB_P_DOMAIN_COMPUTERS where DN like '%OU=LijnPC,OU=FAS%' order by Systemname"
$data = Query-SQL $query $SQLconn

ForEach ($rec in $data) {
    Echo-Log "Test computer: $($rec.Systemname)"
    $connection = Test-Connection -ComputerName $($rec.Systemname) -ErrorAction SilentlyContinue
    if ($connection) {
        Get-Inventory -Computername $($rec.Systemname)
    }
}

Show-FreeMemory
Echo-Log "End of script on computer $($env:COMPUTERNAME)"
Echo-Log ("=" * 80)
# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================