<#
.SYNOPSIS
    VNB Library - Windows Services

.CREATED_BY
	Marcel Jussen

.VERSION
	2.3.0.1

.CHANGE_DATE
	20-11-2017

.DESCRIPTION
    Windows Services change/start/stop functions.
#>
#Requires -version 4.0

Function Stop-RemoteService
{
    # ---------------------------------------------------------
    #
    # ---------------------------------------------------------
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FQDN = $Env:COMPUTERNAME,

        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName
    )

    process
    {
        [void][System.Reflection.Assembly]::LoadWithPartialName('System.ServiceProcess')
        $Service = new-Object System.ServiceProcess.ServiceController($ServiceName, $FQDN)
        $Stopped = $true
        if ($Service.Status -ne "Stopped" )
        {
            try
            {
                $Service.Stop()
                $Service.WaitForStatus('Stopped', (new-timespan -seconds 10))
            }
            catch
            {
                $Stopped = $false
            }
        }
        return $Stopped
    }
}

Set-Alias -Name 'Remote-StopService' -Value 'Stop-RemoteService'

Function Start-RemoteService
{
    # ---------------------------------------------------------
    #
    # ---------------------------------------------------------
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FQDN = $Env:COMPUTERNAME,

        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName
    )

    process
    {
        [void][System.Reflection.Assembly]::LoadWithPartialName('System.ServiceProcess')
        $Service = new-Object System.ServiceProcess.ServiceController($ServiceName, $FQDN)
        $Started = $true
        if ($Service.Status -ne "Running" )
        {
            try
            {
                $Service.Start()
                $Service.WaitForStatus('Running', (new-timespan -seconds 10))
            }
            catch
            {
                $Started = $false
            }
        }
        return $Started
    }
}

Set-Alias -Name 'Remote-StartService' -Value 'Start-RemoteService'

Function Restart-RemoteService
{
    # ---------------------------------------------------------
    #
    # ---------------------------------------------------------
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FQDN = $Env:COMPUTERNAME,

        [parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName
    )

    process
    {
        try
        {
            [Void](Stop-RemoteService -FQDN $FQDN -ServiceName $ServiceName)
            Start-RemoteService -FQDN $FQDN -ServiceName $ServiceName
        }
        catch
        {
            throw
        }
    }
}

function Test-Service
{
    <#
    .SYNOPSIS
    Tests if a service exists, without writing anything out to the error stream.

    .DESCRIPTION
    `Get-Service` writes an error when a service doesn't exist.  This function tests if a service exists without writing anyting to the output stream.

    .OUTPUTS
    System.Boolean.

    .LINK
    Install-Service

    .LINK
    Uninstall-Service

    .EXAMPLE
    Test-Service -Name 'Drive'

    Returns `true` if the `Drive` service exists.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The name of the service to test.
        $Name
    )

    $service = Get-Service -Name "$Name*" |
        Where-Object { $_.Name -eq $Name }
    if ( $service )
    {
        return $true
    }
    else
    {
        return $false
    }
}

function Assert-Service
{
    <#
    .SYNOPSIS
    Checks if a service exists, and writes an error if it doesn't.

    .DESCRIPTION
    Also returns `True` if the service exists, `False` if it doesn't.

    .OUTPUTS
    System.Boolean.

    .LINK
    Test-Service

    .EXAMPLE
    Assert-Service -Name 'Drivetrain'

    Writes an error if the `Drivetrain` service doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The name of the service.
        $Name
    )

    if ( -not (Test-Service $Name) )
    {
        Write-Error ('Service {0} not found.' -f $Name)
        return $false
    }

    return $true
}

function Uninstall-Service
{
    <#
    .SYNOPSIS
    Removes/deletes a service.

    .DESCRIPTION
    Removes an existing Windows service.  If the service doesn't exist, nothing happens.  The service is stopped before being deleted, so that the computer doesn't need to be restarted for the removal to complete.  Even then, sometimes it won't go away until a reboot.  I don't get it either.

    .LINK
    Install-Service

    .EXAMPLE
    Uninstall-Service -Name DeathStar

    Removes the Death Star Windows service.  It is destro..., er, stopped first, then destro..., er, deleted.  If only the rebels weren't using Linux!
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        # The service name to delete.
        $Name
    )

    $service = Get-Service | Where-Object { $_.Name -eq $Name }
    $sc = (Join-Path $env:WinDir system32\sc.exe -Resolve)

    if ( $service )
    {
        if ( $pscmdlet.ShouldProcess( "service '$Name'", "remove" ) )
        {
            Stop-Service $Name
            & $sc delete $Name
        }
    }
}

Set-Alias -Name 'Remove-Service' -Value 'Uninstall-Service'

# ---------------------------------------------------------
# Export aliases
# ---------------------------------------------------------
export-modulemember -alias * -function *