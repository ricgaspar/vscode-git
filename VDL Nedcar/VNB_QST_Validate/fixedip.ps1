# =========================================================
# VDL Nedcar - Information Systems
#
# .SYNOPSIS
# 	VNB Fixed IP registration and configuration
#
# .CREATED_BY
# 	Marcel Jussen
#
# .CHANGE_DATE
# 	12-07-2018
#
# .DESCRIPTION
#	Register a fixed IP address and configure the local machine
#
# =========================================================
#Requires -version 4.0

[CmdletBinding()]
Param(
    [switch]$Update,
    [switch]$Delete,
    [switch]$Remove,
    [switch]$Swap,
    [switch]$Force,
    [string]$Computername
)

# ---------------------------------------------------------
# Reload required modules
Import-Module VNB_PSLib -Force -ErrorAction Stop

# ---------------------------------------------------------
# Ensures you only refer to variables that exist (great for typos)
# and enforces other “best-practice” coding rules.
Set-StrictMode -Version Latest

# ---------------------------------------------------------
$Global:DEBUG = $True

# ---------------------------------------------------------
Function Get-NICSpeedDuplex {
    Param (
        [String]$DeviceIndex
    )
    $key = "SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"
    $computer = $env:Computername
    Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $DeviceIndex } | ForEach-Object {
        $suffix = $([String]$_.Index).PadLeft(4, "0")

        #get remote registry value of speed/duplex
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $service = $reg.OpenSubKey("$key\\$suffix\\Ndi").GetValue("Service")
        If ($service -imatch "usb") {
            # This USB device will not have a '*SpeedDuplex' key
            New-Object PSObject -Property @{
                "SpeedDuplexMode" = "USB Device"
            }
        }
        ElseIf ($service -imatch "netft") {
            # Microsoft Clustered Network will not have a '*SpeedDuplex' key
            New-Object PSObject -Property @{
                "SpeedDuplexMode" = "Cluster Device"
            }
        }
        Else {
            $speedduplex = $reg.OpenSubKey("$key\\$suffix").GetValue("*SpeedDuplex")
            if ($speedduplex) {
                $enums = "$key\$suffix\Ndi\Params\*SpeedDuplex\enum"
                New-Object PSObject -Property @{
                    "SpeedDuplexMode" = $reg.OpenSubKey($enums).GetValue($speedduplex)
                }
            }
            else {
                New-Object PSObject -Property @{
                    "SpeedDuplexMode" = "Cannot be determined."
                }
            }
        }
    }
}

function Disable-NetBIOS {
    gcim Win32_NetworkAdapterConfiguration -Filter 'ipenabled = true' |
        Invoke-CimMethod -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = 2 }
}

