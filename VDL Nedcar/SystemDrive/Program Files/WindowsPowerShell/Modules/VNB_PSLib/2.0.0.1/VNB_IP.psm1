<#
.SYNOPSIS
    VNB Library - IP networking functions

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	28-02-2015
 
.DESCRIPTION
    IP networking functions.
#>

Function Get-Hostname {
# ---------------------------------------------------------
# Return the DNS host name of the current computer
# ---------------------------------------------------------	
	process {
		([system.net.dns]::GetHostByName("localhost")).hostname
	}
}  

Set-Alias -Name 'Get-HostFQDN' -Value 'Get-HostName'

Function Resolve-DNSToIP {
# ---------------------------------------------------------
# Resolve DNS name to IP address
# ---------------------------------------------------------
	[CmdletBinding()]
	param ( 
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string]
		$DNSName 
	)
	Process {
		try { 
			[system.string]([System.Net.DNS]::GetHostAddresses($DNSName))
		}
		catch { return $null }
	}
} 

Function Resolve-IPToDNS {
# ---------------------------------------------------------
# Resolve IP address to DNS name
# ---------------------------------------------------------
	[CmdletBinding()]
	param ( 
		[parameter(Mandatory=$True)]
		[ValidateNotNullOrEmpty()]
		[system.string]
		$IPName
	)
	Process { 
		try {
			([System.Net.DNS]::GetHostByAddress($IPName)).hostname
		}
		catch { return $null }
	}
} 

function Get-IPAddress
{
    <#
    .SYNOPSIS
    Gets the IP addresses in use on the local computer.

    .DESCRIPTION
    The .NET API for getting all the IP addresses in use on the current computer's network intefaces is pretty cumbersome.  If all you care about is getting the IP addresses in use on the current computer, and you don't care where/how they're used, use this function.

    If you *do* care about network interfaces, then you'll have to do it yourself using the [System.Net.NetworkInformation.NetworkInterface](http://msdn.microsoft.com/en-us/library/System.Net.NetworkInformation.NetworkInterface.aspx) class's [GetAllNetworkInterfaces](http://msdn.microsoft.com/en-us/library/system.net.networkinformation.networkinterface.getallnetworkinterfaces.aspx) static method, e.g.

        [Net.NetworkInformation.NetworkInterface]::GetNetworkInterfaces()

    .LINK
    http://stackoverflow.com/questions/1069103/how-to-get-my-own-ip-address-in-c

    .OUTPUTS
    System.Net.IPAddress.

    .EXAMPLE
    Get-IPAddress

    Returns all the IP addresses in use on the local computer, IPv4 *and* IPv6.

    .EXAMPLE
    Get-IPAddress -IPV4

    Returns just the IPv4 addresses in use on the local computer.

    .EXAMPLE
    Get-IPADdress -IPV6

    Retruns just the IPv6 addresses in use on the local computer.
    #>
    [CmdletBinding(DefaultParameterSetName='NonFiltered')]
    param(
        [Parameter(ParameterSetName='Filtered')]
        [Switch]
        # Return just IPv4 addresses.
        $IPV4,

        [Parameter(ParameterSetName='Filtered')]
        [Switch]
        # Return just IPv6 addresses.
        $IPV6
    )

    [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
        Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } | 
        ForEach-Object { $_.GetIPProperties() } | 
        Select-Object -ExpandProperty UnicastAddresses  | 
        Select-Object -ExpandProperty Address |
        Where-Object {
            if( $PSCmdlet.ParameterSetName -eq 'NonFiltered' )
            {
                return ($_.AddressFamily -eq 'InterNetwork' -or $_.AddressFamily -eq 'InterNetworkV6')
            }

            if( $IPV4 -and $_.AddressFamily -eq 'InterNetwork' )
            {
                return $true
            }

            if( $IPV6 -and $_.AddressFamily -eq 'InterNetworkV6' )
            {
                return $true
            }

            return $false
        }
}

function Test-IPAddress
{
    <#
    .SYNOPSIS
    Tests that an IP address is in use on the local computer.

    .DESCRIPTION
    Sometimes its useful to know if an IP address is being used on the local computer.  This function does just that.

    .LINK
    Test-IPAddress

    .EXAMPLE
    Test-IPAddress -IPAddress '10.1.2.3'

    Returns `true` if the IP address `10.1.2.3` is being used on the local computer.

    .EXAMPLE
    Test-IPAddress -IPAddress '::1'

    Demonstrates that you can use IPv6 addresses.

    .EXAMPLE
    Test-IPAddress -IPAddress ([Net.IPAddress]::Parse('10.5.6.7'))

    Demonstrates that you can use real `System.Net.IPAddress` objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Net.IPAddress]
        # The IP address to check.
        $IPAddress
    )

    $ip = Get-IPAddress | Where-Object { $_ -eq $IPAddress }
    if( $ip )
    {
        return $true
    }
    else
    {
        return $false
    }
}

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *