# ---------------------------------------------------------
# Check SCCM inactive clients
#
# Marcel Jussen
# 30-1-2014
# ---------------------------------------------------------

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:ErrorCount = 0
$Global:WarningCount = 0
$Global:DEBUG = $true
$Global:ScriptPath = $null

Function Collect_Systems_SCCM {
		
	$UDLPath = $Global:ScriptPath  + "\Connection.udl"
	$Results = $null
	
	if([System.IO.File]::Exists($UDLPath)) {
		$UDL = Read-UDL-ConnectionString $UDLPath
		
		# Check if the required collection exists in CM_VNB
		$query = "select ResultTableName from [CM_VNB].[dbo].[v_Collections] where collectionname = 'Inactive clients'"
		$TSQL = Invoke-UDL-SQL $query $UDL
		if($TSQL -ne $null) {		
			$ViewName = [string]$TSQL.ResultTableName
			$query = "select name from [CM_VNB].[dbo].[$ViewName]"
			$CollSystemNames = Invoke-UDL-SQL $query $UDL
			$Results = @()
			foreach($System in $CollSystemNames) {
				$Results += $System.name
			}
			$Results = $Results | Sort-Object
		} 
	} 
	return $Results
}

Function Get-ScriptDirectory
{
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
$Global:ScriptPath = Get-ScriptDirectory

$DNSDomain = Get-DnsDomain
$SysColl = Collect_Systems_SCCM

foreach($Sysname in $SysColl) {	
	$SysDNSname = $Sysname + '.' + $DNSDomain
	$IsAlive = IsComputerAlive $SysDNSname
	if($IsAlive) {
		$ADFound = Search-AD-Computer $Sysname
		Write-Host "$SysDNSname - $IsAlive - $ADFound"
	}
}