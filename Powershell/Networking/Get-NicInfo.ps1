function test-duplex {
    [CmdletBinding()]
    param (
        [string]$computer = "."
    )
    BEGIN {
        $HKLM = 2147483650
        $reg = [wmiclass]"\\$computer\root\default:StdRegprov"
        $keyroot = "SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
    }

    PROCESS {

        Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computer -Filter "IPEnabled='$true'" |
            Foreach-Object {

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
                    "0" {$duplex = "Auto Detect"}
                    "1" {$duplex = "10Mbps \ Half Duplex"}
                    "2" {$duplex = "10Mbps \ Full Duplex"}
                    "3" {$duplex = "100Mbps \ Half Duplex"}
                    "4" {$duplex = "100Mbps \ Full Duplex"}
                }

                New-Object -TypeName PSObject -Property @{
                    NetworkConnector = $($nic.NetConnectionID )
                    DuplexSetting    = $duplex
                    Speed            = $($nic.Speed)
                }

            } #if
        } #foreach
    } #process
} #function

test-duplex