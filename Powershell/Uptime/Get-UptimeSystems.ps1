# ---------------------------------------------------------
#
# Collect uptime information from domain servers and store
# in SQL database secdump on S001.
# Marcel Jussen
# 25-11-2011
#
# ---------------------------------------------------------
Import-Module VNB_PSLib -Force -ErrorAction Stop


Function Get-UpTime
{
#############################################################################
# Pre-Requisites: Requires PowerShell 2.0 and WMI access to target computers (admin access).
#
# Usage syntax:
# For local computer where script is being run: .\Get-Uptime.ps1.
# For list of remote computers: .\Get-Uptime.ps1 -ComputerList "c:\temp\computerlist.txt"
#
# Usage Examples:
#
# .\Get-Uptime.ps1 -Computer ComputerName
# .\Get-Uptime.ps1 -ComputerList "c:\temp\computerlist.txt" | Export-Csv uptime-report.csv -NoTypeInformation
#############################################################################
#Requires -Version 2.0

	param  (
		[Parameter(Position=0,ValuefromPipeline=$true)][string][alias("cn")]$computer,
		[Parameter(Position=1,ValuefromPipeline=$false)][string]$computerlist)

	If (-not ($computer -or $computerlist)) {
		$computers = $Env:COMPUTERNAME
	}
	If ($computer) {
		$computers = $computer
	}
	If ($computerlist) {
		$computers = Get-Content $computerlist
	}
	$Info = @{}
	foreach ($computer in $computers)
	{
		$wmi = Get-WmiObject -ComputerName $computer -Query "SELECT LastBootUpTime FROM Win32_OperatingSystem" -ErrorAction SilentlyContinue
		if ($wmi -ne $null) {
			$now = Get-Date
			$boottime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
			$uptime = $now - $boottime
			$d =$uptime.days
			$h =$uptime.hours
			$m =$uptime.Minutes
			$s = $uptime.Seconds
			$Info.$computer = "$d Days $h Hours $m Min $s Sec"
		} else {
			$boottime = $null
			$Info.$computer = $null
		}
	}
	$result = ($Info.GetEnumerator() | ForEach-Object { New-Object PSObject -Property @{ Systemname = $_.Key; Uptime = $_.Value; Last_Reboot = $boottime } | Select-Object -Property Systemname, Uptime, Last_Reboot })
	$result
}

Function get_OS {
	param  (
		[Parameter(Position=0,ValuefromPipeline=$true)][string][alias("cn")]$computer)
	If (-not ($computer)) { $computer = $Env:COMPUTERNAME }
	$objOS = Get-WmiObject -ComputerName $computer Win32_OperatingSystem -ErrorAction SilentlyContinue
	if ($objOS -ne $null) {
		foreach ($os in $objOS) {
    		$Result = $objOS.Version
  		}
	}
  	return $Result
}

Function get_DNSname {
	param  (
		[Parameter(Position=0,ValuefromPipeline=$true)][string][alias("cn")]$computer
	)
	If (-not ($computer)) { $computer = $Env:COMPUTERNAME }
	$objSystem = Get-WmiObject -ComputerName $computer Win32_ComputerSystem -ErrorAction SilentlyContinue
	if ($objSystem -ne $null) {
		ForEach ($system in $objSystem) {
    		$result = $system.DNSHostName
		}
  	}
  	return $Result
}

Function Get-WMIComputerSessions {
<#
.SYNOPSIS
    Retrieves tall user sessions from local or remote server/s
.DESCRIPTION
    Retrieves tall user sessions from local or remote server/s
.PARAMETER computer
    Name of computer/s to run session query against.
.NOTES
    Name: Get-WmiComputerSessions
    Author: Boe Prox
    DateCreated: 01Nov2010

.LINK
    https://boeprox.wordpress.org
.EXAMPLE
Get-WmiComputerSessions -computer "server1"

Description
-----------
This command will query all current user sessions on 'server1'.

#>
[cmdletbinding(
	DefaultParameterSetName = 'session',
	ConfirmImpact = 'low'
)]
    Param(
        [Parameter(
            Mandatory = $True,
            Position = 0,
            ValueFromPipeline = $True)]
            [string[]]$computer
    )
Begin {
    #Create empty report
    $report = @()
    }
Process {
    #Iterate through collection of computers
    ForEach ($c in $computer) {
        #Get explorer.exe processes
        $proc = gwmi win32_process -computer $c -Filter "Name = 'explorer.exe'" -ErrorAction SilentlyContinue
		if ($proc -ne $null) {
        	#Go through collection of processes
        	ForEach ($p in $proc) {
            	$temp = "" | Select Computer, Domain, User
            	$temp.computer = $c
            	$temp.user = ($p.GetOwner()).User
            	$temp.domain = ($p.GetOwner()).Domain
            	$report += $temp
			}
        }  else {
			 $report = "" | Select Computer, Domain, User
			 $report.computer = $c
		}
	  }
    }
End {
    $report
    }
}


# ------------------------------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"

# ---------------------------------------------------------
# Open SQL Connection (connection name is script name)
$conn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($conn.state -eq "Closed") { exit }

# $colResults = collectAD_Servers
$colResults = collectAD_Computers
$syscount = 0
$total = $colResults.Count
foreach ($objResult in $colResults) {
	$syscount++
	$objItem = $objResult.Properties
	$Systemname = [string]$objItem.name
	$DNSName = $null
	if ($objItem.name -ne $null) {
		$DNSName = $Systemname + '.nedcar.nl'
		$alive = IsComputerAlive ($DNSName)
		if ($alive -eq $true) {
			$IP = ResolveDNS ($DNSName)

			$query = "delete from SystemUptime where systemname='" + $Systemname + "'"
			$data = Query-SQL $query $conn
			$uptimedata = Get-UpTime($DNSName)

			$Uptime = $uptimedata.Uptime
			$Last_Reboot = $uptimedata.Last_Reboot

			$RemoteDNS = get_DNSname($DNSName)
			$Os = Get_OS($DNSName)

			$LU = Get-WmiComputerSessions -computer $DNSName
			$LastUser = $LU.User

			$query = "insert into SystemUptime(systemname, domainname, poldatetime, Dnsname, RemoteDNS, OS, LastUser, IPname, Uptime, Last_Reboot) VALUES (" +
				"'" + $Systemname + "','" + $Env:USERDOMAIN + "',GetDate()," +
				"'" + $DNSName + "'," +
				"'" + $RemoteDNS + "'," +
				"'" + $OS + "'," +
				"'" + $LastUser + "'," +
				"'" + $IP + "'," +
				"'" + $Uptime + "'," +
				"'" + $Last_Reboot + "')"
			$data = Query-SQL $query $conn

			Echo-Log "$syscount of $total : $Systemname, $IP, $Uptime, $Last_Reboot"
		} else {
			Echo-Log "$syscount of $total : $DNSName is not alive."
		}
	}
}

Remove-SQLconnection $conn
