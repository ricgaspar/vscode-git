# =========================================================
# VDL Nedcar - Information Systems
#
# .SYNOPSIS
# 	VNB Validate Quality station configuration
#
# .CREATED_BY
# 	Marcel Jussen
#
# .CHANGE_DATE
# 	17-07-2018
#
# .DESCRIPTION
#	Checks Quality station configuration
#
# =========================================================
#Requires -version 4.0

[CmdletBinding()]
Param(
    [string]$Computername = $env:Computername
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
Function Get-AutoLogon {
    Param (
        [String]$Computername = $env:Computername
    )

    try {
        $key = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon"
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computername)

        $Result = @{
            'AutoAdminLogon' = $reg.OpenSubKey($key).GetValue("AutoAdminLogon")
            'DefaultDomainName' = $reg.OpenSubKey($key).GetValue("DefaultDomainName")
            'DefaultPassword' = $reg.OpenSubKey($key).GetValue("DefaultPassword")
            'DefaultUserName' = $reg.OpenSubKey($key).GetValue("DefaultUserName")
            'ForceAutologon' = $reg.OpenSubKey($key).GetValue("ForceAutoLogon")
        }
        Return $Result
    }
    catch {
        Return $null
    }
}
Function Get-NICSpeedDuplex {
    Param (
        [String]$Computername,
        [String]$DeviceIndex
    )
    $key = "SYSTEM\\CurrentControlSet\\Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}"

    Get-WmiObject -Computername $Computername -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $DeviceIndex } | ForEach-Object {
        $suffix = $([String]$_.Index).PadLeft(4, "0")

        #get remote registry value of speed/duplex
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computername)
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

# =========================================================
Clear-Host

# Record start of script.
$BaseStart = Get-Date
$Global:ScriptStart = Get-Date

# Create default folder structure if it is not there already
$LogFolderPath = "$env:SYSTEMDRIVE\Logboek"
[void]( Create-FolderStruct $LogFolderPath)
$ScriptLog = Join-Path -Path $LogFolderPath -ChildPath 'VNB-QST-Validate.log'
$Global:glb_EVENTLOGFile = $ScriptLog
[void](Init-Log -LogFileName $ScriptLog $False -alternate_location $True)

Echo-Log ("=" * 80)
Echo-Log "Starting script."
# ---------------------------------------------------------

# Create MSSQL connection
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$glb_UDL = $scriptPath + '\MDT.udl'
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

$SNR = Get-CimInstance -ClassName Win32_BIOS
Echo-Log "Local computer name: $env:Computername"
Echo-Log "Searching MDT database for serialnumber $($Computername)..."

