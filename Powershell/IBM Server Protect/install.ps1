# =========================================================
#
# Execute a remote install/update of the IBM Spectrum Protect client software
#
# Marcel Jussen
# 31-01-2018
#
# =========================================================
#Requires -version 4.0

[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$Computername = $ENV:Computername,

    [ValidateNotNullOrEmpty()]
    [string]$InstallSource = '\\s031.nedcar.nl\IBMSP',

    [ValidateNotNullOrEmpty()]
    [string]$IBMSPSourcePath = 'TSM_814_Client_AMD64',

    [ValidateNotNullOrEmpty()]
    [switch]$Force = $False,

    [ValidateNotNullOrEmpty()]
    [switch]$NoTempCache = $False,

    [ValidateNotNullOrEmpty()]
    [switch]$SkipTempCache = $False
)

# ---------------------------------------------------------
# Includes
Import-Module VNB_PSLib -Force -ErrorAction Stop

Function Test-CIMFolder {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$Path
    )
    Get-CimInstance -Computername $Computername -Query "ASSOCIATORS OF {Win32_Directory.Name='$Path'} where ResultClass=CIM_Directory"
}

Function Test-CIMFile {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$Path
    )
    # What drive are we searching
    $DriveLetter = ($Path.Split(":")).Get(0) + ':'
    $SubPath = $Path -replace ('\\', '\\')
    $Filter = "Drive='$DriveLetter' and Name='$SubPath'"
    $FoundPath = Get-CimInstance Cim_DataFile -Computer $Computername -Filter $Filter
    Return $FoundPath
}

Function Get-BackupClientInfo {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$SftPublisher = 'IBM',
        [string]$SftDisplayName = 'IBM Tivoli Storage Manager Client'
    )
    $retval = $null
    $UninstallKey = "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    Echo-Log "Searching registry key $UninstallKey"
    Echo-Log "  for displayname '$SftDisplayName'"
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $ComputerName)
    $regkey = $reg.OpenSubKey($UninstallKey)
    $subkeys = $regkey.GetSubKeyNames()
    foreach ($key in $subkeys) {
        $thisKey = $UninstallKey + "\\" + $key
        $thisSubKey = $reg.OpenSubKey($thisKey)
        $DisplayName = $thisSubKey.GetValue("DisplayName")
        $DisplayVersion = $thisSubKey.GetValue("DisplayVersion")
        $Publisher = $thisSubKey.GetValue("Publisher")
        if (($Publisher -eq $SftPublisher) -and ($DisplayName -eq $SftDisplayName)) {
            $retval = @{}
            $retval.Add("Publisher", $Publisher)
            $retval.Add("DisplayVersion", $DisplayVersion)
            $retval.Add("DisplayName", $DisplayName)
            $retval.Add("InstallDate", $thisSubKey.GetValue("InstallDate"))
            $retval.Add("InstallLocation", $thisSubKey.GetValue("InstallLocation"))
            $retval.Add("UninstallString", $thisSubKey.GetValue("UninstallString"))
            $retval.Add("Version", $thisSubKey.GetValue("Version"))
            $retval.Add("VersionMajor", $thisSubKey.GetValue("VersionMajor"))
            $retval.Add("VersionMinor", $thisSubKey.GetValue("VersionMinor"))
        }
    }
    Return $Retval
}

Function Get-CIMServicesWithPath {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$InstallLocation
    )

    Echo-Log "CIM retrieve backup services information from computer $Computername."
    Echo-Log "  using $InstallLocation for service path executables."
    $Services = Get-CimInstance Win32_Service -Computername $Computername | `
        Where-Object {$_.PathName -ne $null } | `
        Where-Object {$_.PathName.contains($InstallLocation)}
    Return $Services
}

Function New-RemoteCommand {
    [CmdletBinding()]
    param (
        [string]$Computername,
        [string]$Command
    )

    $RemoteProcess = ([wmiclass]"\\$Computername\root\cimv2:Win32_Process").create($Command)
    Switch ($RemoteProcess.returnvalue) {
        0 {$resultTxt = "Successful"}
        2 {$resultTxt = "Access denied"}
        3 {$resultTxt = "Insufficient privilege"}
        8 {$resultTxt = "Unknown failure"}
        9 {$resultTxt = "Path not found"}
        21 {$resultTxt = "Invalid parameter"}
        default {$resultTxt = "Unhandled error"}
    }
    $processId = $RemoteProcess.processId
    $processStatus = "unknown"
    $WaitForCompletion = $True
    if ($WaitForCompletion) {
        $wait = $true
        While ($wait) {
            Start-Sleep -Milliseconds 250
            $test = Get-WmiObject -Computer $Computername -query "select * from Win32_Process Where ProcessId='$processId'"
            if ((Measure-Object -InputObject $test).count -eq 0) {
                $wait = $false
            }
        }
        $processStatus = "completed"
    }
    Return $processStatus
}

