. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

function Get-RegexNamedGroups($hash)
{
    $newHash = @{};
    $hash.keys | ? { $_ -notmatch '^\d+$' } | % { $newHash[$_] = $hash[$_] }
    $newHash
}

function ImportWith-Regex([string]$FilePath, [string]$regex)
{
    Get-Content $FilePath | ForEach-Object {
        if ($PSItem -match $regex)
        {
            New-Object PSObject -Property (Get-RegexNamedGroups $matches)
        }   
    }
} 

function Import-ApacheLog($FileName)
{
    $apacheExtractor = "(?<Host>\S*)",
       "(?<LogName>.*?)",
       "(?<UserId>\S*)",
       "\[(?<TimeStamp>.*?)\]",
      "`"(?<Request>[^`"]*)`"",
       "(?<Status>\d{3})",
       "(?<BytesSent>\S*)" -join "\s+"
    ImportWith-Regex $FileName $apacheExtractor
}

function Import-NCSA-Log($LogFilename){
	Write-Host "Creating hash from $LogFilename"
	$hash = Import-ApacheLog $LogFilename
	
	$SQLconn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
	if ($SQLconn.state -eq "Closed") { 
		Write-Host "The SQL connection could not be made or is forcefully closed."	
		return 0	
	}

	Write-Host "Importing log entries into SQL from $LogFilename"
	foreach($log in $hash) {
		$IIS_TimeStamp = $log.TimeStamp
		# Remove slashes
		$IIS_TimeStamp = ($IIS_TimeStamp -split ' ')[0]
		$index = $IIS_TimeStamp.IndexOf(':')
		$IIS_TimeStamp = $IIS_TimeStamp.Substring(0,$index) + ' ' + $IIS_TimeStamp.Substring($index+1)
		$IIS_TimeStamp = $IIS_TimeStamp.Replace('/',' ')
		
		$IIS_Logname = $LogFilename
		$IIS_Host = $log.Host
		$IIS_UserID = $log.UserID
		$IIS_Status = $log.Status
		$IIS_Request = $log.Request
		$IIS_BytesSent = $log.BytesSent

		$query = "insert into IIS_LOGTABLE_NCSA " +       		
		"(systemname, domainname, poldatetime, IIS_TimeStamp, IIS_Logname, IIS_Host, IIS_UserID, IIS_Status, IIS_Request, IIS_BytesSent) " +
		" VALUES ( " + 
		"'" + $Env:COMPUTERNAME + "'," + 
		"'" + $Env:USERDOMAIN + "',GetDate()," +
		"'" + $IIS_TimeStamp + "'," +           	
		"'" + $IIS_Logname + "'," +
		"'" + $IIS_Host + "'," +
		"'" + $IIS_UserID + "'," +           	
		"'" + $IIS_Status + "'," +	
		"'" + $IIS_Request + "'," +	
		"" + $IIS_BytesSent + ")"			
		$data = Query-SQL $query $SQLconn
	}

	Remove-SQLconnection $SQLconn

}

cls

$Path = '\\vs008\c$\SMTP-log\SMTPSVC1\'

$Now = Get-Date		
$Age_in_days = 1
$LastWrite = $Now.AddDays(- $Age_in_days)	

# Files older than Age_in_days
# $Files = Get-ChildItem -path $Path -Force -errorAction SilentlyContinue | where {$_.psIsContainer -eq $false} | where {$_.LastWriteTime -le "$LastWrite"} 
# foreach($LogFilename in $Files) { Import-NCSA-Log($Path + '\' + $LogFilename) }
# return 0

$Date = Get-Date
$Date = $Date.adddays(-1)
$Date2Str = $Date.ToString("yyyMMdd")
$Files = Get-ChildItem "\\vs008\c$\SMTP-log\SMTPSVC1\" | where {$_.psIsContainer -eq $false}
ForEach ($File in $Files){
	$FileDate = $File.creationtime
	$CTDate2Str = $FileDate.ToString("yyyyMMdd")
	if ($CTDate2Str -eq $Date2Str) {
		$LogFilename = "\\vs008\c$\SMTP-log\SMTPSVC1\" + $File
		$LogFilename		
		Import-NCSA-Log($LogFilename)
	}
}