# =========================================================
#
# Marcel Jussen
# 4-11-2014
#
# =========================================================
cls
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1
. C:\Scripts\Secdump\PS\libFS.ps1

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

Function Record-DNS-Requestor {
	param (
		[string]$Requestor,
		[string]$LogFile,
		[string]$LogTime
	)
	
	$Requestor = ReqCleaner $Requestor
	
	$NoSave = $false
	if($Requestor -match 'DC07') { $NoSave = $true }
	if($Requestor -match 'DC08') { $NoSave = $true }
	
	if($NoSave -eq $false) { 
		$query = "select dnsrequests from DNS_SCAN where systemname = '" + $Requestor + "'"
	  	$data = Query-SQL $query $conn
		# Check if this requestor has been registered before
		if($data) {
			$dnsrequests = $data[0]
			$dnsrequests ++
			$query = "UPDATE [dbo].[DNS_SCAN] SET [poldatetime]=GetDate(), [logfile]='$logfile', [logtime]='$logtime', [dnsrequests]=$dnsrequests WHERE [systemname]='$Requestor'"
			$data = Query-SQL $query $conn
		} else {
			$dnsrequests = 1
			$query = "INSERT INTO [dbo].[DNS_SCAN] ([poldatetime],[systemname],[dnsrequests],[logfile],[logtime]) VALUES (GetDate(), '$Requestor', $dnsrequests, '$logfile', '$logtime' )"
			$data = Query-SQL $query $conn
		}
	}
}

Function Import_Log {
	param (
		[string]$logfile
	)
	$logfile
	
	$reader = [System.IO.File]::OpenText($logfile)
	try {
    	for(;;) {
        	$line = $reader.ReadLine()
        	if ($line -eq $null) { break }
        	# process the line
			$linearr = $line -Split ' '			
			if($linearr.Count -eq 8) { 
				$logtime = $linearr[0]
				$source = $linearr[2]
				$dest = $linearr[4]				
				$search = ($dest -match 'VS038')
				if($search) {				
					Record-DNS-Requestor $source $logfile $logtime
				}
			}
    	}	
	}
	finally {
    	$reader.Close()
	}
}

cls

$conn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($conn.state -eq "Closed") { exit }

$logpath = '\\vs038\c$\Scripts\DNS_SCAN'
$files = Files_ByAge -Path $logpath -include '*.log' -age_in_days 7
foreach($log in $files) {
	$logfile =  $logpath + '\' + $log.Name
	Import_log $logfile	
	
	$newfile = $logfile.Replace('.log', '.lo_')
	Rename-Item -Path $logfile -NewName $newfile
}

Remove-SQLconnection $conn
