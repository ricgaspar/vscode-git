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
    [Parameter(Mandatory = $true)]
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

$Global:ALCMPartPath = 'Program Files\VDLNedcar\ALCMClient\1.0.7'

# ---------------------------------------------------------
Function Get-AutoLogon {
    Param (
        [String]$Computername = $env:Computername
    )

    try {
        $key = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon"
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computername)

        $Result = @{
            'AutoAdminLogon'    = $reg.OpenSubKey($key).GetValue("AutoAdminLogon")
            'DefaultDomainName' = $reg.OpenSubKey($key).GetValue("DefaultDomainName")
            'DefaultPassword'   = $reg.OpenSubKey($key).GetValue("DefaultPassword")
            'DefaultUserName'   = $reg.OpenSubKey($key).GetValue("DefaultUserName")
            'ForceAutologon'    = $reg.OpenSubKey($key).GetValue("ForceAutoLogon")
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

function Get-RemoteUptime {
    Param (
        [String]$Computername
    )
    $os = Get-WmiObject win32_operatingsystem -Computername $Computername
    $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
    $Result = "Uptime: " + $Uptime.Days + " days, " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes"
    Return $Result
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
$glb_UDL = Join-Path -Path $scriptPath -ChildPath 'MDT.udl'
$Global:UDLConnection = Read-UDLConnectionString $glb_UDL

Echo-Log "Searching MDT database for OSDComputername $($Computername)..."

$query = "select SerialNumber,MacAddress,ID,OSDComputername from dbo.ComputerSettings where OSDComputername='$($Computername)'"
$data = Query-SQL $query $Global:UDLConnection
if ($data) {
    Echo-Log "The MDT query was successfull."
    $MDTComputerID = $data.ID
    $MDTComputerName = $data.OSDComputername
    $MDTMacAddress = $data.MacAddress
    $MDTSerialNumber = $data.SerialNumber

    Echo-Log ("MDT ID:            $MDTComputerID")
    Echo-Log ("MDT Computer name: $MDTComputerName")
    Echo-Log ("MDT MAC address:   $MDTMacAddress")

    # Lets see if we can query the requested computer.
    try {
        $SNR = (Get-CimInstance -ClassName Win32_BIOS -Computername $Computername | Select-Object SerialNumber).SerialNumber
    }
    catch {
        $SNR = $null
    }

    # If we have a MDT registered computer with valid serialnumber, retrieve network information.
    if ($SNR -eq $MDTSerialNumber) {
        Echo-Log ("-" * 80)
        Echo-Log "The (remote) computer accepts WMI connections."

        # Search the network adapter with the MDT registered MAC address
        $NetworkAdapter = Get-CimInstance -ComputerName $Computername -Classname Win32_NetworkAdapter |
            Where-Object { ($_.PhysicalAdapter) -eq 'TRUE' } |
            Where-Object { ($_.MACAddress) -eq $MDTMacAddress }

        if ($NetworkAdapter) {
            $DeviceIndex = $NetworkAdapter.Index
            Echo-Log "Network adapter:"
            Echo-Log "  Name : $($NetworkAdapter.Name)"
            Echo-Log "  MAC  : $($NetworkAdapter.MACAddress)"

            Echo-Log ("-" * 80)
            $uptime = Get-RemoteUptime -Computername $Computername
            if ($uptime) {
                Echo-Log "Computer uptime: $uptime"
            }
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
            $ProcessExe = 'jp2launcher.exe', 'java.exe'
            $CHK_PROC_ALCM=$False
            $Process = Get-WMIOBject -Computername $Computername -class Win32_Process |
                Select-Object ProcessId, ProcessName, ExecutablePath
            Foreach ($Prc in $ProcessExe) {
                Echo-Log "Running process '$Prc' check:"
                $ALCMProcess = $Process | Where-Object { $_.ProcessName -eq $Prc }
                if ($ALCMProcess) {
                    Echo-Log "- (ID: $($ALCMProcess.ProcessId)) $($ALCMProcess.ProcessName)"
                    Echo-Log "  Path $($ALCMProcess.ExecutablePath)"

                    if ($Prc -eq 'jp2launcher.exe') {
                        if ($($ALCMProcess.ExecutablePath) -like "*$Global:ALCMPartPath*") {
                            $CHK_PROC_ALCM = $True
                        }
                    }
                }
                else {
                    Echo-Log "* ERROR: No jp2launcher process was found in a running state."
                }
            }

            if ($CHK_PROC_ALCM) {
                Echo-Log "- The ALCM client is found in a running state."
            }
            else {
                Echo-Log "* ERROR:The ALCM client is not found in a running state."
            }

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
                    Echo-Log "- The computer object is part of a 'ALC(x)' OU."
                    $CHK_AD_DN = $True
                }
                else {
                    Echo-Log "* The computer object is not part of a 'ALC(x)' OU."
                }
            }
            else {
                Echo-Log "* ERROR: The computer object is not part of the 'Factory' OU."
            }

            if (!$CHK_AD_DN) {
                Echo-Log "* The computer object location in Active Directory is invalid."
                Echo-Log "* '$($DN)'"
            }
            else {
                Echo-Log "- The computer object location in Active Directory is correct."
            }

            Echo-Log ("-" * 80)
            Echo-Log "ALC Client application check:"
            if ($COmputername -eq $env:Computername) {
                $AppPath = "C:\$Global:ALCMPartPath\ALCM Client.cmd"
            }
            else {
                $AppPath = "\\$Computername\C$\$Global:ALCMPartPath\ALCM Client.cmd"
            }
            $CHK_APP_PATH = (Exists-File $AppPath)
            if ($CHK_APP_PATH) {
                Echo-Log "- The application path and start script for the ALCM client was found."
            }
            else {
                Echo-Log "* ERROR: Cannot find ALCM client application path or startup script."
                Echo-Log "         Missing: $AppPath"
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
                Echo-Log "*        Missing: $AutoShortcut"
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
            Echo-Log ("-" * 80)
        }
        else {
            Echo-Log ("ERROR: No networkadapter with MAC: '$MDTMacAddress' was found on this computer.")
        }
    }
    else {
        if ([string]::IsNullorEmpty($SNR)) {
            Echo-Log "ERROR: The serialnumber was null or empty."
            Echo-Log "       The (remote) computer is switched off or could not be contacted over the network."
        }
        else {
            Echo-Log "ERROR: The MDT registered serialnumber '$MDTSerialNumber' does not match '$SNR'"
        }

    }
}
else {
    Echo-Log "ERROR: Cannot find any MDT registered computer by the OSDComputername '$($Computername)'."
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