Function Get-TempSourcePath {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$InstallSource,
        [string]$ClientSource,
        $SkipTempCache = $False
    )

    Echo-Log ("-" * 80)
    Echo-Log "Creating a local cached copy as an installation source."
    $TempInstallPath = $null
    $Drives = @('C:', 'D:')
    ForEach ($Drive in $Drives) {
        Echo-Log "Checking drive $Drive on $Computername for free disk space."
        $VolInfo = Get-CimInstance win32_logicaldisk -Computername $ComputerName | Where-Object { $_.DeviceID -eq $Drive }
        $VolFreeSpace = [int]0
        if ($VolInfo -ne $null) {
            [int]$VolFreeSpace = $VolInfo.FreeSpace / (1024 * 1024 * 1024)
        }
        # We need at least 2Gb free space
        if ($VolFreeSpace -ge 2) {
            Echo-Log "Found enough free space on $Drive [$VolFreeSpace Gb free]"
            $TempInstallPath = "$Drive\Temp\IBMSP_Install"
        }

        if($SkipTempCache -eq $True) {
            Echo-Log "Command line option -SkipTempCache used. Source copy is not applied."
            return $TempInstallPath
        }

        if ($TempInstallPath) {
            $RemoteInstallPath = '\\' + $Computername + '\' + ($TempInstallPath -replace ':', '$')
            Echo-Log "Creating temporary install path $RemoteInstallPath"
            New-Item -Path $RemoteInstallPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

            $CopySource = Join-Path -Path $InstallSource -ChildPath 'TSM_BA_CONFIG'
            Echo-Log "Copy source $CopySource to temporary install path."
            Copy-Item -Path $CopySource -Destination $RemoteInstallPath -Force -Recurse

            $CopySource = Join-Path -Path $ClientSource -ChildPath '*'
            Echo-Log "Copy source $CopySource to temporary install path."
            Copy-Item -Path $CopySource -Destination $RemoteInstallPath -Force -Recurse
            return $TempInstallPath
        }
    }
}
Function Install-Prereqs {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$InstallSource
    )

    Echo-Log ("-" * 80)
    $PrereqPath = Join-Path -Path $InstallSource -ChildPath 'tsmcli\x64\client\Disk1\ISSetupPrerequisites'
    Echo-Log "Installing prerequisites from folder:"
    Echo-Log "$PrereqPath"
    if (Test-CIMFolder -Computername $Computername -Path $PrereqPath) {
        $PreReqs = Get-ChildItem -Path $PrereqPath -Filter '*.exe' -File -Recurse
        ForEach ($Exe in $PreReqs) {
            Echo-Log "Installing $($Exe.Name)"
            $Command = $($Exe.Fullname) + ' /Q'
            $Status = New-RemoteCommand -Computername $Computername -Command $Command
            Echo-Log "Status: $Status"
        }
    }
    else {
        Echo-Log "ERROR: Cannot find prerequisites at the default location:"
        Echo-Log "       $PrereqPath"
    }
}

