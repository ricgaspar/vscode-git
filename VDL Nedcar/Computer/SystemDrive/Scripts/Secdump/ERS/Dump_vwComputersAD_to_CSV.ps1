# ---------------------------------------------------------
# Save vw_UsersAD to CSV
#
# Marcel Jussen
# 11-11-2014
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

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd"
$logfile = "Secdump-Dump_vw_ComputersAD_to_CSV-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"

$CSVFolder = '\\nedcar.nl\office\IM\6-Application Management\Local Support\DTM\3-CMDB\addata\'
$CSVFile = 'Active Directory - Computer accounts.csv'

$CSVPath = $CSVFolder + $CSVFile

if(Test-Path $CSVFolder) {
	Echo-Log "Output folder $CSVFolder was found."
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Echo-Log "The SQL connection could not be made or is forcefully closed."		
	} else {

		$query = "select * from vw_VNB_P_DOMAIN_COMPUTERS"
		Echo-Log "Parse query: $query"
		$data = Query-SQL $query $SQLconn
		if ($data -ne $null) {
			$reccount = $data.Count
			if ($reccount -eq $null) { $reccount = 1 } 
			Echo-Log "Number of records returned: $reccount"
	
			Echo-Log "Writing records to CSV file."
			$data | Export-Csv -Force -Path $CSVPath -NoTypeInformation -encoding "unicode"
		}

		Echo-Log "Closing SQL connection."
		Remove-SQLconnection $SQLconn
	}
	
} else {
	Echo-Log "ERROR: Output folder could not be found!"
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

Close-LogSystem