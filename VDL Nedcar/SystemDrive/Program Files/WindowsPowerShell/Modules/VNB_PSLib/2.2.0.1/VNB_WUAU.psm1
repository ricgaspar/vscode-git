<#
.SYNOPSIS
    VNB Library - Windows Update Agent

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	4-06-2017
 
.DESCRIPTION
    Windows Update agent
#>
#Requires -version 3.0

Function Set-ClientWSUSSetting {
    <#  
    .SYNOPSIS  
        Sets the wsus client settings on a local or remove system.

    .DESCRIPTION
        Sets the wsus client settings on a local or remove system.
         
    .PARAMETER Computername
        Name of computer to connect to. Can be a collection of computers.

    .PARAMETER UpdateServer
        URL of the WSUS server. Must use Https:// or Http://

    .PARAMETER TargetGroup
        Name of the Target Group to which the computer belongs on the WSUS server.
    
    .PARAMETER DisableTargetGroup
        Disables the use of setting a Target Group
    
    .PARAMETER Options
        Configure the Automatic Update client options. 
        Accepted Values are: "Notify","DownloadOnly","DownloadAndInstall","AllowUserConfig"

    .PARAMETER DetectionFrequency
        Specifed time (in hours) for detection from client to server.
        Accepted range is: 1-22
    
    .PARAMETER DisableDetectionFrequency
        Disables the detection frequency on the client.
    
    .PARAMETER RebootLaunchTimeout
        Set the timeout (in minutes) for scheduled restart.
        Accepted range is: 1-1440
    
    .PARAMETER DisableRebootLaunchTimeout              
        Disables the reboot launch timeout.
    
    .PARAMETER RebootWarningTimeout
        Set the restart warning countdown (in minutes)
        Accepted range is: 1-30
     
    .PARAMETER DisableRebootWarningTimeout
        Disables the reboot warning timeout  
        
    .PARAMETER RescheduleWaitTime
        Time (in minutes) that Automatic Updates should wait at startup before applying updates from a missed scheduled installation time.
      
    .PARAMETER DisableRescheduleWaitTime
        Disables the RescheduleWaitTime   
    
    .PARAMETER ScheduleInstallDay                  
        Specified Day of the week to perform automatic installation. Only valid when Options is set to "DownloadAndInstall"
        Accepted values are: "Everyday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"
    
    .PARAMETER ElevateNonAdmins
        Allow non-administrators to approve or disapprove updates
        Accepted values are: "Enable","Disable"
    
    .PARAMETER AllowAutomaticUpdates
        Enables or disables Automatic Updates
        Accepted values are: "Enable","Disable"
    
    .PARAMETER UseWSUSServer
        Enables or disables use of a Windows Update Server
        Accepted values are: "Enable","Disable"
    
    .PARAMETER AutoInstallMinorUpdates
        Enables or disables silent installation of minor updates.
        Accepted values are: "Enable","Disable"
    
    .PARAMETER AutoRebootWithLoggedOnUsers
        Enables or disables automatic reboots after patching completed whether users or logged into the machine or not.
        Accepted values are: "Enable","Disable"

    .NOTES  
        Name: Set-WSUSClient
        Author: Boe Prox
        https://learn-powershell.net
        DateCreated: 02DEC2011 
        
        To do: Add -PassThru support
               
    .LINK  
        http://technet.microsoft.com/en-us/library/cc708449(WS.10).aspx
        
    .EXAMPLE
    Set-ClientWSUSSetting -UpdateServer "http://testwsus.com" -UseWSUSServer Enable -AllowAutomaticUpdates Enable -DetectionFrequency 4 -Options DownloadOnly

    Description
    -----------
    Configures the local computer to enable automatic updates and use testwsus.com as the update server. Also sets the update detection
    frequency to occur every 4 hours and only downloads the updates. 
    
    .EXAMPLE
    Set-ClientWSUSSetting -UpdateServer "http://testwsus.com" -UseWSUSServer Enable -AllowAutomaticUpdates Enable -DetectionFrequency 4 -Options DownloadAndInstall -RebootWarningTimeout 15 
    -ScheduledInstallDay Monday -ScheduledInstallTime 20
    
    Description
    -----------
    Configures the local computer to enable automatic updates and use testwsus.com as the update server. Also sets the update detection
    frequency to occur every 4 hours and performs the installation automatically every Monday at 8pm and configured to reboot 15 minutes (with a timer for logged on users) after updates
    have been installed.

    #>
    [cmdletbinding(
        SupportsShouldProcess = $True
    )]
    Param (
        [parameter(Position=0,ValueFromPipeLine = $True)]
        [string[]]$Computername = $Env:Computername,
        [parameter(Position=1)]
        [string]$UpdateServer,
        [parameter(Position=2)]
        [string]$TargetGroup,
        [parameter(Position=3)]
        [switch]$DisableTargetGroup,         
        [parameter(Position=4)]
        [ValidateSet('Notify','DownloadOnly','DownloadAndInstall','AllowUserConfig')]
        [string]$Options,
        [parameter(Position=5)]
        [ValidateRange(1,22)]
        [Int32]$DetectionFrequency,
        [parameter(Position=6)]
        [switch]$DisableDetectionFrequency,        
        [parameter(Position=7)]
        [ValidateRange(1,1440)]
        [Int32]$RebootLaunchTimeout,
        [parameter(Position=8)]
        [switch]$DisableRebootLaunchTimeout,        
        [parameter(Position=9)]
        [ValidateRange(1,30)]  
        [Int32]$RebootWarningTimeout,
        [parameter(Position=10)]
        [switch]$DisableRebootWarningTimeout,        
        [parameter(Position=11)]
        [ValidateRange(1,60)]
        [Int32]$RescheduleWaitTime,
        [parameter(Position=12)]
        [switch]$DisableRescheduleWaitTime,        
        [parameter(Position=13)]
        [ValidateSet('EveryDay','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')]
        [ValidateCount(1,1)]
        [string]$ScheduleInstallDay,
        [parameter(Position=14)]
        [ValidateRange(0,23)]
        [Int32]$ScheduleInstallTime,
        [parameter(Position=15)]
        [ValidateSet('Enable','Disable')]
        [string]$ElevateNonAdmins,    
        [parameter(Position=16)]
        [ValidateSet('Enable','Disable')]
        [string]$AllowAutomaticUpdates,  
        [parameter(Position=17)]
        [ValidateSet('Enable','Disable')]
        [string]$UseWSUSServer,
        [parameter(Position=18)]
        [ValidateSet('Enable','Disable')]
        [string]$AutoInstallMinorUpdates,
        [parameter(Position=19)]
        [ValidateSet('Enable','Disable')]
        [string]$AutoRebootWithLoggedOnUsers                                              
    )
    Begin {
    }
    Process {
        $PSBoundParameters.GetEnumerator() | ForEach {
            Write-Verbose ("{0}" -f $_)
        }
        ForEach ($Computer in $Computername) {
            If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                $WSUSEnvhash = @{}
                $WSUSConfigHash = @{}
                $ServerReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine",$Computer) 
                #Check to see if WSUS registry keys exist
                $temp = $ServerReg.OpenSubKey('Software\Policies\Microsoft\Windows',$True)
                If (-NOT ($temp.GetSubKeyNames() -contains 'WindowsUpdate')) {
                    #Build the required registry keys
                    $temp.CreateSubKey('WindowsUpdate\AU') | Out-Null
                }
                #Set WSUS Client Environment Options
                $WSUSEnv = $ServerReg.OpenSubKey('Software\Policies\Microsoft\Windows\WindowsUpdate',$True)
                If ($PSBoundParameters['ElevateNonAdmins']) {
                    If ($ElevateNonAdmins -eq 'Enable') {
                        If ($pscmdlet.ShouldProcess("Elevate Non-Admins","Enable")) {
                            $WsusEnv.SetValue('ElevateNonAdmins',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    } ElseIf ($ElevateNonAdmins -eq 'Disable') {
                        If ($pscmdlet.ShouldProcess("Elevate Non-Admins","Disable")) {
                            $WsusEnv.SetValue('ElevateNonAdmins',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                }
                If ($PSBoundParameters['UpdateServer']) {
                    If ($pscmdlet.ShouldProcess("WUServer","Set Value")) {
                        $WsusEnv.SetValue('WUServer',$UpdateServer,[Microsoft.Win32.RegistryValueKind]::String)
                    }
                    If ($pscmdlet.ShouldProcess("WUStatusServer","Set Value")) {
                        $WsusEnv.SetValue('WUStatusServer',$UpdateServer,[Microsoft.Win32.RegistryValueKind]::String)
                    }
                }
                If ($PSBoundParameters['TargetGroup']) {
                    If ($pscmdlet.ShouldProcess("TargetGroup","Enable")) {
                        $WsusEnv.SetValue('TargetGroupEnabled',1,[Microsoft.Win32.RegistryValueKind]::Dword)
                    }
                    If ($pscmdlet.ShouldProcess("TargetGroup","Set Value")) {
                        $WsusEnv.SetValue('TargetGroup',$TargetGroup,[Microsoft.Win32.RegistryValueKind]::String)
                    }
                }    
                If ($PSBoundParameters['DisableTargetGroup']) {
                    If ($pscmdlet.ShouldProcess("TargetGroup","Disable")) {
                        $WsusEnv.SetValue('TargetGroupEnabled',0,[Microsoft.Win32.RegistryValueKind]::Dword)
                    }
                }      
                                       
                #Set WSUS Client Configuration Options
                $WSUSConfig = $ServerReg.OpenSubKey('Software\Policies\Microsoft\Windows\WindowsUpdate\AU',$True)
                If ($PSBoundParameters['Options']) {
                    If ($pscmdlet.ShouldProcess("Options","Set Value")) {
                        If ($Options = 'Notify') {
                            $WsusConfig.SetValue('AUOptions',2,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($Options = 'DownloadOnly') {
                            $WsusConfig.SetValue('AUOptions',3,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($Options = 'DownloadAndInstall') {
                            $WsusConfig.SetValue('AUOptions',4,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($Options = 'AllowUserConfig') {
                            $WsusConfig.SetValue('AUOptions',5,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                } 
                If ($PSBoundParameters['DetectionFrequency']) {
                    If ($pscmdlet.ShouldProcess("DetectionFrequency","Enable")) {
                        $WsusConfig.SetValue('DetectionFrequencyEnabled',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                    If ($pscmdlet.ShouldProcess("DetectionFrequency","Set Value")) {
                        $WsusConfig.SetValue('DetectionFrequency',$DetectionFrequency,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                }
                If ($PSBoundParameters['DisableDetectionFrequency']) {
                    If ($pscmdlet.ShouldProcess("DetectionFrequency","Disable")) {
                        $WsusConfig.SetValue('DetectionFrequencyEnabled',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                } 
                If ($PSBoundParameters['RebootWarningTimeout']) {
                    If ($pscmdlet.ShouldProcess("RebootWarningTimeout","Enable")) {
                        $WsusConfig.SetValue('RebootWarningTimeoutEnabled',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                    If ($pscmdlet.ShouldProcess("RebootWarningTimeout","Set Value")) {
                        $WsusConfig.SetValue('RebootWarningTimeout',$RebootWarningTimeout,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                }
                If ($PSBoundParameters['DisableRebootWarningTimeout']) {
                    If ($pscmdlet.ShouldProcess("RebootWarningTimeout","Disable")) {
                        $WsusConfig.SetValue('RebootWarningTimeoutEnabled',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                }   
                If ($PSBoundParameters['RebootLaunchTimeout']) {
                    If ($pscmdlet.ShouldProcess("RebootLaunchTimeout","Enable")) {
                        $WsusConfig.SetValue('RebootLaunchTimeoutEnabled',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                    If ($pscmdlet.ShouldProcess("RebootLaunchTimeout","Set Value")) {
                        $WsusConfig.SetValue('RebootLaunchTimeout',$RebootLaunchTimeout,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                }
                If ($PSBoundParameters['DisableRebootLaunchTimeout']) {
                    If ($pscmdlet.ShouldProcess("RebootWarningTimeout","Disable")) {
                        $WsusConfig.SetValue('RebootLaunchTimeoutEnabled',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                } 
                If ($PSBoundParameters['ScheduleInstallDay']) {
                    If ($pscmdlet.ShouldProcess("ScheduledInstallDay","Set Value")) {
                        If ($ScheduleInstallDay = 'EveryDay') {
                            $WsusConfig.SetValue('ScheduledInstallDay',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($ScheduleInstallDay = 'Monday') {
                            $WsusConfig.SetValue('ScheduledInstallDay',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($ScheduleInstallDay = 'Tuesday') {
                            $WsusConfig.SetValue('ScheduledInstallDay',2,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($ScheduleInstallDay = 'Wednesday') {
                            $WsusConfig.SetValue('ScheduledInstallDay',3,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($ScheduleInstallDay = 'Thursday') {
                            $WsusConfig.SetValue('ScheduledInstallDay',4,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($ScheduleInstallDay = 'Friday') {
                            $WsusConfig.SetValue('ScheduledInstallDay',5,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($ScheduleInstallDay = 'Saturday') {
                            $WsusConfig.SetValue('ScheduledInstallDay',6,[Microsoft.Win32.RegistryValueKind]::DWord)
                        } ElseIf ($ScheduleInstallDay = 'Sunday') {
                            $WsusConfig.SetValue('ScheduledInstallDay',7,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                }   
                If ($PSBoundParameters['RescheduleWaitTime']) {
                    If ($pscmdlet.ShouldProcess("RescheduleWaitTime","Enable")) {
                        $WsusConfig.SetValue('RescheduleWaitTimeEnabled',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                    If ($pscmdlet.ShouldProcess("RescheduleWaitTime","Set Value")) {
                        $WsusConfig.SetValue('RescheduleWaitTime',$RescheduleWaitTime,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                }
                If ($PSBoundParameters['DisableRescheduleWaitTime']) {
                    If ($pscmdlet.ShouldProcess("RescheduleWaitTime","Disable")) {
                        $WsusConfig.SetValue('RescheduleWaitTimeEnabled',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                  } 
                If ($PSBoundParameters['ScheduleInstallTime']) {
                    If ($pscmdlet.ShouldProcess("ScheduleInstallTime","Set Value")) {
                        $WsusConfig.SetValue('ScheduleInstallTime',$ScheduleInstallTime,[Microsoft.Win32.RegistryValueKind]::DWord)
                    }
                }   
                If ($PSBoundParameters['AllowAutomaticUpdates']) {
                    If ($AllowAutomaticUpdates -eq 'Enable') {
                        If ($pscmdlet.ShouldProcess("AllowAutomaticUpdates","Enable")) {
                            $WsusEnv.SetValue('NoAutoUpdate',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    } ElseIf ($AllowAutomaticUpdates -eq 'Disable') {
                        If ($pscmdlet.ShouldProcess("AllowAutomaticUpdates","Disable")) {
                            $WsusEnv.SetValue('NoAutoUpdate',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                } 
                If ($PSBoundParameters['UseWSUSServer']) {
                    If ($UseWSUSServer -eq 'Enable') {
                        If ($pscmdlet.ShouldProcess("UseWSUSServer","Enable")) {
                            $WsusEnv.SetValue('UseWUServer',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    } ElseIf ($UseWSUSServer -eq 'Disable') {
                        If ($pscmdlet.ShouldProcess("UseWSUSServer","Disable")) {
                            $WsusEnv.SetValue('UseWUServer',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                }
                If ($PSBoundParameters['AutoInstallMinorUpdates']) {
                    If ($AutoInstallMinorUpdates -eq 'Enable') {
                        If ($pscmdlet.ShouldProcess("AutoInstallMinorUpdates","Enable")) {
                            $WsusEnv.SetValue('AutoInstallMinorUpdates',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    } ElseIf ($AutoInstallMinorUpdates -eq 'Disable') {
                        If ($pscmdlet.ShouldProcess("AutoInstallMinorUpdates","Disable")) {
                            $WsusEnv.SetValue('AutoInstallMinorUpdates',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                }  
                If ($PSBoundParameters['AutoRebootWithLoggedOnUsers']) {
                    If ($AutoRebootWithLoggedOnUsers -eq 'Enable') {
                        If ($pscmdlet.ShouldProcess("AutoRebootWithLoggedOnUsers","Enable")) {
                            $WsusEnv.SetValue('NoAutoRebootWithLoggedOnUsers',1,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    } ElseIf ($AutoRebootWithLoggedOnUsers -eq 'Disable') {
                        If ($pscmdlet.ShouldProcess("AutoRebootWithLoggedOnUsers","Disable")) {
                            $WsusEnv.SetValue('NoAutoRebootWithLoggedOnUsers',0,[Microsoft.Win32.RegistryValueKind]::DWord)
                        }
                    }
                }                                                                                                                                          
            } Else {
                Write-Warning ("{0}: Unable to connect!" -f $Computer)
            }
        }
    }
}

Function Get-ClientWSUSSetting {
    <#  
    .SYNOPSIS  
        Retrieves the wsus client settings on a local or remove system.

    .DESCRIPTION
        Retrieves the wsus client settings on a local or remove system.
         
    .PARAMETER Computername
        Name of computer to connect to. Can be a collection of computers.

    .PARAMETER ShowEnvironment
        Display only the Environment settings.

    .PARAMETER ShowConfiguration
        Display only the Configuration settings.

    .NOTES  
        Name: Get-WSUSClient
        Author: Boe Prox
        DateCreated: 02DEC2011 
               
    .LINK  
        https://learn-powershell.net
        
    .EXAMPLE
    Get-ClientWSUSSetting -Computer TestServer
    
    RescheduleWaitTime            : NA
    AutoInstallMinorUpdates       : NA
    TargetGroupEnabled            : NA
    ScheduledInstallDay           : NA
    DetectionFrequencyEnabled     : 1
    WUServer                      : http://wsus.com
    Computername                  : TestServer
    RebootWarningTimeoutEnabled   : NA
    ElevateNonAdmins              : NA
    ScheduledInstallTime          : NA
    RebootRelaunchTimeout         : 10
    ScheduleInstallDay            : NA
    RescheduleWaitTimeEnabled     : NA
    DisableWindowsUpdateAccess    : NA
    AUOptions                     : 3
    DetectionFrequency            : 4
    RebootWarningTimeout          : NA
    ScheduleInstallTime           : NA
    WUStatusServer                : http://wsus.com
    TargetGroup                   : NA
    RebootRelaunchTimeoutEnabled  : 1
    UseWUServer                   : 1
    NoAutoRebootWithLoggedOnUsers : 1

    Description
    -----------
    Displays both Environment and Configuration settings for TestServer
    
    .EXAMPLE
    Get-ClientWSUSSetting -Computername Server1 -ShowEnvironment
    
    Computername               : Server1
    TargetGroupEnabled         : NA
    TargetGroup                : NA
    WUStatusServer             : http://wsus.com
    WUServer                   : http://wsus.com
    DisableWindowsUpdateAccess : 1
    ElevateNonAdmins           : 0
    
    Description
    -----------
    Displays the Environment settings for Server1
    
    .Example
    Get-ClientWSUSSetting -Computername Server1 -ShowConfiguration
    
    ScheduledInstallTime          : NA
    AutoInstallMinorUpdates       : 0
    ScheduledInstallDay           : NA
    Computername                  : Server1
    RebootWarningTimeoutEnabled   : NA
    RebootWarningTimeout          : NA
    NoAUAsDefaultShutdownOption   : NA
    RebootRelaunchTimeout         : NA
    DetectionFrequency            : 4
    ScheduleInstallDay            : NA
    RescheduleWaitTime            : NA
    RescheduleWaitTimeEnabled     : 0
    AUOptions                     : 3
    NoAutoRebootWithLoggedOnUsers : 1
    DetectionFrequencyEnabled     : 1
    ScheduleInstallTime           : NA
    NoAUShutdownOption            : NA
    RebootRelaunchTimeoutEnabled  : NA
    UseWUServer                   : 1
    IncludeRecommendedUpdates     : NA  
    
    Description
    -----------
    Displays the Configuration settings for Server1
    #>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeLine = $True)]
        [string[]]$Computername = $Env:Computername,
        [parameter()]
        [switch]$ShowEnvironment,
        [parameter()]
        [switch]$ShowConfiguration        
    )
    Begin {
        $EnvKeys = "WUServer","WUStatusServer","ElevateNonAdmins","TargetGroupEnabled","TargetGroup","DisableWindowsUpdateAccess"
        $ConfigKeys = "AUOptions","AutoInstallMinorUpdates","DetectionFrequency","DetectionFrequencyEnabled","NoAutoRebootWithLoggedOnUsers",
        "NoAutoUpdate","RebootRelaunchTimeout","RebootRelaunchTimeoutEnabled","RebootWarningTimeout","RebootWarningTimeoutEnabled","RescheduleWaitTime","RescheduleWaitTimeEnabled",
        "ScheduleInstallDay","ScheduleInstallTime","UseWUServer"
    }
    Process {
        $PSBoundParameters.GetEnumerator() | ForEach {
            Write-Verbose ("{0}" -f $_)
        }
        ForEach ($Computer in $Computername) {
                If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                $WSUSEnvhash = @{}
                $WSUSConfigHash = @{}
                $ServerReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine",$Computer)
                #Get WSUS Client Environment Options
                $WSUSEnv = $ServerReg.OpenSubKey('Software\Policies\Microsoft\Windows\WindowsUpdate')
                $subkeys = @($WSUSEnv.GetValueNames())
                $NoData = @(Compare-Object -ReferenceObject $EnvKeys -DifferenceObject $subkeys | Select -ExpandProperty InputObject)
                ForEach ($item in $NoData) {
                    $WSUSEnvhash[$item] = 'NA'
                }
                $Data = @(Compare-Object -ReferenceObject $EnvKeys -DifferenceObject $subkeys -IncludeEqual -ExcludeDifferent | Select -ExpandProperty InputObject)
                ForEach ($key in $Data) {
                    If ($key -eq 'WUServer') {
                        $WSUSEnvhash['WUServer'] = $WSUSEnv.GetValue('WUServer')
                    }
                    If ($key -eq 'WUStatusServer') {
                        $WSUSEnvhash['WUStatusServer'] = $WSUSEnv.GetValue('WUStatusServer')
                    }
                    If ($key -eq 'ElevateNonAdmins') {
                        $WSUSEnvhash['ElevateNonAdmins'] = $WSUSEnv.GetValue('ElevateNonAdmins')
                    }
                    If ($key -eq 'TargetGroupEnabled') {
                        $WSUSEnvhash['TargetGroupEnabled'] = $WSUSEnv.GetValue('TargetGroupEnabled')
                    }
                    If ($key -eq 'TargetGroup') {
                        $WSUSEnvhash['TargetGroup'] = $WSUSEnv.GetValue('TargetGroup')
                    }  
                    If ($key -eq 'DisableWindowsUpdateAccess') {
                        $WSUSEnvhash['DisableWindowsUpdateAccess'] = $WSUSEnv.GetValue('DisableWindowsUpdateAccess')
                    }              
                }
                #Get WSUS Client Configuration Options
                $WSUSConfig = $ServerReg.OpenSubKey('Software\Policies\Microsoft\Windows\WindowsUpdate\AU')
                $subkeys = @($WSUSConfig.GetValueNames())
                $NoData = @(Compare-Object -ReferenceObject $ConfigKeys -DifferenceObject $subkeys | Select -ExpandProperty InputObject)
                ForEach ($item in $NoData) {
                    $WSUSConfighash[$item] = 'NA'
                }            
                $Data = @(Compare-Object -ReferenceObject $ConfigKeys -DifferenceObject $subkeys -IncludeEqual -ExcludeDifferent | Select -ExpandProperty InputObject)
                ForEach ($key in $Data) {
                    If ($key -eq 'AUOptions') {
                        $WSUSConfighash['AUOptions'] = $WSUSConfig.GetValue('AUOptions')
                    }
                    If ($key -eq 'AutoInstallMinorUpdates') {
                        $WSUSConfighash['AutoInstallMinorUpdates'] = $WSUSConfig.GetValue('AutoInstallMinorUpdates')
                    }
                    If ($key -eq 'DetectionFrequency') {
                        $WSUSConfighash['DetectionFrequency'] = $WSUSConfig.GetValue('DetectionFrequency')
                    }
                    If ($key -eq 'DetectionFrequencyEnabled') {
                        $WSUSConfighash['DetectionFrequencyEnabled'] = $WSUSConfig.GetValue('DetectionFrequencyEnabled')
                    }
                    If ($key -eq 'NoAutoRebootWithLoggedOnUsers') {
                        $WSUSConfighash['NoAutoRebootWithLoggedOnUsers'] = $WSUSConfig.GetValue('NoAutoRebootWithLoggedOnUsers')
                    }
                    If ($key -eq 'RebootRelaunchTimeout') {
                        $WSUSConfighash['RebootRelaunchTimeout'] = $WSUSConfig.GetValue('RebootRelaunchTimeout')
                    }
                    If ($key -eq 'RebootRelaunchTimeoutEnabled') {
                        $WSUSConfighash['RebootRelaunchTimeoutEnabled'] = $WSUSConfig.GetValue('RebootRelaunchTimeoutEnabled')
                    }
                    If ($key -eq 'RebootWarningTimeout') {
                        $WSUSConfighash['RebootWarningTimeout'] = $WSUSConfig.GetValue('RebootWarningTimeout')
                    }
                    If ($key -eq 'RebootWarningTimeoutEnabled') {
                        $WSUSConfighash['RebootWarningTimeoutEnabled'] = $WSUSConfig.GetValue('RebootWarningTimeoutEnabled')
                    }
                    If ($key -eq 'RescheduleWaitTime') {
                        $WSUSConfighash['RescheduleWaitTime'] = $WSUSConfig.GetValue('RescheduleWaitTime')
                    }                                                                                                            
                    If ($key -eq 'RescheduleWaitTimeEnabled') {
                        $WSUSConfighash['RescheduleWaitTimeEnabled'] = $WSUSConfig.GetValue('RescheduleWaitTimeEnabled')
                    }  
                    If ($key -eq 'ScheduleInstallDay') {
                        $WSUSConfighash['ScheduleInstallDay'] = $WSUSConfig.GetValue('ScheduleInstallDay')
                    }  
                    If ($key -eq 'ScheduleInstallTime') {
                        $WSUSConfighash['ScheduleInstallTime'] = $WSUSConfig.GetValue('ScheduleInstallTime')
                    }  
                    If ($key -eq 'UseWUServer') {
                        $WSUSConfighash['UseWUServer'] = $WSUSConfig.GetValue('UseWUServer')
                    }                                          
                }
                
                #Display Output
                If ((-Not ($PSBoundParameters['ShowEnvironment'] -OR $PSBoundParameters['ShowConfiguration'])) -OR `
                ($PSBoundParameters['ShowEnvironment'] -AND $PSBoundParameters['ShowConfiguration'])) {
                    Write-Verbose "Displaying everything"
                    $WSUSHash = ($WSUSEnvHash + $WSUSConfigHash)
                    $WSUSHash['Computername'] = $Computer
                    New-Object PSObject -Property $WSUSHash
                } Else {
                    If ($PSBoundParameters['ShowEnvironment']) {
                        Write-Verbose "Displaying environment settings"
                        $WSUSEnvHash['Computername'] = $Computer
                        New-Object PSObject -Property $WSUSEnvhash
                    }
                    If ($PSBoundParameters['ShowConfiguration']) {
                        Write-Verbose "Displaying Configuration settings"
                        $WSUSConfigHash['Computername'] = $Computer
                        New-Object PSObject -Property $WSUSConfigHash
                    }
                }
            } Else {
                Write-Warning ("{0}: Unable to connect!" -f $Computer)
            }
        }
    }
}

Function Get-WUAUServername {
	process {
		$WUAUEnv = Get-ClientWSUSSetting -ShowEnvironment
		$WUAUServer = $WUAUEnv.WUServer
		$WUAUServer = $WUAUServer.replace("http:","")
		$WUAUServer = $WUAUServer.replace("/","")	
		return $WUAUServer
	}
}

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *