# ---------------------------------------------------------
#
# Import wireless connections registered by CSU
# in SQL database secdump on S001.
# Marcel Jussen 9-12-2011
#
# ---------------------------------------------------------
cls
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "s001.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1
# ---------------------------------------------------------

$excel = New-Object -com Excel.Application
$excel.Visible=$false
$excel.DisplayAlerts=$false
$wbk = "D:\Wireless_Meting_v2.xls"

if (Test-Path $wbk)
{
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($conn.state -eq "Closed") { exit }   	

	$query = "delete from LogonWIFI"
	$data = Query-SQL $query $SQLconn

	$excel.Workbooks.open($wbk) | out-null  #drop the object info output	
	$worksheet = $excel.Worksheets.Item("Wireless_Meting V2") 	
	
	$rowstart = 2
	$column_mac = 1
	$column_ssid = 10
	$column_connecttime = 4
	$column_ip = 11
	
	$row = $rowstart 
		
	$MAC = [string]$worksheet.Cells.Item($row,$column_mac).Value()	
	$SSID = [string]$worksheet.Cells.Item($row,$column_ssid).Value()	
	$CONNECTTIME = [string]$worksheet.Cells.Item($row,$column_connecttime).Value()
	$IP = [string]$worksheet.Cells.Item($row,$column_ip).Value()
	
	while ($MAC.Length -ne 0) {	
		if (($SSID -eq "NEDBRNS053") -and ($IP -ne "0.0.0.0") -and ($IP.Lenght -lt 0)) {
		
			$query = "insert into LogonWIFI (NicMAC,NicIP,ConnectTime,EndTime) " +
				"VALUES('$MAC','$IP','$CONNECTTIME','')"
			$data = Query-SQL $query $SQLconn
		
			Write-Host "$MAC $IP $CONNECTTIME"
		}
		$row++
		$MAC = [string]$worksheet.Cells.Item($row,$column_mac).Value()	
		$SSID = [string]$worksheet.Cells.Item($row,$column_ssid).Value()
		$CONNECTTIME = [string]$worksheet.Cells.Item($row,$column_connecttime).Value()
		$IP = [string]$worksheet.Cells.Item($row,$column_ip).Value()
	}	
	
	Remove-SQLconnection $SQLconn
	$excel.Workbooks.Close()
} else {
	Write-Host "ERROR: Excel file $wbk cannot be found!"
}

<# Kill Excel or otherwise it will keep running in the background #>
spps -n excel 
