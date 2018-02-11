# ---------------------------------------------------------
#
# Scheduled Tasks Functions
# Marcel Jussen
# 10-3-2011
#
# ---------------------------------------------------------

Function Get-ScheduledTask {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	param(
		[string]$ComputerName 
	)
	If (-not ($ComputerName)) { $ComputerName = $Env:COMPUTERNAME }   
	$Command = "schtasks.exe /query /s $ComputerName"
	Invoke-Expression $Command
	Clear-Variable Command -ErrorAction SilentlyContinue	
}

Function End-ScheduledTask {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	param(
	[string]$ComputerName,
	[string]$TaskName = "blank"
	)

	If (-not ($ComputerName)) { $ComputerName = $Env:COMPUTERNAME }   
	If ((Get-ScheduledTask -ComputerName $ComputerName) -match $TaskName)
	{
		$Command = "schtasks.exe /End /s $ComputerName /tn $TaskName "
		Invoke-Expression $Command
		Clear-Variable Command -ErrorAction SilentlyContinue			 
	}
}

Function Run-ScheduledTask {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	param(
	[string]$ComputerName,
	[string]$TaskName = "blank"
	)
	If (-not ($ComputerName)) { $ComputerName = $Env:COMPUTERNAME }   
	If ((Get-ScheduledTask -ComputerName $ComputerName) -match $TaskName)
	{
		$Command = "schtasks.exe /Run /s $ComputerName /tn $TaskName "
		Invoke-Expression $Command
		Clear-Variable Command -ErrorAction SilentlyContinue			 
	}
}

Function Remove-ScheduledTask {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	param(
	[string]$ComputerName,
	[string]$TaskName = "blank"
	)
	If (-not ($ComputerName)) { $ComputerName = $Env:COMPUTERNAME }   
	If ((Get-ScheduledTask -ComputerName $ComputerName) -match $TaskName)
	{
		$Command = "schtasks.exe /delete /s $ComputerName /tn $TaskName /F"
		Invoke-Expression $Command
		Clear-Variable Command -ErrorAction SilentlyContinue
	} 
}

Function Create-ScheduledTask {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	param(
	[string]$ComputerName,
	[string]$RunAsUser = "System",
	[string]$TaskName = "MyTask",
	[string]$TaskRun = '"C:\Program Files\Scripts\Script.vbs"',
	[string]$Schedule = "Monthly",
	[string]$Modifier = "second",
	[string]$Days = "SUN",
	[string]$Months = '"MAR,JUN,SEP,DEC"',
	[string]$StartTime = "13:00",
	[string]$EndTime = "17:00",
	[string]$Interval = "60"	
	)
	
	If (-not ($ComputerName)) { $ComputerName = $Env:COMPUTERNAME }
	$Command = "schtasks.exe /create /s $ComputerName /ru $RunAsUser /tn $TaskName /tr $TaskRun /sc $Schedule /mo $Modifier /d $Days /m $Months /st $StartTime /et $EndTime /ri $Interval /F"
	Invoke-Expression $Command
	Clear-Variable Command -ErrorAction SilentlyContinue
}

Function Export-ScheduledTasks {
# --------------------------------------------------------- 
# 
# ---------------------------------------------------------
	param(
		[string]$ComputerName
	)	
	If (-not ($ComputerName)) { $ComputerName = $Env:COMPUTERNAME }
	$TempReport=$Env:TEMP + "\temp.csv"
	schtasks /QUERY /S $ComputerName /FO CSV /V > $TempReport
	$TempCsv = Import-Csv $TempReport
	Remove-Item $TempReport
	return $TempCSV		
}