# =========================================================
#
# Marcel Jussen
# 17-04-2014
#
# =========================================================

# $erroractionpreference = "SilentlyContinue"

cls
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libSQL.ps1
. C:\Scripts\Secdump\PS\libAD.ps1

cls

function CheckComputerConnectivity($computer)
{
	$bPing = $false
	$bShare = $false
	$result = $false
	#Firstly check if the computer can be pinged.	
	$PingResult = IsComputerAlive($computer)
	if ($PingResult -eq $true)
	{
		$bPing = $true
		#Secondly check if can browse to the scheduled task share
		$path = "\\$computer\admin`$\tasks"
		$ShareErr = $null
		$ShareResult = Get-ChildItem $path -ErrorVariable ShareErr
		if ($ShareErr.count -eq 0) { $bShare = $true }
						
	}
	if ($bPing -eq $true -and $bShare -eq $true)
	{ $result = $true }
	return $result
	
}

function GetServersFromOU([string]$strDomainName, [array]$arrOUs)
{
	$arrDCs = $strDomainName.split(".")
	$strFullDC = $null
	foreach ($DC in $arrDCs)
	{
		if ($strFullDC -eq $null) { $strFullDC = "DC=$DC" }
		else { $strFullDC = "$strFullDC,DC=$DC" }			
	}
			
	$arrComputers = @( )
	foreach ($Ou in $arrOUs)
	{
		$strFilter = "computer"
										
		$objDomain = New-Object System.DirectoryServices.DirectoryEntry
										
		$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
		$objSearcher.SearchRoot = "LDAP://OU=$OU,$strFullDC"
		$objSearcher.SearchScope = "subtree" 
		$objSearcher.PageSize = 3000
										
		$objSearcher.Filter = "(objectCategory=$strFilter)"
		$colResults = $objSearcher.FindAll()
					
						
		foreach ($i in $colResults)
		{
			$objComputer = $i.GetDirectoryEntry()
			$arrComputers += $objComputer.Name
		}
	}
	$arrcomputers = $arrcomputers | Sort-Object
	return $arrComputers
}

#
# Translates object property type table to T-SQL data type table
#
Function Translate_Properties {
	param (
		$PropertyList
	)	
	if([string]::IsNullOrEmpty($PropertyList)) { return $null }		
	$VarList = @()
	foreach($Prop in $PropertyList) {
		$PropertyName = [string]$Prop.Name
		$PropertyDefinition = [string]$Prop.Definition		
		$PropertyType = $null
		if($PropertyDefinition.Length -gt 0) {
			$PropertyType = $PropertyDefinition.split()
		}
		if($PropertyType.Count -gt 0) { 				
			switch ($PropertyType[0]) 
    		{ 
        		'bool'		{ $VarType = '[nchar](5)' } 
				'date'		{ $VarType = '[datetime]' } 
        		'int' 		{ $VarType = '[int]' } 
				'uint' 		{ $VarType = '[bigint]' } 
        		'string'	{ $VarType = '[varchar](max)' }
				default 	{ $VarType = "[varchar](max)" }    		
			}			
			$VarDef = "[$PropertyName] $vartype"
			$VarList += $VarDef
		}
	}
	return $VarList
} 

#
# Create a table with an array of vars
#
Function Create_Table_ByVarlist {
	param (
		$ADOConnection,
		[string]$TableName,
		[array]$Varlist,		
		$ExtraColumns = $null,
		$ExtraColumnTypes = $null
	)
	
	if($ADOConnection -eq $null) { return $null }
	if([string]::IsNullOrEmpty($TableName)) { return $null }
	if([string]::IsNullOrEmpty($Varlist)) { return $null }	

	# Create table if it does not exist
	$TSQL = "IF NOT (EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = '$TableName')) BEGIN "	
	$TSQL += "CREATE TABLE [dbo].[$TableName] ("
	
	if(($ExtraColumns -ne $null) -and ($ExtraColumnTypes -ne $null)) { 
		$einde = $ExtraColumns.Count
		for($cnt=0; $cnt -lt $einde; $cnt++) {
			$Column = $ExtraColumns[$cnt]
			$ColumnType = $ExtraColumnTypes[$cnt]
			$TSQL += "$Column $ColumnType,"
		}
	}
	
	$VarCount = $Varlist.Count
	if($VarCount -gt 1) {		
		for ($cnt=0; $cnt -le ($VarCount-2); $cnt++) {
			$var=$Varlist[$cnt]
			$TSQL += "$var,"
		}
		$var=$Varlist[$cnt]
		$TSQL += "$var)"
	}
	$TSQL += " END"	
	Query-SQL $TSQL $ADOConnection	
}