Function Install-IBMSPClient {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$InstallSource
    )

    Echo-Log ("-" * 80)
    Echo-Log "Installing IBM Spectrum Protect Client."
    $IBMSP_InstallPath = Join-Path -Path $ENV:ProgramFiles -ChildPath 'Tivoli\TSM'
    Echo-Log "Destination path: $IBMSP_InstallPath"

    $IBMSP_AddLocal = "BackupArchiveGUI,BackupArchiveWeb,AdministrativeCmd"
    Echo-Log "Using command line parameters: $IBMSP_AddLocal"

    $MSIPath = Join-Path -Path $InstallSource -ChildPath 'tsmcli\x64\client\Disk1\IBM Spectrum Protect Client.msi'
    Echo-Log "Start MSI installation."
    Echo-Log "$MSIPath"

    $Command = 'C:\Windows\System32\msiexec.exe /i ' + [char]34 + $MSIPAth + [char]34
    $Command = $Command + ' RebootYesNo=' + [char]34 + 'No' + [char]34
    $Command = $Command + ' REBOOT=' + [char]34 + 'Suppress' + [char]34
    $Command = $Command + ' ALLUSERS=1'
    $Command = $Command + ' INSTALLDIR=' + [char]34 + $IBMSP_InstallPath + [char]34
    $Command = $Command + ' ADDLOCAL=' + [char]34 + $IBMSP_AddLocal + [char]34
    $Command = $Command + ' TRANSFORMS=1033.mst /quiet /norestart'
    $Command = $Command + ' /l*v C:\Logboek\IBM_SP_Install.log'

    $Status = New-RemoteCommand -Computername $Computername -Command $Command
    Echo-Log "Status: $Status"

    return $IBMSP_InstallPath
}
Function New-IBMSPClientConfig {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$InstallSource,
        [string]$IBMSP_InstallPath
    )

    Echo-Log ("-" * 80)
    Echo-Log ("Copy new config files to backup client software on computer $SystemName")

    $IBMSP_ClientPath = Join-Path -Path $IBMSP_InstallPath -ChildPath 'baclient'
    $IBMSP_ClientPath = "\\$Computername\$IBMSP_ClientPath"
    $IBMSP_ClientPath = $IBMSP_ClientPath -replace(':','$')
    Echo-Log "Client path: $IBMSP_ClientPath"

    $DSMOpt = Join-Path -Path $InstallSource -ChildPath 'TSM_BA_CONFIG\dsm.opt'
    $InclExcl = Join-Path -Path $InstallSource -ChildPath 'TSM_BA_CONFIG\inclexcl.dsm'
    $CertFile = Join-Path -Path $InstallSource -ChildPath 'TSM_BA_CONFIG\cert256_s202.arm'

    echo-Log "Copy DSM option file $DSMOpt"
    echo-Log "  to $IBMSP_ClientPath"
    Copy-Item -Path $DSMOpt -Destination $IBMSP_ClientPath -Force -ErrorAction SilentlyContinue

    echo-Log "Copy Include/Exclude option file $InclExcl"
    echo-Log "  to $IBMSP_ClientPath"
    Copy-Item -Path $InclExcl -Destination $IBMSP_ClientPath -Force -ErrorAction SilentlyContinue

    echo-Log "Copy certificate file $CertFile"
    echo-Log "  to $IBMSP_ClientPath"
    Copy-Item -Path $CertFile -Destination $IBMSP_ClientPath -Force -ErrorAction SilentlyContinue

}

Function Update-IBMSPClientCertificate {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$InstallSource,
        [string]$IBMSP_InstallPath
    )

    Echo-Log ("-" * 80)
    Echo-Log ("Configuring backup client software on computer $SystemName")

    $IBMSP_ClientPath = Join-Path -Path $IBMSP_InstallPath -ChildPath 'baclient'
    Echo-Log "Client path: $IBMSP_ClientPath"
    $CertFile = Join-Path -Path $InstallSource -ChildPath 'TSM_BA_CONFIG\cert256_s202.arm'

    $CopyToPath = "\\$Computername\$IBMSP_ClientPath"
    $CopyToPath = $CopyToPath -replace (':', '$')

    echo-Log "Copy certificate file $CertFile"
    echo-Log "  to $CopyToPath"
    Copy-Item -Path $CertFile -Destination $CopyToPath -Force -ErrorAction STOP
}

