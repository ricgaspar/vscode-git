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
    [switch]$Force,
    [switch]$Update
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

Function Set-WMINetConfig {
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
            Echo-Log ''
        }
    }
    else {
        Echo-Log "No changes are made. The current IP address is correct."
    }
}

Function Update-MDTComputerNIC {
    [CmdletBinding()]
    param (
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
    Insert-Record -Computername $Computername -ObjectName $ObjectName -ObjectData $ObjectData -Erase $True
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
        $NewIPConfig = @{
            'IPAddress'      = $($data.IPReserved)
            'Gateway'        = '10.30.120.1'
            'Netmask'        = '255.255.254.0'
            'DNSSearchOrder' = "10.30.20.10", "10.30.20.11"
        }
    }
    return $NewIPConfig
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

if ($force) {
    Echo-Log "The -Force command line parameter was used. Changes are forced, even if not needed."
}

# Create MSSQL connection
$glb_UDL = '.\MDT.udl'
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL
$Computername = $env:Computername

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

    if ($MDTComputerName -eq $env:Computername) {
        $NetworkAdapter = Get-CimInstance -Classname Win32_NetworkAdapter |
            Where-Object { ($_.PhysicalAdapter) -eq 'TRUE' } |
            Where-Object { ($_.MACAddress) -eq $MDTMacAddress }

        if ($NetworkAdapter) {

            $DeviceIndex = $NetworkAdapter.Index
            $Name = $NetworkAdapter.Name
            Echo-Log "Network adapter:"
            Echo-Log "  Index: $DeviceIndex"
            Echo-Log "  Name:  $Name"

            $NicInfo = Get-NICSpeedDuplex $DeviceIndex
            Echo-Log "  Speed and duplex mode: $($NicInfo.SpeedDuplexMode)"

            $NetworkAdapterConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
                Where-Object { ($_.Index -eq $DeviceIndex) }

            if (($NetworkAdapterConfig.DHCPEnabled -eq 'TRUE') -or ($Force)) {

                if (($NetworkAdapterConfig.DHCPEnabled -ne 'TRUE')) {
                    Echo-Log ("-" * 80)
                    Echo-Log 'WARNING: The adapter is already set to a fixed IP address.'
                    Echo-Log ("-" * 80)
                }

                # Store current information in MDT
                Update-MDTComputerNIC -MDTComputerID $MDTComputerID -NetworkAdapter $NetworkAdapter -NetworkAdapterConfig $NetworkAdapterConfig -NicInfo $NicInfo

                # Retrieve new IP address from MDT
                $NewIPConfig = Get-NewIpConfig -MDTComputerID $MDTComputerID -UDLConnection $Global:UDLConnection
                if ($NewIPConfig) {
                    # Update adapter if requested
                    if ($Update -or $Force) {
                        Echo-Log ("-" * 80)
                        Echo-Log "Configuring adapter with static IP address: $($NewIPConfig.IPaddress)"

                        if (!$Force) {
                            Set-WMINetConfig -NetworkAdapterConfig $NetworkAdapterConfig -IPConfig $NewIPConfig
                        }
                        else {
                            Set-WMINetConfig -NetworkAdapterConfig $NetworkAdapterConfig -IPConfig $NewIPConfig -Force
                        }

                        Echo-Log ("-" * 80)

                        $NetworkAdapter = Get-CimInstance -Classname Win32_NetworkAdapter |
                            Where-Object { ($_.PhysicalAdapter) -eq 'TRUE' } |
                            Where-Object { ($_.MACAddress) -eq $MDTMacAddress }
                        $NicInfo = Get-NICSpeedDuplex $DeviceIndex
                        $NetworkAdapterConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
                            Where-Object { ($_.Index -eq $DeviceIndex) }
                        Update-MDTComputerNIC -MDTComputerID $MDTComputerID -NetworkAdapter $NetworkAdapter -NetworkAdapterConfig $NetworkAdapterConfig -NicInfo $NicInfo
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
            else {
                Echo-Log ("-" * 80)
                Echo-Log 'WARNING: The adapter is not DHCP enabled and has a static IP address.'
                Echo-Log '         Use the -Force parameter to force changes.'
                Echo-Log ("-" * 80)
                Echo-Log "Current IP configuration:"
                Echo-Log "  IP Address: $($NetworkAdapterConfig.IPAddress[0])"
                Echo-Log "  Net mask  : $($NetworkAdapterConfig.IPSubnet[0])"
                Echo-Log "  Gateway   : $($NetworkAdapterConfig.DefaultIPGateway[0])"
                Echo-Log "  DNS       : $($NetworkAdapterConfig.DNSServerSearchOrder)"
            }
        }
        else {
            echo-log "ERROR: Cannot find a network interface."
            echo-Log "       No interface  matches the MDT registered MAC Address $MDTMacAddress"
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
Echo-Log "End of cleanup script."
$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log "Total running time : $min"
Echo-Log ("=" * 80)

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================