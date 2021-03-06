# =========================================================
#
# Marcel Jussen
# 4-11-2014
#
# =========================================================
cls

# ---------------------------------------------------------
# Includes
Import-Module VNB_PSLib -Force -ErrorAction Stop

Function Append-Log {
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Write-host "[$logtime]: $message"
	Add-Content $SCRIPTLOG "[$logtime]: $message" -ErrorAction SilentlyContinue
}

Function ReqCleaner {
	param (
		[string]$Requestor
	)
	$retval = $null
	
	$RqArr = $Requestor -Split "\."
	if($RqArr.Count -eq 5) {
		$retval = $RqArr[0] + '.' + $RqArr[1] + '.' + $RqArr[2] + '.' + $RqArr[3]
	}
	if($RqArr.Count -eq 4) {
		$retval = $RqArr[0] + '.' + $RqArr[1] + '.' + $RqArr[2] 
	}
	
	return $Retval
}

Function Record-Requestor {
	param (
		[string]$Requestor,
		[string]$LogFile,
		[string]$LogTime
	)
	
	$Requestor = ReqCleaner $Requestor
	
	$NoSave = $false
	# if($Requestor -match 'DC07') { $NoSave = $true }
	# if($Requestor -match 'DC08') { $NoSave = $true }
	
	if($NoSave -eq $false) { 
		$query = "select kmsrequests from KMS_SCAN where systemname = '" + $Requestor + "'"
	  	$data = Query-SQL $query $conn
		# Check if this requestor has been registered before
		if($data) {
			$kmsrequests = $data[0]
			$kmsrequests ++
			$query = "UPDATE [dbo].[KMS_SCAN] SET [poldatetime]=GetDate(), [logfile]='$logfile', [logtime]='$logtime', [kmsrequests]=$kmsrequests WHERE [systemname]='$Requestor'"
			$data = Query-SQL $query $conn
		} else {
			$kmsrequests = 1
			$query = "INSERT INTO [dbo].[KMS_SCAN] ([poldatetime],[systemname],[kmsrequests],[logfile],[logtime]) VALUES (GetDate(), '$Requestor', $kmsrequests, '$logfile', '$logtime' )"
			$data = Query-SQL $query $conn
		}
	}
}

Function Import_Log {
	param (
		[string]$logfile
	)
	
	$reader = [System.IO.File]::OpenText($logfile)
	try {
    	for(;;) {
        	$line = $reader.ReadLine()
        	if ($line -eq $null) { break }
        	# process the line
			$linearr = $line -Split ' '			
			if($linearr.Count -ge 7) { 
				$logtime = $linearr[0]
				$source = $linearr[2]
				$dest = $linearr[4]				
				$search = ($dest -match 'S007')
				if($search) {				
					Record-Requestor $source $logfile $logtime
				}
			}
	    	}	
	}
	finally {
    		$reader.Close()
	}
}

cls

$SCRIPTLOG = $env:SystemDrive + "\Logboek\KMS_SCAN_Import.log"
if(Test-Path($SCRIPTLOG)) { Remove-Item $SCRIPTLOG -ErrorAction SilentlyContinue }
Append-Log "Start import KMS Scan log files."

# Create MSSQL connection
$conn = Read-UDLConnectionString $glb_UDL
if ($conn.state -eq "Closed") { 
	Append-Log "ERROR: could not connect to $Global:SECDUMP_SQLServer"
	exit 
}

$logpath = 'c:\Scripts\KMS_SCAN'
$files = Files_ByAge -Path $logpath -include '*.log' -age_in_days 0
if($files) {
	foreach($log in $files) {
		$logfile =  $logpath + '\' + $log.Name
		Append-Log "Importing $logfile"
		Import_log $logfile	
		
		$newfile = $logfile.Replace('.log', '.lo_')
		Append-log "Rename $logfile"
		Append-Log " to $newfile"
		Rename-Item -Path $logfile -NewName $newfile
	}
} else {
	Append-Log "Nothing to do."
}

Remove-SQLconnection $conn

Append-Log "Done."