Function Remove-BackupServices {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$IBMSP_InstallPath,
        [string]$BAClientInstallPath
    )

    Echo-Log ("-" * 80)
    Echo-Log ("Remove pre-existing TSM backup client services on computer $SystemName")
    $IBMSP_ClientPath = Join-Path -Path $IBMSP_InstallPath -ChildPath 'baclient'
    Echo-Log "Client path: $IBMSP_ClientPath"

    $ServicesCollection = Get-CIMServicesWithPath -Computername $Computername -InstallLocation $BAClientInstallPath
    foreach ($Service in $ServicesCollection) {
        $TSM_SRV = [char]34 + $Service.Name + [char]34
        Echo-Log "Remove pre-existing service: $TSM_SRV"
        $DSMCUTIL = Join-Path $IBMSP_ClientPath -ChildPath "dsmcutil.exe"
        $Command = [char]34 + $DSMCUTIL + [char]34
        $Command = $Command + ' remove'
        $Command = $Command + ' /name:' + $TSM_SRV
        $Status = New-RemoteCommand -Computername $Computername -Command $Command
        Echo-Log "Process status: $Status"
    }
}
Function Remove-IBMSPServices {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$IBMSP_InstallPath
    )

    Echo-Log ("-" * 80)
    Echo-Log ("Remove pre-existing IBM SP backup client services on computer $SystemName")

    $IBMSP_ClientPath = Join-Path -Path $IBMSP_InstallPath -ChildPath 'baclient'
    Echo-Log "Client path: $IBMSP_ClientPath"

    # Remove existing Scheduler
    $IBMSP_SCHEDSRV = [char]34 + 'IBMSP Client Scheduler' + [char]34
    Echo-Log "Remove pre-existing service: $IBMSP_SCHEDSRV"
    $DSMCUTIL = Join-Path $IBMSP_ClientPath -ChildPath "dsmcutil.exe"
    $Command = [char]34 + $DSMCUTIL + [char]34
    $Command = $Command + ' remove'
    $Command = $Command + ' /name:' + $IBMSP_SCHEDSRV
    $Status = New-RemoteCommand -Computername $Computername -Command $Command
    Echo-Log "Process status: $Status"

    # Remove existing CAD
    $IBMSP_CADSRV = [char]34 + 'IBMSP Client Acceptor Daemon' + [char]34
    Echo-Log "Remove pre-existing service: $IBMSP_CADSRV"
    $DSMCUTIL = Join-Path $IBMSP_ClientPath -ChildPath "dsmcutil.exe"
    $Command = [char]34 + $DSMCUTIL + [char]34
    $Command = $Command + ' remove'
    $Command = $Command + ' /name:' + $IBMSP_CADSRV
    $Status = New-RemoteCommand -Computername $Computername -Command $Command
    Echo-Log "Process status: $Status"
}

Function Install-IBMSPServices {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$IBMSP_InstallPath
    )

    Echo-Log ("-" * 80)
    Echo-Log ("Installing and configuring backup client services on computer $SystemName")

    $IBMSP_ClientPath = Join-Path -Path $IBMSP_InstallPath -ChildPath 'baclient'
    Echo-Log "Client path: $IBMSP_ClientPath"
    $IBMSP_OPTPath = Join-Path -Path $IBMSP_ClientPath -ChildPath 'dsm.opt'
    Echo-Log "Option file: $IBMSP_OPTPath"
    $IBMSP_INCPath = Join-Path -Path $IBMSP_ClientPath -ChildPath 'inclexcl.dsm'
    Echo-Log "Include/Exclude file: $IBMSP_INCPath"

    # Install Scheduler
    $IBMSP_SCHEDSRV = [char]34 + 'IBMSP Client Scheduler' + [char]34
    Echo-Log "Installing service: $IBMSP_SCHEDSRV"
    $DSMCUTIL = Join-Path $IBMSP_ClientPath -ChildPath "dsmcutil.exe"
    $Command = [char]34 + $DSMCUTIL + [char]34
    $Command = $Command + ' install scheduler'
    $Command = $Command + ' /name:' + $IBMSP_SCHEDSRV
    $Command = $Command + ' /clientdir:' + [char]34 + $IBMSP_ClientPath + [char]34
    $Command = $Command + ' /optfile:' + [char]34 + $IBMSP_OPTPath + [char]34
    $Command = $Command + ' /node:' + $Computername
    $Command = $Command + ' /password:admin123'
    $Command = $Command + ' /validate:yes'
    $Command = $Command + ' /autostart:no'
    $Command = $Command + ' /startnow:no'
    $Status = New-RemoteCommand -Computername $Computername -Command $Command
    Echo-Log "Process status: $Status"

    # Install CAD
    $IBMSP_CADSRV = [char]34 + 'IBMSP Client Acceptor Daemon' + [char]34
    Echo-Log "Install service: $IBMSP_CADSRV"
    $DSMCUTIL = Join-Path $IBMSP_ClientPath -ChildPath "dsmcutil.exe"
    $Command = [char]34 + $DSMCUTIL + [char]34
    $Command = $Command + ' install cad'
    $Command = $Command + ' /name:' + $IBMSP_CADSRV
    $Command = $Command + ' /optfile:' + [char]34 + $IBMSP_OPTPath + [char]34
    $Command = $Command + ' /node:' + $Computername
    $Command = $Command + ' /password:admin123'
    $Command = $Command + ' /validate:yes'
    $Command = $Command + ' /autostart:yes'
    $Command = $Command + ' /startnow:no'
    $Status = New-RemoteCommand -Computername $Computername -Command $Command
    Echo-Log "Process status: $Status"

    # Configure CAD with scheduler
    Echo-Log "Configure CAD service with scheduler: $IBMSP_SCHEDSRV"
    $DSMCUTIL = Join-Path $IBMSP_ClientPath -ChildPath "dsmcutil.exe"
    $Command = [char]34 + $DSMCUTIL + [char]34
    $Command = $Command + ' update cad'
    $Command = $Command + ' /name:' + $IBMSP_CADSRV
    $Command = $Command + ' /cadschedname:' + $IBMSP_SCHEDSRV
    $Status = New-RemoteCommand -Computername $Computername -Command $Command

    Echo-Log "Starting service: $IBMSP_CADSRV"
    $Service = $IBMSP_CADSRV -replace [char]34, ''
    $Started = Remote-StartService $Computername $Service
    Echo-Log "Service status: $Started"
}

