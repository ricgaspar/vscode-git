# ---------------------------------------------------------
#
# Generic Functions
# Marcel Jussen
# 8-8-2013
#
# ---------------------------------------------------------
#Requires -Version 2.0   

function Test-Admin {
# --------------------------------------------------------- 
# Returns true if current user is an Administrator
# ---------------------------------------------------------
 $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
 $principal = new-object Security.Principal.WindowsPrincipal $identity 
 $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)   
}

Function Get-UpTime
{
# ---------------------------------------------------------
# Returns system uptime
#
# Usage syntax: 
# For local computer where script is being run: Get-Uptime
# For remote computer: Get-Uptime -ComputerName "systemx"
# For list of remote computers: Get-Uptime -ComputerList "c:\temp\computerlist.txt" 
# ---------------------------------------------------------
	param  (     
		[Parameter(Position=0,ValuefromPipeline=$true)][string][alias("cn")]$computer,     
		[Parameter(Position=1,ValuefromPipeline=$false)][string]$computerlist)   
	
	If (-not ($computer -or $computerlist)) { $computers = $Env:COMPUTERNAME }   
	If ($computer) { $computers = $computer	}   
	If ($computerlist) { $computers = Get-Content $computerlist	}   
	
	$Info = @{}   
	foreach ($computer in $computers)  
	{     
		$wmi = Get-WmiObject -ComputerName $computer -Query "SELECT LastBootUpTime FROM Win32_OperatingSystem"    
		$now = Get-Date    
		$boottime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)     
		$uptime = $now - $boottime    
		$d =$uptime.days     
		$h =$uptime.hours     
		$m =$uptime.Minutes     
		$s = $uptime.Seconds     
		$Info.$computer = "$d Days $h Hours $m Min $s Sec"
	}   
	$result = ($Info.GetEnumerator() | ForEach-Object { New-Object PSObject -Property @{ Systemname = $_.Key; Uptime = $_.Value; Last_Reboot = $boottime } | Select-Object -Property Systemname, Uptime, Last_Reboot }) 
	$result 
}
