

# ---------------------------------------------------------
#
# Collect Exchange database statistics and store in secdump
# Marcel Jussen
#
# ---------------------------------------------------------
#requires -Version 2

# ---------------------------------------------------------
# INCLUDES
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
Connect-ExchangeServer -auto

#Import Localized Data
Import-LocalizedData -BindingVariable Messages

Function New-OSCPSCustomErrorRecord
{
	#This function is used to create a PowerShell ErrorRecord
	[CmdletBinding()]
	Param
	(
	   [Parameter(Mandatory=$true,Position=1)][String]$ExceptionString,
	   [Parameter(Mandatory=$true,Position=2)][String]$ErrorID,
	   [Parameter(Mandatory=$true,Position=3)][System.Management.Automation.ErrorCategory]$ErrorCategory,
	   [Parameter(Mandatory=$true,Position=4)][PSObject]$TargetObject
	)
	Process
	{
	   $exception = New-Object System.Management.Automation.RuntimeException($ExceptionString)
	   $customError = New-Object System.Management.Automation.ErrorRecord($exception,$ErrorID,$ErrorCategory,$TargetObject)
	   return $customError
	}
}

Function Get-OSCEXMailboxDatabaseStatistics
{
	<#
		.SYNOPSIS
		Get-OSCEXMailboxDatabaseStatistics is an advanced function which can be used to collect the properties of mailbox and mailbox database.
		.DESCRIPTION
		Get-OSCEXMailboxDatabaseStatistics is an advanced function which can be used to collect the properties of mailbox and mailbox database.
		.PARAMETER MailboxProperty
		Indicates the name of mailbox properties which will be retrieved, in the form "Name","Alias".
		Please do not use wildcard character(*) in the property name or as the value of this parameter.
		The property names should not be conflicted with the names of mailbox database property.
		.PARAMETER MailboxDatabaseProperty
		Indicates the name of mailbox database properties which will be retrieved, in the form "LastFullBackup","DatabaseSize".
		Please do not use wildcard character(*) in the property name or as the value of this parameter.
		The property names should not be conflicted with the names of mailbox property.
		.PARAMETER MailboxFilter
		Indicates the OPath filter used to find mailboxes.
		.EXAMPLE
		#Retrieve specified property values for all mailboxes
		Get-OSCEXMailboxDatabaseStatistics -MailboxProperty "Name","Alias" -MailboxDatabaseProperty "LastFullBackup","DatabaseSize" | Format-Table -Autosize
		.EXAMPLE
		#Retrieve specified property values for these mailboxes which alias starts with "TestUser0"
		Get-OSCEXMailboxDatabaseStatistics -MailboxProperty "Name","Alias" -MailboxDatabaseProperty "LastFullBackup","DatabaseSize" -MailboxFilter 'Alias -like "TestUser0*"' | Format-Table -Autosize
		.EXAMPLE
		#Retrieve specified property values for these mailboxes which alias starts with "TestUser0" and exports the results to a comma-separated values (CSV) file.
		Get-OSCEXMailboxDatabaseStatistics -MailboxProperty "Name","Alias" -MailboxDatabaseProperty "LastFullBackup","DatabaseSize" -MailboxFilter 'Alias -like "TestUser*"' | Export-Csv -Path c:\Scripts\mailbox-statistics.csv -NoTypeInformation
		.LINK
		Windows PowerShell Advanced Function
		http://technet.microsoft.com/en-us/library/dd315326.aspx
		.LINK
		Get-Mailbox
		http://technet.microsoft.com/en-us/library/bb123685.aspx
		.LINK
		Get-MailboxDatabase
		http://technet.microsoft.com/en-us/library/bb124924.aspx
	#>
	
	[CmdletBinding()]
	Param
	(
		#Define parameters
		[Parameter(Mandatory=$true,Position=1)]
		[string[]]$MailboxProperty,
		[Parameter(Mandatory=$true,Position=2)]
		[string[]]$MailboxDatabaseProperty,
		[Parameter(Mandatory=$false,Position=3)]
		[string]$MailboxFilter
	)
	Process
	{
		#Define two variables for storing the information.
		$results = @()
		$mbxDBStatistics = @{}
		#Define a ProgressRecord
		$activityName = $Messages.ActivityName
		# $progressRecord = New-Object System.Management.Automation.ProgressRecord(1,$activityName,"Processing")
		#Try to get mailbox servers
		if (-not ([System.String]::IsNullOrEmpty($MailboxFilter))) {
			$mailboxes = Get-Mailbox -Filter $MailboxFilter -ResultSize unlimited -Verbose:$false
		} else {
			$mailboxes = Get-Mailbox -ResultSize unlimited -Verbose:$false
		}
		if ($mailboxes -ne $null) {
			foreach ($mailbox in $mailboxes) {
				$counter++
				if ($mailboxes -is [array]) {
					$progressPercent = [int]($counter / ($mailboxes.Count) * 100)
				}
				#Define a variable for storing the information.
				$result = New-Object PSObject
				#Display progress
				$verboseMsg = $Messages.ProcessingMailbox
				$verboseMsg = $verboseMsg -replace "Placeholder01", $($mailbox.Alias)
				$pscmdlet.WriteVerbose($verboseMsg)
				# $progressRecord.CurrentOperation = $verboseMsg
				# $progressRecord.PercentComplete = $progressPercent
				# $pscmdlet.WriteProgress($progressRecord)
				#Begin to process
				$mbxServerName = $mailbox.ServerName
				$mbxDBName = $mailbox.Database
				$result | Add-Member -MemberType NoteProperty -Name "ServerName" -Value $mbxServerName
				$result | Add-Member -MemberType NoteProperty -Name "Database" -Value $mbxDBName
				if (-not ($mbxDBStatistics.ContainsKey($mbxDBName))) {
					$mbxDB = Get-MailboxDatabase -Identity $mbxDBName -Status -Verbose:$false
					$mbxDBStatistics.Add($mbxDBName,$mbxDB)
				}
				foreach ($mbxDBProperty in $MailboxDatabaseProperty) {
					$mbxDBPropertyValue = $mbxDBStatistics[$mbxDBName].$mbxDBProperty
					$result | Add-Member -MemberType NoteProperty -Name "$mbxDBProperty" -Value $mbxDBPropertyValue
				}
				foreach ($mbxProperty in $MailboxProperty) {
					$result | Add-Member -MemberType NoteProperty -Name "$mbxProperty" -Value $($mailbox.$mbxProperty)
				}
				$results += $result
			}
		} else {
			#Cannot find mailboxes with specified filter
			$errorMsg = $Messages.CannotFindMBXWithSpecifiedFilter
			$errorMsg = $errorMsg -replace "Placeholder01",$MailboxFilter
			$customError = New-OSCPSCustomErrorRecord `
			-ExceptionString $errorMsg `
			-ErrorCategory NotSpecified -ErrorID 1 -TargetObject $pscmdlet
			$pscmdlet.WriteError($customError)
			return $null		
		}
		#Return the results
		return $results
	}
}