Function Install-IBMSPCertificate {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$IBMSP_InstallPath
    )

    Echo-Log ("-" * 80)
    Echo-Log ("Installing certificate on computer $SystemName")

    $IBMSP_ClientPath = Join-Path -Path $IBMSP_InstallPath -ChildPath 'baclient'
    Echo-Log "Client path: $IBMSP_ClientPath"
    $IBMSP_CertPath = Join-Path -Path $IBMSP_ClientPath -ChildPath 'cert256_s202.arm'
    Echo-Log "Certificate file: $IBMSP_CertPath"

    # Remove existing CAD
    $DSMCUTIL = Join-Path $IBMSP_ClientPath -ChildPath "dsmcert.exe"
    $Command = [char]34 + $DSMCUTIL + [char]34
    $Command = $Command + ' -add -server s202 -file '
    $Command = $Command + [char]34 + $IBMSP_CertPath + [char]34
    $Status = New-RemoteCommand -Computername $Computername -Command $Command
    Echo-Log "Process status: $Status"
}

Function Update-DSMOpt {
    [CmdletBinding()]
    param (
        [string]$Computername = $ENV:Computername,
        [string]$IBMSP_InstallPath
    )

    Echo-Log ("-" * 80)
    Echo-Log ("Update DSM.opt file on computer $SystemName")

    $IBMSP_ClientPath = Join-Path -Path $IBMSP_InstallPath -ChildPath 'baclient'
    Echo-Log "Client path: $IBMSP_ClientPath"
    $IBMSP_OPTPath = Join-Path -Path $IBMSP_ClientPath -ChildPath 'dsm.opt'
    $OptFile = "\\$Computername\$IBMSP_OPTPath"
    $OptFile = $OptFile -replace (':','$')
    Echo-Log "Option file: $OptFile"

    # Read content
    $Content = Get-Content -Path $OptFile
    $Content = $Content -Replace 'tsmsrvgb1', 'tsm001gb'
    $Content = $Content -Replace 'tsmsrvgb2', 'tsm001gb'
    $Content = $Content -Replace 'tsmsrv', 'tsm001'
    # Write back
    Set-Content -Path $OptFile $Content
}

# ================================================================================
Clear-Host

$ScriptName = $myInvocation.MyCommand.Name
$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "IBMSP_Install-$($cdtime)"
$GlobLog = Init-Log -LogFileName $logfile

Echo-Log ("=" * 80)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"
if ($Force) {
    Echo-Log "Using command -Force to install/reconfigure the backup client."
}
Echo-Log ('-' * 80)
$SystemList = $Computername

