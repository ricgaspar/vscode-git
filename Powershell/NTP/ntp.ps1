<#

.SYNOPSIS
This function will get a list of computer and check for each of them the NTP configuration and the delta between the computer and specified source

.DESCRIPTION
This function first parse all informations from w32tm.exe to extract needed informations
If you don't specify a specific source, it'll check delta with all NTP sources registered in the NTP configuration.
If -Full is specified, It'll check also if the NTP Service is properly configured, at least if it's started ;). But this method use WinRM connection to target computer. Be sure to enable thie features before use it.
All will re returned as an object so you could export it by pipeline and work smoothy with results.

.PARAMETER ComputerName
Here you can specify a string list or a simple computername

.PARAMETER TimeSource
This parameter is the NTP source you wanna compare with your computer's time.

.PARAMETER FULL
This will also check if the service is started on remote host
It'll also check if the 123 port is open (if firewall started)

.EXAMPLE
C:\PS> Get-NTP -ComputerName SERVER1 -TimeSource 187.25.12.89
C:\PS> "SERVER1","SERVER2","SERVER3" | Get-NTP -TimeSource 187.25.12.89
C:\PS> Get-Content C:\PS\Servers.txt | Get-NTP

.LINK
PowerTheShell: http://pwrshell.net

.NOTE
Author: Fabien Dibot (@fdibot)
http://pwrshell.net
Version: 0.1
Copyright: Copyleft

#>

Function Get-NTP {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Position=0,Mandatory=$false,ValueFromPipeline=$true)]
        [String[]]$ComputerName = $env:COMPUTERNAME,
        [String]$TimeSource,
        [Switch]$Full
    )

    BEGIN {
        Write-Verbose "Creating an empty array for output"
        $Output = @()
        Write-Verbose "Testing w32tm existance"
        if (!(Test-Path (Join-Path -Path $env:SystemRoot -ChildPath '\system32\w32tm.exe'))) {
            Throw "w32tm is not available on this system."
        }
        $ServiceStatus = ""
        $Status = "Configured"
        $StartMode = ""
        $DeltaTime = "N/A"
    }
    PROCESS {
        $ComputerName | % {
            $Server = $_
            if ($psCmdlet.ShouldProcess("$Server", "Test-Connection")) {
                Write-Verbose "Test connection between the computer which execute the script and $($_)"
                if (Test-Connection -ComputerName $Server -Count 1 -Quiet -ErrorAction SIlentlyContinue) {
                    if ($Full) {
                        Write-Verbose "Check NTP Service status"
                        Write-Verbose "Creating CIM Session"
                        Try {
                            $CIMSession = New-CimSession $Server -ErrorAction SilentlyContinue
                            $NTPService = Get-CIMInstance -CimSession $CIMSession -ClassName win32_service -Filter "Name= 'W32Time'" -ErrorAction SilentlyContinue
                            $StartMode = $NTPService.StartMode
                            $ServiceStatus = $NTPService.Status
                        }
                        Catch {
                            $StartMode = "N/A"
                            $ServiceStatus = "N/A"
                        }
                    } # End If $Full
                    Write-Verbose "Connecting with $Server OK. Continue NTP check."
                    Write-verbose "Gathering NTP configuration for $($_)"
                    Try {
                        $NTPConfiguration = w32tm /query /computer:$Server /configuration
                        if ($NTPConfiguration -contains "Enabled") {
                            $Status = "NotConfigured"
                        }
                        Else {
                            $Status = "Configured"
                            Write-Verbose "Parsing all informations from w32tm query"
                            if (!($TimeSource)){
                                $Source = $NTPConfiguration | ? {$_ -match 'ntpserver:'} | % { ($_ -split ":\s\b")[1] }
                                if ($source) { 
                                    $Source = $Source.Split(" ")[0]
                                    $Source = $Source.Replace(",0x1","")
                                }
                                $DeltaTime = Invoke-Command -ScriptBlock { 
                                    param ($Source)
                                    w32tm /stripchart /computer:$Source /samples:1 /dataonly 
                                    } -ComputerName $Server -ArgumentList $Source
                                $Deltatime = $DeltaTime | ? { $_  -match '[\+|\-][0-9][0-9].[0-9]{7}s' } 
                                $DeltaTime = $DeltaTime.split(" ")[1]

                            }
                            Else {
                                $DeltaTime = Invoke-Command -ScriptBlock { 
                                    param($TimeSource)
                                    w32tm /stripchart /computer:$TimeSource /samples:1 /dataonly 
                                    } -ComputerName $Server -ArgumentList $TimeSource
                                $Deltatime = $DeltaTime | ? { $_ -match '[\+|\-][0-9][0-9].[0-9]{7}s' } 
                                $DeltaTime = $DeltaTime.split(" ")[1]
                            }
                        } # End if $NTPConfiguration 
                    }
                    Catch {
                        Write-Warning $_.Exception.Message 
                    }
                    Finally {
                       Write-Verbose "Object creation and adding it to Final output object"
                       if (!($TimeSource)) { 
                            $NTPSource = $Source 
                       }
                       else { 
                            $NTPSource = $TimeSource
                       }
                       $Params = [ordered]@{"ComputerName"=$Server;
                                   "TimeSource"=$NTPSource;
                                   "NTPStatus"=$Status;
                                   "NTPService"=$ServiceStatus;
                                   "NTPServiceStartMode"=$StartMode;
                                   "Delta"=$DeltaTime}
                       $Output += New-Object -TypeName PSCustomObject -Property $Params
                    } # end Try/catch/Finally
                }
                Else {
                    Write-Warning "Can't connect to $Server"
                } # End Test-Connection
            } # End ShouldProcess
        } # End Foreach $ComputerName
    }
    END {
        $Output
    }
}

Get-NTP -ComputerName vdlnc00261.nedcar.nl -TimeSource ntp1.nedcar.nl