#
# Insert values in a table with an array of vars and an object with values
#
Function Insert_Values_ByVarList {
	param (
		$ADOConnection,
		[string]$TableName,
		[array]$Varlist,
		$Values,
		$ExtraColumns = $null,
		$ExtraColumnsVals = $null
	)
	
	if($ADOConnection -eq $null) { return $null }
	if($Values -eq $null) { return $null }
	if([string]::IsNullOrEmpty($TableName)) { return $null }
	if([string]::IsNullOrEmpty($Varlist)) { return $null }		
	
	$tsql_varlist = ""
	$tsql_vallist = ""
	
	$ValNames = $Values | Get-Member -MemberType Properties | Select 'Name'		
	foreach($Val in $Values) {				
		
		# Add additional columns and values
		if (($ExtraColumns -ne $null) -and ($ExtraColumnsVals -ne $null)) { 
			for($cnt=0;$cnt -lt $ExtraColumns.Count; $cnt++) {
				$ec = $ExtraColumns[$cnt]
				$ecval = $ExtraColumnsVals[$cnt]				
				$tsql_varlist += "[$ec],"
				$tsql_vallist += "'$ecval',"
			}
		}
				
		# Add columns and values
		For($cnt=0;$cnt -le $ValNames.Count-2; $cnt++) {
			$ValueName = $ValNames[$cnt]
			$PropName = $ValueName.Name
			$PropValue = $Val.$PropName
			$tsql_varlist += "[$PropName],"
			$tsql_vallist += "'$PropValue',"
		}			
		$ValueName = $ValNames[$cnt]
		$PropName = $ValueName.Name
		$PropValue = $Val.$PropName
		$tsql_varlist += "[$PropName]"
		$tsql_vallist += "'$PropValue'"		
	}
	$TSQL = "INSERT INTO [dbo].[$TableName] ($tsql_varlist) VALUES ($tsql_vallist)"
	Query-SQL $TSQL $ADOConnection
}

# Open ADO connection
$ADO = New-SQLconnection 'vs064' 'SECDUMP'

# Drop tables.
Drop_Table "ScheduleServiceConnection" $ADO
Drop_Table "ScheduleServiceTasks" $ADO

$strDomain = "nedcar.nl"
$arrOUs = @( )
$arrOus += "APOLLO"
$arrOus += "C-LAN"
$arrOus += "SAP"
$arrOus += "VCTX_PS_FARM"
$arrOus += "XENAPP"

$arrComputers = GetServersFromOU $strDomain $arrOUs
$sch = New-Object -ComObject("Schedule.Service")

$arrComputers = @('s007')

foreach($computer in $arrComputers) { 
	$hostname = $computer
	$hostname
	$concheck = CheckComputerConnectivity($hostname)
	if($concheck -eq $true) {
		# Connect to scheduler		
		$sch.connect($hostname)

		# and retrieve root folder scheduled tasks
		$tasks = $sch.getfolder("\").gettasks(0)

		# Create table for ScheduleServiceConnection
		$PropertyList = $sch | Get-Member -Membertype Properties
		$Varlist = Translate_Properties $PropertyList
		Create_Table_ByVarlist $ADO "ScheduleServiceConnection" $Varlist

		# Insert values of ScheduleServiceConnection
		Insert_Values_ByVarList $ADO "ScheduleServiceConnection" $PropertyList $sch

		# Create array of extra columns and their values
		$ECols = @()
		$ECols += "TargetServer"
		$EColTypes = @()
		$EColTypes += "[varchar](25)"
		$EColsVals = @()
		$EColsVals += "$hostname"
	
		# Create table for ScheduleServiceTasks
		$PropertyList = $tasks | Get-Member -Membertype Properties
		$Varlist = Translate_Properties $PropertyList
		Create_Table_ByVarlist $ADO "ScheduleServiceTasks" $Varlist $ECols $EColTypes

		# Insert values of ScheduleServiceTasks
		foreach ($task in $tasks) {
			Insert_Values_ByVarList $ADO "ScheduleServiceTasks" $PropertyList $task $ECols $EColsVals
		}
	}
}

$ADO.Close()