foreach ($SystemName in $SystemList) {
    Echo-Log "Using computer: $SystemName"
    If (Test-Connection -ComputerName $SystemName -Count 1 -Quiet) {
        Echo-Log "CIM retrieve OS information from computer $Systemname."
        $OSInfo = Get-CimInstance Win32_OperatingSystem -ComputerName $SystemName | Select-Object Caption, Version
        foreach ($os in $OSInfo) {
            $Caption = $os.Caption
            $OSVersion = $os.Version
        }
        Echo-Log "Operating System: $Caption"
        Echo-Log "Version: $OSVersion"

        Echo-Log "CIM retrieve processor information from computer $Systemname."
        $ProcInfo = Get-CimInstance Win32_Processor -ComputerName $SystemName | Select-Object AddressWidth
        foreach ($proc in $ProcInfo) { $Arch = $proc.AddressWidth }
        Echo-Log "Processor architecture: $Arch bit"

        # Let us assume we are performing a fresh install
        $Upgrade = $False
        # and that all services previously installed are stopped. We'll check for that later.
        $ServOk = $True

        Echo-Log ('-' * 80)
        Echo-Log "Retrieve Tivoli Storage Manager client information."
        $BAClienInfo = Get-BackupClientInfo -ComputerName $SystemName -SftPublisher 'IBM' -SftDisplayName 'IBM Tivoli Storage Manager Client'
        if ($BAClienInfo -eq $null) {
            Echo-Log "No Tivoli Storage Manager client was found."
            Echo-Log "Retrieve IBM Spectrum Protect client information."
            $BAClienInfo = Get-BackupClientInfo -ComputerName $SystemName -SftPublisher 'IBM' -SftDisplayName 'IBM Spectrum Protect Client'
        }

        if ($BAClienInfo -ne $null) {
            # A previous installed client was found.
            $Upgrade = $True

            $BAClientPublisher = $BAClienInfo.Get_Item("Publisher")
            Echo-Log "- Publisher:              $BAClientPublisher"
            $BAClientDisplayName = $BAClienInfo.Get_Item("DisplayName")
            Echo-Log "- Display name:           $BAClientDisplayName"
            $BAClientVersion = $BAClienInfo.Get_Item("DisplayVersion")
            Echo-Log "- Backup client version:  $BAClientVersion"
            $BAClientInstallPath = $BAClienInfo.Get_Item("InstallLocation")
            Echo-Log "- Installed at:           $BAClientInstallPath"

            # Collect service information before upgrade
            Echo-Log ('-' * 80)
            $ServicesCollection = Get-CIMServicesWithPath -Computername $SystemName -InstallLocation $BAClientInstallPath
            if ($ServicesCollection -ne $null) {
                foreach ($Service in $ServicesCollection) {
                    $ServiceName = $Service.Name
                    Echo-Log "- Service: $ServiceName"
                    Echo-Log "  Service started:  $($Service.Started)"
                    if ($Service.Started -eq "True") {
                        Echo-Log "Stopping service '$ServiceName' on computer $SystemName"
                        $Stopped = Remote-StopService $SystemName $ServiceName
                        if ($Stopped) {
                            Echo-Log "Service '$ServiceName' is now stopped."
                        }
                        else {
                            $ServOk = $False
                            Echo-Log "ERROR: Service '$ServiceName' could not be stopped."
                        }
                    }
                }
            }
            else {
                Echo-Log "No backup client services could be found."
            }
        }
        else {
            Echo-Log "No backup client found on $SystemName"
        }

        if ($ServOk -eq $True) {
            # Perform action
            Echo-Log ("-" * 80)
            if ($Upgrade) {
                Echo-Log ("Performing client UPGRADE on computer $SystemName")
            }
            else {
                Echo-Log ("Performing FRESH installation on computer $SystemName")
            }

            # Where is our installation software coming from?
            $ClientSource = Join-Path -Path $InstallSource -ChildPath $IBMSPSourcePath

            # Are we using a local copy (cache) for our installation?
            if ($NoTempCache -eq $True) {
                $SourcePath = $ClientSource
                Echo-Log "Command line option -NoTempCache was applied."
                Echo-Log "Using path $SourcePath as our installation source."
            }
            else {
                $SourcePath = Get-TempSourcePath -Computername $SystemName -InstallSource $InstallSource -ClientSource $ClientSource -SkipTempCache $SkipTempCache
            }
            Echo-Log "We are using $SourcePath as our installation source path."

            # Install prerequisites first.
            Install-Prereqs -Computername $Computername -InstallSource $SourcePath

            # Install backup client.
            $IBMSP_InstallPath = Install-IBMSPClient -Computername $Computername -InstallSource $SourcePath

            # The command line switch -Force can overrule the upgrade detection and actions
            # Copy new config files when forced or this is a fresh install
            if ($Force -or ($Upgrade -eq $False)) {
                New-IBMSPClientConfig -Computername $Computername -InstallSource $SourcePath -IBMSP_InstallPath $IBMSP_InstallPath
            }
            else {
                Echo-Log "No new configuration files are copied. Retaining current configuration files."
            }

            # If we are performing a upgrade install, remove old backup services
            if ($Upgrade -eq $True) {
                Echo-Log "This is an upgrade. Update configuration files."
                Update-DSMOpt -Computername $Computername -IBMSP_InstallPath $IBMSP_InstallPath

                Echo-Log "This is an upgrade. Removing old TSM services."
                # Remove TSM backup services
                Remove-BackupServices -Computername $Computername -IBMSP_InstallPath $IBMSP_InstallPath -BAClientInstallPath $BAClientInstallPath
                # Remove IBM SP backup services
                Remove-IBMSPServices -Computername $Computername -IBMSP_InstallPath $IBMSP_InstallPath
            }
            else {
                Echo-Log "This is not an upgrade. No new services are installed and updated."
            }

            #Install IBM SP backup services
            Install-IBMSPServices -Computername $Computername -IBMSP_InstallPath $IBMSP_InstallPath

            #Install server certificate for back-up server.
            if ($Upgrade -eq $True) {
                Echo-Log "This is an upgrade. Update certificate files."
                Update-IBMSPClientCertificate -Computername $Computername -InstallSource $InstallSource -IBMSP_InstallPath $IBMSP_InstallPath
            }
            Install-IBMSPCertificate -Computername $Computername -IBMSP_InstallPath $IBMSP_InstallPath

            Echo-Log ("-" * 80)
            Echo-Log ("Restart services from upgrade/installation process.")
            # Restarting services that were running before the upgrade
            if ($ServicesCollection -ne $null) {
                foreach ($Service in $ServicesCollection) {
                    $ServiceName = $Service.Name
                    if ($Service.Started -eq "True") {
                        Echo-Log "Starting backup services previously stopped."
                        Echo-Log "- Service: $ServiceName"
                        $Started = Remote-StartService $SystemName $ServiceName
                        Echo-Log "  Service started: $Started"
                    }
                }
                Echo-Log "Services recovery completed."
            }
            else {
                Echo-Log "No services to restart."
            }
        }

        # Remove the temporary installation folder if we are using it.
        Echo-Log ("-" * 80)
        Echo-Log ("Cleanup of installation cache.")
        if ($NoTempCache -eq $False) {
            $OrigSourcePath = Join-Path $InstallSource -ChildPath $ClientSource
            if ($SourcePath -eq $OrigSourcePath) {
                Echo-Log "WARNING: Trying to erase the remote source location?"
            }
            else {
                Echo-Log ("Folder $SourcePath on Computer $Systemname")
                if (Test-CIMFolder -Computername $Systemname -Path $SourcePath) {
                    Echo-Log "Cleanup of source folder $SourcePath"
                    $command = 'cmd.exe /c rmdir /S /Q'
                    $Command = $command + ' ' + [char]34 + $SourcePath + [char]34
                    $Status = New-RemoteCommand -Computername $Computername -Command $Command
                    Echo-Log "Status: $Status"
                }
                else {
                    Echo-Log "Warning: The folder $SourcePath does not exist."
                }
            }
        }
        else {
            Echo-Log "No cache used. Nothing to do."
        }
    }
    else {
        Echo-Log "ERROR: $SystemName cannot be contacted. Test-Connection failed."
    }
}

