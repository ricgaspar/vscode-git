# ---------------------------------------------------------
# Alter Notes field per user
#
# Marcel Jussen
# 5-4-2014
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libFS.ps1
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $true

Function Erase_User_Notes {
	param ( 
		[string]$DN, 
		[string]$Info = ""
	)
	if([string]::IsNullOrEmpty($DN)) { return $null }
	$obj = [ADSI]$DN
	if($obj -ne $null) {		
		$Cur = $obj.info
		$CurVal = $Cur.value
		if($Cur -ne $null) { 
  			if(($Info -ne $null) -and ($Info.length -gt 0)) {
				# Change field when input value is not empty and different from current value
				if ( $CurVal.CompareTo($Info) -ne 0 ) {
  					$obj.Put("info", $Info)
    				$obj.SetInfo()
				}
			} else {
				# Erase field when input value is empty
				$obj.PutEx(1, "info", 0)
    			$obj.SetInfo()			
			}
		} else {
			# Change value is current value is empty and new value is not empty.
			if(($Info -ne $null) -and ($Info.length -gt 0)) {
				$obj.Put("info", $Info)
    			$obj.SetInfo()				
			}
		}
	}
  	return $null
}

#----
# Check type of variable returned by SQL
# If type DBNull then replace with empty string
#----
Function Reval_Parm { 
	Param (
		$Parm
	)
	if(($Parm -eq $null) -or ($Parm.Length -eq 0)) { $Parm = "" }
	$VarType = $Parm.GetType()	
	if($VarType.Fullname -eq "System.DBNull") { $Parm = "" }
	if($Parm -ne $null) { $Parm = $Parm.trim() }
	Return $Parm
} 

#----
# Query SEDCUMP for list of new AD accounts to create
#----
Function collect_Users_SQL {
	# ------------------------------------------------------------------------------
	# Connect to SQL server

	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."	
		$ErrorVal=9010
		return $ErrorVal
	}

	# Init return value
	$ErrorVal = 0	
	
	# What is our domain.
	$UserDomain = Get-NetbiosDomain

	# Query lists all new accounts with status ISP_VERIFIED=Y and ISP_AD_INSERT=Y
	# Query is extended with account create information.
	$query = "select * from vw_UsersAD_Temp"
	Echo-Log "Parse query: $query"
	$data = Query-SQL $query $SQLconn
	if ($data -ne $null) {
		$reccount = $data.Count
		if ($reccount -eq $null) { $reccount = 1 } 
		Echo-Log "Number of records returned: $reccount"
		$Global:Changes_Proposed = $reccount
		Echo-Log ("-"*60)
		ForEach($rec in $data) {			
		
			#
			# Retrieve data from SQL record
			#
			$SAMAccountName = Reval_Parm $rec.SAMAccountName
			$PATH = Reval_Parm $rec.Path
			$DN = Reval_Parm $rec.DN
						
			Echo-Log "($SAMAccountName) $Path"
			
			# Create a domain account, fill account fields and add to default domain groups
			[Void](Erase_User_Notes $Path)										
		}			
	} else {
		Echo-Log "No records found."
	}	

	# ------------------------------------------------------------------------------
	Echo-Log ("-"*60)	
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log "Proposed changes found in SQL result    : $Global:Changes_Proposed"
	Echo-Log "Changes committed to Active Directory   : $Global:Changes_Committed"
	if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }
	Echo-Log ("-"*60)	
	Echo-Log "Closing SQL connection."
	Remove-SQLconnection $SQLconn
	return $ErrorVal
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Users_SetNotes-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"
Echo-Log ("-"*60)

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

Echo-Log "Inventory users accounts in the domain."
$userCol = collect_Users_SQL

Echo-Log "Altering notes field per user"
foreach($User in $userCol) {
	$path = $User.Path
	if($path -ne $null) {
		$path = $path.ToUpper()
		if($path.Contains("OU=NEDCAR,DC=NEDCAR,DC=NL")) {			
			$obj = [ADSI]$path
			$SamAccountName = $obj.sAMAccountName.value
#			Repair_User_CtxProf $SamAccountName
		}
	}
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if ($Global:Changes_Committed -ne 0) {
	$Title = "Repair User home directories. $cdtime ($Global:Changes_Committed changes committed)" 	
} else {
	$Title = "Repair User home directories. $cdtime (No changes committed)" 
}

if($Global:DEBUG) {
	Echo-Log "** Debug: Sending resulting log as a mail message."
} 

$SendTo = "nedcar-events@kpn.com"
$dnsdomain = Get-DnsDomain
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

# Send-HTMLEmail-LogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
