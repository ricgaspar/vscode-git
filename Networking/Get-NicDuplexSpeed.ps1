function test-duplex {
    [CmdletBinding()]
    param (
        [string]$computer = $env:Computername
    )
    BEGIN {
        $HKLM = 2147483650
        $reg = [wmiclass]"\\$computer\root\default:StdRegprov"
        $keyroot = "SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
    }

    PROCESS {

        Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computer -Filter "IPEnabled='$true'" |
            ForEach-Object {

            $data = $_.Caption -split "]"
            $suffix = $data[0].Substring(($data[0].length - 4), 4)
            $key = $keyroot + "\$suffix"

            $value = "*PhysicalMediaType"
            $pmt = $reg.GetDwordValue($HKLM, $key, $value)  ## REG_DWORD

            ## 0=Unspecified, 9=Wireless, 14=Ethernet
            if ($pmt.uValue -eq 14) {

                $nic = $_.GetRelated("Win32_NetworkAdapter") | Select-Object Speed, NetConnectionId

                $value = "*SpeedDuplex"
                $dup = $reg.GetStringValue($HKLM, $key, $value)  ## REG_SZ

                switch ($dup.sValue) {
                    "0" {$duplex = "Auto Negotiation"}
                    "1" {$duplex = "10Mbps \ Half Duplex"}
                    "2" {$duplex = "10Mbps \ Full Duplex"}
                    "3" {$duplex = "100Mbps \ Half Duplex"}
                    "4" {$duplex = "100Mbps \ Full Duplex"}
                }

                New-Object -TypeName PSObject -Property @{
                    ComputerName     = $computer
                    NetworkConnector = $($nic.NetConnectionID )
                    DuplexSetting    = $duplex
                    Speed            = $($nic.Speed)
                }

            } #if
        } #foreach
    } #process
} #function

Function Get-NICSpeedDuplex {
    Param (
        [String]$computer = $env:Computername
    )
    $key = "SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"

    Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Computer $computer -Filter "IPEnabled='$true'" | ForEach-Object {
        $suffix = $([String]$_.Index).PadLeft(4, "0")

        #get remote registry value of speed/duplex
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $service = $reg.OpenSubKey("$key\\$suffix\\Ndi").GetValue("Service")
        If ($service -imatch "usb") {
            # This USB device will not have a '*SpeedDuplex' key
            New-Object PSObject -Property @{
                "ComputerName" = $computer
                "Device"       = $_.Description
                "Speed/Duplex" = "USB Device"
            }
        }
        ElseIf ($service -imatch "netft") {
            # Microsoft Clustered Network will not have a '*SpeedDuplex' key
            New-Object PSObject -Property @{
                "ComputerName" = $computer
                "Device"       = $_.Description
                "Speed/Duplex" = "Cluster Device"
            }
        }
        Else {
            $speedduplex = $reg.OpenSubKey("$key\\$suffix").GetValue("*SpeedDuplex")
            if ($speedduplex) {
                $enums = "$key\$suffix\Ndi\Params\*SpeedDuplex\enum"
                New-Object PSObject -Property @{
                    "ComputerName" = $computer
                    "Device"       = $_.Description
                    "Speed/Duplex" = $reg.OpenSubKey($enums).GetValue($speedduplex)
                }
            }
            else {
                New-Object PSObject -Property @{
                    "ComputerName" = $computer
                    "Device"       = $_.Description
                    "Speed/Duplex" = "Cannot be determined."
                }
            }

        }
    }
}

Get-NICSpeedDuplex VDLNC01443