# ------------------------------------------------------------------------------
Echo-Log ("-" * 80)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("=" * 80)

Close-LogSystem

write-host "Press any key to continue..."
[void][System.Console]::ReadKey($true)

# SIG # Begin signature block
# MIIHMQYJKoZIhvcNAQcCoIIHIjCCBx4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyUVYZ1L0qySeQ1rp7f46AM1E
# cnagggUYMIIFFDCCA/ygAwIBAgITdgAAAFpjO/1I+6d6kAAAAAAAWjANBgkqhkiG
# 9w0BAQsFADBMMRIwEAYKCZImiZPyLGQBGRYCbmwxFjAUBgoJkiaJk/IsZAEZFgZu
# ZWRjYXIxHjAcBgNVBAMTFVZETE5FRENBUi1WUzE0MC1DQS1WMjAeFw0xODAzMTUw
# ODM1NTlaFw0xOTAzMTUwODM1NTlaMGUxEjAQBgoJkiaJk/IsZAEZFgJubDEWMBQG
# CgmSJomT8ixkARkWBm5lZGNhcjEiMCAGA1UECxMZRW50ZXJwcmlzZSBBZG1pbmlz
# dHJhdGlvbjETMBEGA1UEAxMKQURNTUo5MDYyNDCBnzANBgkqhkiG9w0BAQEFAAOB
# jQAwgYkCgYEAprqZ6a/K3QovCQYKlhtXxxAkuFNYh0Tifso/7JpsciznRC3nnrpb
# Afl2pVr8s3NV07r7H9yF/AlArgZlA0MtqrYzW+95C6+jPVX7/NPfJOUHSGr66blK
# 3ga0ywLx9w8miDyJSRrmEmzPY8Vn6fMkpdMK44co8zKZAN59YmDhEdkCAwEAAaOC
# AlgwggJUMCUGCSsGAQQBgjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBuAGkAbgBnMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDAdBgNVHQ4EFgQU6xiPDocO
# s7EPJbHyYxGJmtu1hXowHwYDVR0jBBgwFoAUYBq1RvmdL0zDLoyzfYwhknTW7Iow
# gc8GA1UdHwSBxzCBxDCBwaCBvqCBu4aBuGxkYXA6Ly8vQ049VkRMTkVEQ0FSLVZT
# MTQwLUNBLVYyLENOPVZTMTQwLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2
# aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPW5lZGNhcixEQz1u
# bD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JM
# RGlzdHJpYnV0aW9uUG9pbnQwgcUGCCsGAQUFBwEBBIG4MIG1MIGyBggrBgEFBQcw
# AoaBpWxkYXA6Ly8vQ049VkRMTkVEQ0FSLVZTMTQwLUNBLVYyLENOPUFJQSxDTj1Q
# dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
# aW9uLERDPW5lZGNhcixEQz1ubD9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xh
# c3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTAvBgNVHREEKDAmoCQGCisGAQQBgjcU
# AgOgFgwUQURNTUo5MDYyNEBuZWRjYXIubmwwDQYJKoZIhvcNAQELBQADggEBAEgF
# amb4/IuCYeP7rfpx7/dO5pMOm3y2qjQDak8DYlUilDMlqsafoRZwdQfLLR/jPxzw
# Foi5tF+/3lMZdjsfAYKHyxNMviDGJAD7pV5k29qTR/DpQ+DhpwsrK11aLSBMDMNF
# Pvw9tcv470FOA3aj2oL6ck0mb+k3bV9UlqJm5eQSUawXpmhRk5oTo4/Zd9G1qDhb
# Dpd/H8gY4f5gj3XdiIO1BWusSBA4eOwm23qIw0j9cuH9xIvB1Eg9780mHD+OJzl9
# GWwcWteUA8H1SG/eg+Dr+tsCmRwN1pzWwLwG9T0XVy6OASMFGbPuNkKljYVhJUKi
# AHlr5zaUUVezRU83OhkxggGDMIIBfwIBATBjMEwxEjAQBgoJkiaJk/IsZAEZFgJu
# bDEWMBQGCgmSJomT8ixkARkWBm5lZGNhcjEeMBwGA1UEAxMVVkRMTkVEQ0FSLVZT
# MTQwLUNBLVYyAhN2AAAAWmM7/Uj7p3qQAAAAAABaMAkGBSsOAwIaBQCgeDAYBgor
# BgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEE
# MBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQC
# rVpP4C3BV29miYj3Y7VjgKjnrDANBgkqhkiG9w0BAQEFAASBgDiXqyIAyU4PInzj
# 5AKSsrI7ak3YvBbitTuiqShZBLaVdU0Nk4bhk13G7qrxqXoi6sUYH6KYQCwXETiQ
# qFbmwOhevUE+hQWkRMq8FEbFWFIcsgknsebtsTE5sONZwPVOJERq5sRLxmhpUgYP
# jzKLU3PnJn+bQBQR+wDiACZbLvWE
# SIG # End signature block