Function Change_DNS_SearchOrder {
    Param (
        [String]$DeviceIndex
    )

    $networkAdapters = Get-CimInstance -Classname Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $DeviceIndex }
    if ($networkAdapters -ne $null) {
        foreach ($networkAdapter in $networkAdapters) {
            $capt = $networkAdapter.Description
            $CurDNS = $networkAdapter.DNSServerSearchOrder
            $CurDNS = [string]$CurDNS

            $OldDNS = $CurDNS.Contains("10.178.0.6")
            if ($OldDNS -eq $false) { $OldDNS = $CurDNS.Contains("10.178.0.7") }

            $NewDNS = "10.30.20.10", "10.30.20.11"
            if ($OldDNS -eq $true) {
                $Global:Changes_Proposed++
                if ($Global:DEBUG -ne $true) {
                    $ret = $networkAdapter.SetDNSServerSearchOrder($NewDNS)
                    $Global:Changes_Committed++
                    Echo-Log "$computername : $capt : ***  New DNS search order: $NewDNS"
                }
                else {
                    Echo-Log "$computername : $capt : (DEBUG) ***  New DNS search order: $NewDNS"
                }
            }
            else {
                if ([string]::IsNullOrEmpty($CurDNS)) {
                    Echo-Log "$computername : $capt : No DNS search order specified."
                }
                else {
                    Echo-Log "$computername : $capt : DNS search order is already set."
                }
            }
        }
    }
    else {
        Echo-Log "DNS: No static configured adapters found."
    }

}
Function Insert-Record {
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

Function Set-WMINetConfigStaticIP {
    [CmdletBinding()]
    param (
        $NetworkAdapterConfig,
        $IPConfig,
        [switch]$Force
    )

    try {
        $Change = $False
        if (($($NetworkAdapterConfig.IPAddress[0]) -ne $($IPConfig.IPAddress)) -or $Force) {
            # IP address and subnet mask
            $NetworkAdapterConfig.EnableStatic($($IPConfig.IPAddress), $($IPConfig.NetMask)) | Out-Null

            # Gateway
            $NetworkAdapterConfig.SetGateways($IPConfig.Gateway) | Out-Null

            # DNS servers
            $NetworkAdapterConfig.SetDNSServerSearchOrder($IPConfig.DNSSearchOrder) | Out-Null

            # DNS registration
            $NetworkAdapterConfig.SetDNSDomain('nedcar.nl') | Out-Null
            $NetworkAdapterConfig.SetDynamicDNSRegistration($True, $True) | Out-Null

            # Disable NETBIOS over TCP
            $NetworkAdapterConfigs = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration )
            Foreach ($NetworkAdapterConfig in $NetworkAdapterConfigs) {
                $NetworkAdapterConfig.settcpipnetbios(2) | Out-Null
            }

            $Change = $true
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        # $FailedItem = $_.Exception.ItemName
        Echo-Log "ERROR: A change to the IP stack resulted in an error."
        # Echo-Log "       ItemName: $FailedItem"
        Echo-Log "       Message: $ErrorMessage"
    }

    $NetworkAdapterConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
        Where-Object { $_.Index -eq $DeviceIndex }
    if ($Change) {
        If ($($NetworkAdapterConfig.IPAddress[0]) -ne $($IPConfig.IPAddress)) {
            Echo-Log "ERROR: Configuring the IP address failed!"
        }
        else {
            Echo-Log ''
            Echo-Log ("*-" * 40)
            Echo-Log "The IP address was successfully changed."
            Echo-Log ("*-" * 40)
        }
    }
    else {
        Echo-Log "No changes are made. The current IP address is correct."
    }
}

Function Set-WMINetConfigStaticDHCP {
    [CmdletBinding()]
    param (
        $NetworkAdapterConfig,
        [switch]$Force
    )

    try {
        $Change = $False
        if (($NetworkAdapterConfig.DHCPEnabled -ne 'TRUE') -or $Force) {
            # IP address and subnet mask
            $NetworkAdapterConfig.EnableDHCP() | Out-Null
            $NetworkAdapterConfig.SetDNSServerSearchOrder() | Out-Null
            $Change = $true
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        # $FailedItem = $_.Exception.ItemName
        Echo-Log "ERROR: A change to the IP stack resulted in an error."
        # Echo-Log "       ItemName: $FailedItem"
        Echo-Log "       Message: $ErrorMessage"
    }

    $NetworkAdapterConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
        Where-Object { $_.Index -eq $DeviceIndex }
    if ($Change) {
        If ($NetworkAdapterConfig.DHCPEnabled -ne 'TRUE') {
            Echo-Log "ERROR: Configuring the adapter to DHCP failed!"
        }
        else {
            Echo-Log ''
            Echo-Log ("*-" * 40)
            Echo-Log "The network adapter was successfully changed to DHCP."
            Echo-Log ("*-" * 40)
        }
    }
    else {
        Echo-Log "No changes are made. The adapter was already set to DHCP."
    }
}

Function Update-MDTComputerNIC {
    [CmdletBinding()]
    param (
        $MDTComputerName,
        $MDTComputerID,
        $NetworkAdapter,
        $NetworkAdapterConfig,
        $NicInfo
    )

    $ComputerNIC = @{
        'ID'                  = $($MDTComputerID)
        'Systemname'          = $($NetworkAdapter.SystemName);
        'Index'               = $($NetworkAdapter.Index);
        'Name'                = $($NetworkAdapter.Name);
        'MACAddress'          = $($NetworkAdapter.MACAddress);
        'Speed'               = $($NetworkAdapter.Speed);
        'SpeedDuplexMode'     = $($NicInfo.SpeedDuplexMode);
        'PhysicalAdapter'     = $($NetworkAdapter.PhysicalAdapter);
        'NetConnectionStatus' = $($NetworkAdapter.NetConnectionStatus);
        'NetConnectionID'     = $($NetworkAdapter.NetConnectionID);

        'DHCPEnabled'         = $NetworkAdapterConfig.DHCPEnabled;
        'IPAddress0'          = $NetworkAdapterConfig.IPAddress[0];
        'IPSubnet0'           = $NetworkAdapterConfig.IPSubnet[0];
        'DefaultGateway0'     = $NetworkAdapterConfig.DefaultIPGateway[0];
        'DNSServer0'          = $NetworkAdapterConfig.DNSServerSearchOrder[0];
        'DNSServer1'          = $NetworkAdapterConfig.DNSServerSearchOrder[1];
        'DNSDomain'           = $NetworkAdapterConfig.DNSDomain;
        'TcpNetbiosOptions'   = $NetworkAdapterConfig.TcpipNetbiosOptions;
        'TcpWindowSize'       = $NetworkAdapterConfig.TcpWindowSize
    }

    Echo-Log "Current IP configuration:"
    Echo-Log "  IP Address: $($NetworkAdapterConfig.IPAddress[0])"
    Echo-Log "  Net mask  : $($NetworkAdapterConfig.IPSubnet[0])"
    Echo-Log "  Gateway   : $($NetworkAdapterConfig.DefaultIPGateway[0])"
    Echo-Log "  DNS       : $($NetworkAdapterConfig.DNSServerSearchOrder)"

    $ObjectName = 'ComputerNIC'
    Echo-Log "Updating MDT table '$ObjectName' with current IP settings."
    $ObjectData = $ComputerNIC | ConvertTo-Object
    Insert-Record -Computername $MDTComputerName -ObjectName $ObjectName -ObjectData $ObjectData -Erase $True
}

Function Get-NewIpConfig {
    [CmdletBinding()]
    param (
        $MDTComputerID,
        $UDLConnection
    )
    $NewIPConfig = $null
    $query = "exec dbo.IdentifyComputerIP $MDTComputerID"
    $data = Query-SQL $query $Global:UDLConnection
    if ($data) {
        $IPAddress = $($data.IPAddress)
        $NewIPConfig = @{
            'IPAddress'      = $IPAddress
            'Gateway'        = '10.30.120.1'
            'Netmask'        = '255.255.254.0'
            'DNSSearchOrder' = "10.30.20.10", "10.30.20.11"
        }
    }
    else {
        Echo-Log "ERROR: Data is null."
    }
    return $NewIPConfig
}

Function Remove-NewIpConfig {
    [CmdletBinding()]
    param (
        $MDTComputerID,
        $UDLConnection
    )
    $RecordCount = $null
    $query = "exec dbo.RemoveComputerIP $MDTComputerID"
    $data = Query-SQL $query $Global:UDLConnection
    if ($data) {
        $RecordCount = $($data.count)
    }
    else {
        Echo-Log "ERROR: Data is null."
    }
    return $RecordCount
}

# =========================================================
Clear-Host

# Record start of script.
$BaseStart = Get-Date
$Global:ScriptStart = Get-Date

# Create default folder structure if it is not there already
$LogFolderPath = "$env:SYSTEMDRIVE\Logboek"
[void]( Create-FolderStruct $LogFolderPath)
$ScriptLog = Join-Path -Path $LogFolderPath -ChildPath 'VNB-FixedIP.log'
$Global:glb_EVENTLOGFile = $ScriptLog
[void](Init-Log -LogFileName $ScriptLog $False -alternate_location $True)

Echo-Log ("=" * 80)
Echo-Log "Starting script."
# ---------------------------------------------------------

if ($Update) {
    Echo-Log "The -Update command line parameter was used."
    if ($Delete -or $Remove -or $Swap) {
        Echo-Log "ERROR: Invalid commmand line parameter combination used."
        Exit 1
    }
    if ([string]::IsNullorEmpty($Computername)) {
        Echo-Log "The -Computername command line parameter was not used."
        Echo-Log "Using local computername."
        $Computername = $env:Computername
    }
    else {
        Echo-Log "ERROR: The -Computername command line parameter was used."
        Echo-Log "       You may not update static IP address reservations for other computers than the local computer."
        Exit 1
    }
}

if ($Delete) {
    Echo-Log "The -Delete command line parameter was used."
    if ($Update -or $Swap) {
        Echo-Log "ERROR: Invalid commmand line parameter combination used."
    }
    if ([string]::IsNullorEmpty($Computername)) {
        Echo-Log "The -Computername command line parameter was not used."
        Echo-Log "Using local computername."
        $Computername = $env:Computername
    }
}
if ($Remove) {
    Echo-Log "The -Remove command line parameter was used."
    if ($Update -or $Swap) {
        Echo-Log "ERROR: Invalid commmand line parameter combination used."
    }
    if ([string]::IsNullorEmpty($Computername)) {
        Echo-Log "The -Computername command line parameter was not used."
        Echo-Log "Using local computername."
        $Computername = $env:Computername
    }
}

if ($Swap) {
    Echo-Log "The -Swap command line parameter was used."
    if ($Update -or $Delete -or $Remove) {
        Echo-Log "ERROR: Invalid commmand line parameter combination used."
    }
    if ($Update) {
        Echo-Log "The -Update command line parameter was used."
    }
    if ([string]::IsNullorEmpty($Computername)) {
        Echo-Log "ERROR: The -Computername command line parameter was not used."
        Exit 1
    }
}

if ($Force) {
    Echo-Log "The -Force command line parameter was used. Changes are forced, even if not needed."
}

# Create MSSQL connection
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$glb_UDL = $scriptPath + '\MDT.udl'
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

$SNR = Get-CimInstance -ClassName Win32_BIOS
Echo-Log "Local computer name: $env:Computername"
Echo-Log "Local serial number: $($SNR.SerialNumber)"
Echo-Log "Searching MDT database for serialnumber $($SNR.SerialNumber)..."

$query = "select SerialNumber,MacAddress,ID,Computername from dbo.ComputerSettings where SerialNumber='$($SNR.SerialNumber)'"
$data = Query-SQL $query $Global:UDLConnection
if ($data) {
    $MDTComputerID = $data.ID
    $MDTComputerName = $data.Computername
    $MDTMacAddress = $data.MacAddress

    Echo-Log ("MDT ID:            $MDTComputerID")
    Echo-Log ("MDT Computer name: $MDTComputerName")
    Echo-Log ("MDT MAC address:   $MDTMacAddress")
    Echo-Log ""

    # If we have a valid MDT registered computer, retrieve network information.
    if ($MDTComputerName -eq $env:Computername) {
        # Search the network adapter with the MDT registered MAC address
        $NetworkAdapter = Get-CimInstance -Classname Win32_NetworkAdapter |
            Where-Object { ($_.PhysicalAdapter) -eq 'TRUE' } |
            Where-Object { ($_.MACAddress) -eq $MDTMacAddress }

        if ($NetworkAdapter) {
            $DeviceIndex = $NetworkAdapter.Index
            $Name = $NetworkAdapter.Name
            Echo-Log "Network adapter:"
            Echo-Log "  Index: $DeviceIndex"
            Echo-Log "  Name:  $Name"

            # Retrieve speed and duplex mode information
            $NicInfo = Get-NICSpeedDuplex $DeviceIndex
            Echo-Log "  Speed and duplex mode: $($NicInfo.SpeedDuplexMode)"

            # Retrieve network adapter IP configuration.
            $NetworkAdapterConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
                Where-Object { ($_.Index -eq $DeviceIndex) }

            # Store current information in MDT
            Update-MDTComputerNIC -MDTComputerName $MDTComputerName `
                -MDTComputerID $MDTComputerID `
                -NetworkAdapter $NetworkAdapter `
                -NetworkAdapterConfig $NetworkAdapterConfig `
                -NicInfo $NicInfo

            if ($Update) {
                if (($NetworkAdapterConfig.DHCPEnabled -ne 'TRUE')) {
                    Echo-Log ("-" * 80)
                    Echo-Log 'WARNING: The local adapter is already set to a fixed IP address.'
                    Echo-Log ("-" * 80)
                }

                If (($NetworkAdapterConfig.DHCPEnabled -eq 'TRUE') -or ($Force)) {
                    # Retrieve new IP address from MDT
                    $NewIPConfig = Get-NewIpConfig -MDTComputerID $MDTComputerID -UDLConnection $Global:UDLConnection
                    if ($NewIPConfig) {
                        # Update adapter if requested
                        if ($Update -or $Force) {
                            Echo-Log ("-" * 80)
                            Echo-Log "Configuring adapter with static IP address: $($NewIPConfig.IPaddress)"
                            if (!$Force) {
                                Set-WMINetConfigStaticIP -NetworkAdapterConfig $NetworkAdapterConfig -IPConfig $NewIPConfig
                            }
                            else {
                                Set-WMINetConfigStaticIP -NetworkAdapterConfig $NetworkAdapterConfig -IPConfig $NewIPConfig -Force
                            }
                            Echo-Log ("-" * 80)
                        }
                        else {
                            Echo-Log ("-" * 80)
                            Echo-Log "The -Update command line parameter is not set. No changes are made"
                            Echo-Log ("-" * 80)
                        }
                    }
                    else {
                        Echo-Log ("* " * 40)
                        Echo-Log "ERROR: No reserved IP address information was received."
                        Echo-Log ("* " * 40)
                    }
                }

                # Read new adapter and IP configuration..
                $NetworkAdapter = Get-CimInstance -Classname Win32_NetworkAdapter |
                    Where-Object { ($_.PhysicalAdapter) -eq 'TRUE' } |
                    Where-Object { ($_.MACAddress) -eq $MDTMacAddress }
                $NicInfo = Get-NICSpeedDuplex $DeviceIndex
                $NetworkAdapterConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
                    Where-Object { ($_.Index -eq $DeviceIndex) }

                # ...and save it to MDT
                Update-MDTComputerNIC -MDTComputerName $MDTComputerName `
                    -MDTComputerID $MDTComputerID `
                    -NetworkAdapter $NetworkAdapter `
                    -NetworkAdapterConfig $NetworkAdapterConfig `
                    -NicInfo $NicInfo
            }

            if ($Delete -or $Remove) {
                if ($Computername -eq $env:Computername) {
                    $RemoveID = $MDTComputerID
                    $RemoveComputerName = $MDTComputerName
                }
                else {
                    $query = "select SerialNumber,MacAddress,ID,Computername from dbo.ComputerSettings where Computername='$($Computername)'"
                    $data = Query-SQL $query $Global:UDLConnection
                    $RemoveID = $data.ID
                    $RemoveComputerName = $data.Computername
                }

                Echo-Log "Removing IP reservation for computer:"
                Echo-Log ("MDT ID:            $RemoveID")
                Echo-Log ("MDT Computer name: $RemoveComputerName")

                $Count = [int](Remove-NewIpConfig -MDTComputerID $RemoveID)
                if ($Count -ne 0) {
                    Echo-Log "SUCCESS: Removed $Count reserved IP record."
                }
                else {
                    Echo-Log "ERROR: No reserved IP address was removed."
                }

                if ($Computername -eq $env:Computername) {
                    if (!$Force) {
                        Set-WMINetConfigStaticDHCP -NetworkAdapterConfig $NetworkAdapterConfig
                    }
                    else {
                        Set-WMINetConfigStaticDHCP -NetworkAdapterConfig $NetworkAdapterConfig -Force
                    }
                }
            }

            if ($Swap) {
                if ($Computername -eq $env:Computername) {
                    Echo-Log "ERROR: You cannot swap the static IP address from this computer with its own name."
                }
                else {
                    $OriginID = $MDTComputerID

                    $query = "select SerialNumber,MacAddress,ID,Computername from dbo.ComputerSettings where Computername='$($Computername)'"
                    $data = Query-SQL $query $Global:UDLConnection
                    $DestinID = $data.ID
                    $DestinComputerName = $data.Computername

                    echo-log "Swapping IP address reservation from '$MDTComputerName' to '$DestinComputerName' with ID '$DestinID'"

                    if (!$Force) {
                        Set-WMINetConfigStaticDHCP -NetworkAdapterConfig $NetworkAdapterConfig
                    }
                    else {
                        Set-WMINetConfigStaticDHCP -NetworkAdapterConfig $NetworkAdapterConfig -Force
                    }

                }

            }
        }
        else {
            echo-log "ERROR: Cannot find a network interface."
            echo-Log "       No interface matches the MDT registered MAC Address $MDTMacAddress"
        }
    }
    else {
        Echo-Log ("ERROR: The serial number $($SNR.SerialNumber) does not match the computer name!")
        Echo-Log (        The MDT registered computer name is: $MDTComputerName)
    }
}
else {
    Echo-Log "ERROR: Cannot find any MDT registered computer with serial number: $($SNR.SerialNumber)"
}

# ---------------------------------------------------------
Echo-Log ''
Echo-Log 'End of cleanup script.'
$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log "Total running time : $min"
Echo-Log ("=" * 80)

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================