$query = "select SerialNumber,MacAddress,ID,OSDComputername from dbo.ComputerSettings where OSDComputername='$($Computername)'"
$data = Query-SQL $query $Global:UDLConnection
if ($data) {
    $MDTComputerID = $data.ID
    $MDTComputerName = $data.OSDComputername
    $MDTMacAddress = $data.MacAddress

    Echo-Log ("MDT ID:            $MDTComputerID")
    Echo-Log ("MDT Computer name: $MDTComputerName")
    Echo-Log ("MDT MAC address:   $MDTMacAddress")
    Echo-Log ""

    # If we have a valid MDT registered computer, retrieve network information.
    if ($MDTComputerName -eq $Computername) {
        # Search the network adapter with the MDT registered MAC address
        $NetworkAdapter = Get-CimInstance -ComputerName $Computername -Classname Win32_NetworkAdapter |
            Where-Object { ($_.PhysicalAdapter) -eq 'TRUE' } |
            Where-Object { ($_.MACAddress) -eq $MDTMacAddress }

        if ($NetworkAdapter) {
            $DeviceIndex = $NetworkAdapter.Index
            $Name = $NetworkAdapter.Name
            Echo-Log "Network adapter:"
            Echo-Log "  Index: $DeviceIndex"
            Echo-Log "  Name : $Name"

            # Retrieve network adapter IP configuration.
            $NetworkAdapterConfig = Get-WmiObject -Computername $Computername -Class Win32_NetworkAdapterConfiguration |
                Where-Object { ($_.Index -eq $DeviceIndex) }

            $CHK_NIC_DHCP = ($NetworkAdapterConfig.DHCPEnabled -ne 'TRUE')
            Echo-Log ("-" * 80)
            Echo-Log "IP Configuration checks:"
            if ($CHK_NIC_DHCP) {
                Echo-Log '- The network adapter is set to a fixed IP address. DHCP is not used.'
            }
            else {
                echo-log "* ERROR: The network adapter is not using a fixed IP address."
            }

            $IPAddress0 = $($NetworkAdapterConfig.IPAddress[0])
            Echo-Log "- Current IP address $IPAddress0"
            $CHK_IP_SUBNET = $False
            if ($IPaddress0 -match '10.30.120.') { $CHK_IP_SUBNET = $True }
            if ($IPaddress0 -match '10.30.121.') { $CHK_IP_SUBNET = $True }
            if (!$CHK_IP_SUBNET) {
                Echo-Log "* ERROR: The IP address is not located in the correct subnet."
            }
            else {
                Echo-Log "- The IP address is located in the correct subnet."
            }

            # Retrieve speed and duplex mode information
            $NicInfo = Get-NICSpeedDuplex -Computername $Computername -DeviceIndex $DeviceIndex
            Echo-Log ("-" * 80)
            Echo-Log "Network driver settings:"
            Echo-Log "- Driver mode: $($NicInfo.SpeedDuplexMode)"

            $Speed = $($NetworkAdapter.Speed)
            $MSpeed = "$Speed bps"
            $CHK_NIC_SPEED = $False
            if ($Speed -eq 1000000000) {
                $MSpeed = '1 Gigabit/sec'
                $CHK_NIC_SPEED = $True
            }
            if ($Speed -eq 100000000) { $MSpeed = '100 Megabit/sec' }
            if ($Speed -eq 10000000) { $MSpeed = '10 Megabit/sec' }
            Echo-Log "- Network speed: $($MSpeed)"

            if (!$CHK_NIC_SPEED) {
                Echo-Log "* ERROR: The network speed is not correctly set to 1 Gpbs."
            }
            else {
                Echo-Log "- The network speed is set to 1 Gpbs."
            }

            Echo-Log ("-" * 80)
            Echo-Log "Active Directory check:"
            $DN = Get-ADComputerDN -Computername $Computername
            $DN = $DN -Replace 'LDAP://', ''
            $DN = $DN -Replace ',DC=nedcar,DC=nl', ''
            $CHK_AD_DN = $False
            If ($DN -match 'OU=Factory') {
                Echo-Log "- The computer object is part of the 'Factory' OU."
                If ($DN -match "CN=$Computername,OU=ALC") {
                    Echo-Log "- The computer object is part of a 'ALCx' OU."
                    $CHK_AD_DN = $True
                }
                else {
                    Echo-Log "* The computer object is not part of a 'ALCx' OU."
                }
            }
            else {
                Echo-Log "* ERROR: The computer object is not part of the 'Factory' OU."
            }

            if (!$CHK_AD_DN) {
                Echo-Log "* The computer object location in Active Directory is not correctly set."
                Echo-Log "* '$($DN)'"
            }
            else {
                Echo-Log "- The computer object location in Active Directory is correct."
            }

            Echo-Log ("-" * 80)
            Echo-Log "Console user check:"
            $ConsoleUser = Get-WMIObject -Computername $Computername -class Win32_ComputerSystem | Select-Object username
            $ConsoleUserName = ($ConsoleUser.Username).ToUpper()
            $CHK_CONSOLE_USER = ($($ConsoleUserName) -eq 'NEDCAR\FAPCALC')
            IF ($CHK_CONSOLE_USER) {
                Echo-Log '- The user FAPCALC is logged on.'
            }
            else {
                Echo-Log '* ERROR: The user FAPCALC is not logged on.'
                Echo-Log "*        Current console user: $($ConsoleUserName)"
            }

            Echo-Log ("-" * 80)
            Echo-Log "ALC Client application check:"
            if ($COmputername -eq $env:Computername) {
                $AppPath = 'C:\Program Files\VDLNedcar\ALCMClient\1.0.7\ALCM Client.cmd'
            }
            else {
                $AppPath = "\\$Computername\C$\Program Files\VDLNedcar\ALCMClient\1.0.7\ALCM Client.cmd"
            }
            $CHK_APP_PATH = (Exists-File $AppPath)
            if ($CHK_APP_PATH) {
                Echo-Log "- The startup script for the ALCM client was found."
            }
            else {
                Echo-Log "* ERROR: Cannot find ALCM client startup script."
            }

            $AutoShortcut = "AutoStart ALCM Client.lnk"
            if ($Computername -eq $env:Computername) {
                $AutoAppPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"
            }
            else {
                $AutoAppPath = "\\$Computername\C$\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"
            }

            $ChkAutoShortcut = Join-Path -Path $AutoAppPath -ChildPath $AutoShortCut
            $CHK_START_PATH = (Exists-File $ChkAutoShortcut)
            if ($CHK_START_PATH) {
                Echo-Log "- The auto startup shortcut for the ALCM client was found."
            }
            else {
                Echo-Log "* ERROR: Cannot find the auto startop shortcut for the ALCM client."
            }

            Echo-Log ("-" * 80)
            Echo-Log "Autologon registry check:"
            $CHK_REG_AUTOLOGON = $True
            $AutoLogon = Get-AutoLogon -Computername $Computername
            if ($AutoLogon) {
                if ($($Autologon.AutoAdminLogon) -ne '1') {
                    Echo-Log "* AutoAdminLogon: [$($Autologon.AutoAdminLogon)]"
                    $CHK_REG_AUTOLOGON = $False
                }

                if ($($Autologon.ForceAutoLogon) -ne '1') {
                    Echo-Log "* ForceAutoLogon: [$($Autologon.ForceAutoLogon)]"
                    $CHK_REG_AUTOLOGON = $False
                }

                if ($($Autologon.DefaultDomainName) -ne 'nedcar') {
                    Echo-Log "* DefaultDomainName: [$($Autologon.DefaultDomainName)]"
                    $CHK_REG_AUTOLOGON = $False
                }

                if ($($Autologon.DefaultUsername) -ne 'fapcalc') {
                    Echo-Log "* DefaultUsername: [$($Autologon.DefaultUsername)]"
                    $CHK_REG_AUTOLOGON = $False
                }

                if ($($Autologon.DefaultPassword) -ne 'fapcalc') {
                    Echo-Log "* DefaultPassword: [$($Autologon.DefaultPassword)]"
                    $CHK_REG_AUTOLOGON = $False
                }

            }
            else {
                Echo-Log "* ERROR: The registry values are incomplete or could not be checked!"
                $CHK_REG_AUTOLOGON = $False
            }

            if ($CHK_REG_AUTOLOGON -eq $False) {

                Echo-Log "* One or more Autologon registry values are incorrect."
            }
            else {
                Echo-Log "- The Autologon registry values are correct."
            }
        }
        else {
            Echo-Log ("ERROR: The serial number $($SNR.SerialNumber) does not match the computer name!")
            Echo-Log (        The MDT registered computer name is: $MDTComputerName)
        }
    }
    else {
        Echo-Log "ERROR: Cannot find any MDT registered computer."
    }
}
# ---------------------------------------------------------
Echo-Log ''
Echo-Log 'End of validate script.'
$min = New-TimeSpan -Start ($BaseStart) -End (Get-Date)
Echo-Log "Total running time : $min"
Echo-Log ("=" * 80)

# =========================================================
Close-LogSystem

# =========================================================
# Thats all folks..
# =========================================================