clear

cls	
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"  

$DBStats = Get-OSCEXMailboxDatabaseStatistics -MailboxProperty "Name","Alias" -MailboxDatabaseProperty "LastFullBackup","DatabaseSize"

$SQLServer = "vs064.nedcar.nl"
$conn = New-SQLconnection $SQLServer "secdump"
if ($conn.state -eq "Closed") {
	$conn
	Error-Log "Failed to establish a connection to $SQLServer"
	EXIT
} else {
	Echo-Log "SQL Connection to $SQLServer succesfully established."
}

# Remove all previous records from this system
$query = "delete from exch_dbstatistics"
$data = Query-SQL $query $conn
# if ($data.gettype() -eq [int]) {Error-Log  "Failed to query SQL server.";EXIT}

$SQ = [char]39
$Systemname = $SQ + $env:COMPUTERNAME + $SQ
$Domainname = $SQ + $env:USERDNSDOMAIN + $SQ

foreach($dbstat in $DBStats) {
	$Servername = $dbstat.ServerName
	$Dbname = $dbstat.Database
	$LastBackup = $dbstat.LastFullBackup
	$DBSizeStr = [string]$dbstat.DatabaseSize
	$temp = $DBSizeStr.split("(")
	if($temp.Count -eq 2) {
		$Size = $temp[1]
		$Size = $Size.replace(",","")
		$Size = $Size.replace(")","")
		$Size = $Size.replace("bytes","")
		$DBSize = [int64]$Size
	} else {
		$DBSize = -1		
	}
	
	$MailBoxName = $dbstat.Name
	
	Echo-Log "$MailBoxName [$Dbname] [$LastBackup] [$DBSize] [$MailBoxName]"
	
	$query = "insert into exch_dbstatistics " +
		"(systemname, domainname, poldatetime, " +
		"servername, [database], lastfullbackup, databasesize, mailboxname) " +
		" VALUES ( $systemname, $domainname, GetDate()," +
		$SQ + $Servername + $SQ + "," +
        $SQ + $Dbname + $SQ + "," +
	    $SQ + $LastBackup + $SQ + "," +
    	$DBSize + "," +
		$SQ + $MailBoxName + $SQ + ")"					
		$data = Query-SQL $query $conn		
}

Remove-SQLconnection $conn

Echo-Log "Ended script $ScriptName"