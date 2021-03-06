
# Name of the server that runs DCS web services
$NCSTD_DSC_WEBSERVER = 's031.nedcar.nl'

# Name of the server that has the source share for file resources
$NCSTD_SERVER = 's031.nedcar.nl'

# Name of the share on the sources server that holds sources for file resources
# Important: the share must be READ accessible to all domain computers!
$NCSTD_SHARE = 'NCSTD$'

Configuration NCSTDConfig {

    Param(
        [Parameter(Mandatory = $True)]
        [String[]]$NodeGUID
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $NodeGUID {

        # -------------------------------------------
        # Copy custom Powershell Modules
        File PowershellModulesPresence {
            Type            = "Directory"
            Ensure          = "Present"
            Recurse         = $True
            Checksum        = "SHA-1"
            Force           = $True
            Attributes      = "Archive"
            MatchSource     = $true

            # Important: DO NOT USE VARIABLES. ALL VALUES MUST BE HARDCODED AS NAMES INSTEAD OF THE VALUES ARE COMPILED INTO MOF's
            SourcePath      = "\\s031\ncstd$\SYSTEMROOT\System32\WindowsPowerShell\v1.0\Modules"
            DestinationPath = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
        }

        Log AfterPowershellFolderPresence {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the file resource with ID PowershellFolderPresence"
            DependsOn = "[File]PowershellModulesPresence"
        }

        # -------------------------------------------
        # Create the C:\Scripts folder
        File ScriptFolderPresence {
            Type            = "Directory"
            Ensure          = "Present"
            Recurse         = $True
            Checksum        = "SHA-1"
            Force           = $True
            Attributes      = "Archive"
            MatchSource     = $true

            # Important: DO NOT USE VARIABLES. ALL VALUES MUST BE HARDCODED AS NAMES INSTEAD OF THE VALUES ARE COMPILED INTO MOF's
            SourcePath      = "\\s031.nedcar.nl\NCSTD$\SYSTEMDRIVE\Scripts"
            DestinationPath = "C:\Scripts\"
            DependsOn       = "[File]PowershellModulesPresence"
        }

        Log AfterScriptFolderPresence {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the file resource with ID ScriptFolderPresence"
            DependsOn = "[File]ScriptFolderPresence"
        }

        # -------------------------------------------
        # Create the C:\Logboek folder
        File LogboekFolderPresence {
            Type            = "Directory"
            Ensure          = "Present"
            Recurse         = $True
            Checksum        = "SHA-1"
            Force           = $True
            Attributes      = "Archive"
            MatchSource     = $true

            SourcePath      = "\\s031.nedcar.nl\NCSTD$\SYSTEMDRIVE\Logboek"
            DestinationPath = "C:\Logboek\"
        }

        Log AfterLogboekFolderPresence {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the file resource with ID LogboekFolderPresence"
            DependsOn = "[File]LogboekFolderPresence"
        }

        # -------------------------------------------
        # Create the C:\Windows\Autorun.cmd script
        File AutorunScriptPresence {
            Type            = "File"
            Ensure          = "Present"
            Checksum        = "SHA-1"
            Force           = $True
            Attributes      = "Archive"
            MatchSource     = $true

            SourcePath      = "\\s031.nedcar.nl\NCSTD$\SYSTEMROOT\autorun.cmd"
            DestinationPath = "C:\Windows\autorun.cmd"
        }

        # -------------------------------------------
        # Create the shortcut to C:\Windows\Autorun.cmd folder
        File AutorunShortcutPresence {
            Type            = "File"
            Ensure          = "Present"
            Checksum        = "SHA-1"
            Force           = $True
            Attributes      = "Archive"
            MatchSource     = $true

            SourcePath      = "\\s031.nedcar.nl\NCSTD$\SYSTEMROOT\autorun.cmd.lnk"
            DestinationPath = "C:\Windows\autorun.cmd.lnk"
        }

        # -------------------------------------------
        # Create the OEM files in C:\Windows\System32
        File System32Presence {
            Type            = "Directory"
            Ensure          = "Present"
            Checksum        = "SHA-1"
            Recurse         = $True
            Force           = $True
            Attributes      = "Archive"
            MatchSource     = $true

            SourcePath      = "\\s031.nedcar.nl\NCSTD$\SYSTEMROOT\System32\"
            DestinationPath = "C:\Windows\system32"
        }

        # -------------------------------------------
        # Disable Adobe Acrobat Update Service
        Service AdobeARMservice {
            Name        = "AdobeARMservice"
            StartupType = "Disabled"
            State       = "Stopped"
        }

        Log AfterAdobeARMservice {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the service resource with ID AdobeARMservice"
            DependsOn = "[Service]AdobeARMservice"
        }

        # -------------------------------------------
        # Disable Adobe Flash player Update Service
        Service AdobeFlashPlayerUpdateSvc {
            Name        = "AdobeFlashPlayerUpdateSvc"
            StartupType = "Disabled"
            State       = "Stopped"
        }

        Log AfterAdobeFlashPlayerUpdateSvc {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the service resource with ID AdobeFlashPlayerUpdateSvc"
            DependsOn = "[Service]AdobeFlashPlayerUpdateSvc"
        }

        # -------------------------------------------
        # Environment variable NCSTD is not used anymore.
        Environment SystemPathNCSTD {
            Name   = "NCSTD_VER"
            Ensure = "Absent"
            Path   = $False
        }

        # -------------------------------------------
        # Add Script folders to system path environment variable.
        Environment SystemPathScriptsUtils {
            Name      = "Path"
            Ensure    = "Present"
            Path      = $True
            Value     = "C:\Scripts\Utils;C:\Scripts\Elevation;C:\Scripts\Utils\SysInternals;C:\Program Files\Winzip"
            DependsOn = "[File]ScriptFolderPresence"
        }

        # -------------------------------------------
        # WMI Reliability analysis set to on
        Registry RegistryReliabilityWMI {
            Ensure    = "Present"
            Force     = $True
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Reliability Analysis\WMI"
            ValueName = "WMIEnable"
            ValueType = "DWord"
            Hex       = $True
            ValueData = "0x01"
        }

        # -------------------------------------------
        # Trusted Installer install block time set to 1 hour. Some updates can take that long..
        Registry TrustedInstaller {
            Ensure    = "Present"
            Force     = $True
            Key       = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TrustedInstaller"
            ValueName = "BlockTimeIncrement"
            ValueType = "DWord"
            Hex       = $True
            ValueData = "0xE10"
        }

        # -------------------------------------------
        # Execute init script
        Script NCSTDInit {
            SetScript  = {
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo.Filename = "powershell"
                $process.StartInfo.Arguments = "-ExecutionPolicy Bypass -file C:\Scripts\Config\init.ps1"
                $process.StartInfo.UseShellExecute = $false
                $process.StartInfo.RedirectStandardOutput = $true
                [void]($process.Start())
            }
            TestScript = { Test-Path "C:\Logboek\Config\configure" }
            GetScript  = { <# This must return a hash table #> }
            DependsOn  = "[File]ScriptFolderPresence"
        }

        Log AfterNCSTDInit {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the script resource with ID NCSTDInit"
            DependsOn = "[Script]NCSTDInit"
        }

        # -------------------------------------------
        # Execute init script
        Script NCSTDCleanupXMLcreate {
            SetScript  = {
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo.Filename = "powershell"
                $process.StartInfo.Arguments = "-ExecutionPolicy Bypass -file C:\Scripts\Acties\cleanup_ini2xml.ps1"
                $process.StartInfo.UseShellExecute = $false
                $process.StartInfo.RedirectStandardOutput = $true
                [void]($process.Start())
            }
            TestScript = { Test-Path "C:\Scripts\Acties\cleanup.xml" }
            GetScript  = { <# This must return a hash table #> }
            DependsOn  = "[File]ScriptFolderPresence"
        }

        Log AfterNCSTDCleanupXMLcreate {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the script resource with ID NCSTDCleanupXMLcreate"
            DependsOn = "[Script]NCSTDCleanupXMLcreate"
        }

        # -------------------------------------------
        # Execute init script
        Script NCSTDCleanup {
            SetScript  = {
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo.Filename = "powershell"
                $process.StartInfo.Arguments = "-ExecutionPolicy Bypass -file C:\Scripts\Acties\cleanup.ps1"
                $process.StartInfo.UseShellExecute = $false
                $process.StartInfo.RedirectStandardOutput = $true
                [void]($process.Start())
            }
            TestScript = { Test-Path "C:\Logboek\Cleanup\Cleanup-system.log" }
            GetScript  = { <# This must return a hash table #> }
            DependsOn  = "[Script]NCSTDCleanupXMLcreate"
        }

        Log AfterNCSTDCleanup {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message   = "Finished running the script resource with ID NCSTDCleanup"
            DependsOn = "[Script]NCSTDCleanup"
        }
    }
}

cls

# Remove node/config table
Write-Host "Removing previous configuration table."
$ConfigTable = "\\$NCSTD_SERVER\Standaard\DSC\DSCNodeConfigs.csv"
if (Test-Path $ConfigTable) { Remove-Item -Path $ConfigTable -Force -ErrorAction SilentlyContinue }

#
# Website location for the DSC Pull service
$TargetFiles = "\\$NCSTD_DSC_WEBSERVER\C$\Program Files\WindowsPowershell\DscService\Configuration"

$UDLFile = $glb_UDL
if ((Test-Path $UDLFile)) {
    $UDLConnection = Read-UDLConnectionString $UDLFile
}
# ADODB connections need an implicit Provider type declaration in the UDL connection string
$ADOProvider = 'Provider=SQLOLEDB.1'
$ADOConn = $UDLConnection
if ($ADOConn -notcontains $ADOProvider) { $ADOConn = $ADOProvider + ';' + $ADOConn }

# $TSQL = "select * from vw_VNB_DSC_Approved_Computers order by Systemname"
# Query with ADO connection
# $DTable = Invoke-UDL-SQL -query $TSQL -connectionstring $ADOConn
$DTable = @{Systemname = 'VT998'}
write-host "Generating GUIDs and creating MOF files..."

foreach ($Computer in $DTable) {
    $ComputerName = $Computer.systemname
    $ComputerGuid = [guid]::NewGuid()

    # Translate SQL stored GUID
    $GUID = [guid]($ComputerGuid)

    # Create config MOF file
    Write-Host "- Creating DSC configuration for $ComputerName [$ComputerGuid]"
    [void]( NCSTDConfig -NodeGUID $GUID )

    # Calculate Checksum for MOF file
    New-DSCCheckSum -ConfigurationPath .\NCSTDConfig\"$GUID.mof" -OutPath .\NCSTDConfig -Force

    # Save Nodename and GUID relation to CSV table for nodes to use
    $NewLine = "{0},{1}" -f $ComputerName, $GUID
    $NewLine | add-content -path $ConfigTable

    # Move the MOF files to the web service location
    $SourceFiles = (Get-Location -PSProvider FileSystem).Path + "\NCSTDConfig\$GUID.mof*"
    Move-Item $SourceFiles $TargetFiles -Force

}

Remove-Item ((Get-Location -PSProvider FileSystem).Path + "\NCSTDConfig\")
