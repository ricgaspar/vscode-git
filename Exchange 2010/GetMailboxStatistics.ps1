# ---------------------------------------------------------
# MS Exchange Mailbox to Database distribution
# Marcel Jussen
# 6-11-2012
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ------------------------------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libGen.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

Function Get_Exch_MailBoxStats {
	$query = "delete from exch_mailboxstatistics"
	$data = Query-SQL $query $conn

	$MailboxStats = Get-MailboxStatistics –Server "vs091.nedcar.nl" -Verbose:$false 
	foreach($Mailbox in $MailboxStats) {
		$Servername = $Mailbox.ServerName
		$objectClass = $Mailbox.objectClass
		$DatabaseName = $Mailbox.DatabaseName
		$LastLoggedOnUserAccount = $Mailbox.LastLoggedOnUserAccount
		$LastLogonTime = $Mailbox.LastLogonTime
		$DisplayName = $Mailbox.DisplayName
		$ItemCount = [int64]$Mailbox.ItemCount
		$TotalItemSizeStr = [string]$Mailbox.TotalItemSize
		$StorageLimitStatus = [string]$Mailbox.StorageLimitStatus
	
		$temp = $TotalItemSizeStr.split("(")
		if($temp.Count -eq 2) {
			$Size = $temp[1]
			$Size = $Size.replace(",","")
			$Size = $Size.replace(")","")
			$Size = $Size.replace("bytes","")
			$TotalItemSize = [int64]$Size
		} else {
			$TotalItemSize = -1		
		}				
		
		$query = "insert into exch_mailboxstatistics " +
		"(systemname, domainname, poldatetime, " +
		"servername, databasename, lastloggedonuseraccount, lastlogontime, displayname, itemcount, totalitemsize, storagelimitstatus) " +
		" VALUES ( $systemname, $domainname, GetDate()," +
		$SQ + $Servername + $SQ + "," +
        $SQ + $DatabaseName + $SQ + "," +
	    $SQ + $LastLoggedOnUserAccount + $SQ + "," +
		$SQ + $LastLogonTime + $SQ + "," +
		$SQ + $DisplayName + $SQ + "," +
    	$ItemCount + "," +
		$TotalItemSize + "," +
		$SQ +$StorageLimitStatus + $SQ + ")"
		$data = Query-SQL $query $conn	
	}
}

Function Get_Exch_Mailbox_Sec {

	$query = "delete from exch_mailbox_acl"
	$data = Query-SQL $query $conn
	
	$Mailboxes = Get-Mailbox -ResultSize unlimited -Verbose:$false
	foreach($Mailbox in $Mailboxes) {		
		$DisplayName = $Mailbox.Displayname
		Echo-Log $DisplayName
		$SAMAccountName = $Mailbox.SamAccountName
		$acllist = Get-MailboxPermission -Identity $DisplayName
		foreach($acl in $acllist) {
			$Deny = [string]$acl.Deny
			$InheritanceType = [string]$acl.InheritanceType
			$User = [string]$acl.User
			$IdentityName = [string]$acl.Identity.Name
			$IdentityDistinguishedName = [string]$acl.Identity.DistinguishedName
			$IsInherited = [string]$acl.IsInherited
			$IsValid = [string]$acl.IsValid
						
			$query = "insert into exch_mailbox_acl " +
			"(systemname, domainname, poldatetime, " +
			"SAMAccountName, DisplayName, [Deny], InheritanceType, [User], IdentityName, IdentityDistinguishedName, IsInherited, IsValid) " +
			" VALUES ( $systemname, $domainname, GetDate()," +
			$SQ + $SAMAccountName + $SQ + "," +
			$SQ + $DisplayName + $SQ + "," +
			$SQ + $Deny + $SQ + "," +
        	$SQ + $InheritanceType + $SQ + "," +
	    	$SQ + $User + $SQ + "," +
			$SQ + $IdentityName + $SQ + "," +
			$SQ + $IdentityDistinguishedName + $SQ + "," +
    		$SQ + $IsInherited + $SQ + "," +			
			$SQ + $IsValid + $SQ + ")"
			$data = Query-SQL $query $conn	
		}
	}
}

Function Get_Exch_Mailbox_Addresses {
	$query = "delete from exch_mailbox_adresses"
	$data = Query-SQL $query $conn

	$Mailboxes = Get-Mailbox -ResultSize unlimited -Verbose:$false
	foreach($Mailbox in $Mailboxes) {
		$DisplayName = $Mailbox.Displayname
		Echo-Log $DisplayName
		$SAMAccountName = $Mailbox.SamAccountName
	
		$MBox = Get-Mailbox -Identity $DisplayName -ErrorAction SilentlyContinue
		$PrimarySMTPAddress = $MBox.PrimarySMTPAddress		
		$Addresses = $MBox.EmailAddresses
				
		foreach($address in $Addresses) {
			$SmtpAddress = $address.SmtpAddress
			$IsPrimaryAddress = $address.IsPrimaryAddress
			$ProxyAddressString = $address.ProxyAddressString
						
			$query = "insert into exch_mailbox_adresses " +
			"(systemname, domainname, poldatetime, " +
			"SAMAccountName, DisplayName, PrimarySMTPAddress, SmtpAddress, IsPrimaryAddress, ProxyAddressString) " +
			" VALUES ( $systemname, $domainname, GetDate()," +
			$SQ + $SAMAccountName + $SQ + "," +
			$SQ + $DisplayName + $SQ + "," +
			$SQ + $PrimarySMTPAddress + $SQ + "," +
        	$SQ + $SmtpAddress + $SQ + "," +
	    	$SQ + $IsPrimaryAddress + $SQ + "," +
			$SQ + $ProxyAddressString + $SQ + ")"
			$data = Query-SQL $query $conn	
		}
	}
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName $ScriptName
Echo-Log ("="*60)
Echo-Log "Started script $ScriptName"

$SQ = [char]39
$Systemname = $SQ + $env:COMPUTERNAME + $SQ
$Domainname = $SQ + $env:USERDNSDOMAIN + $SQ

$SQLServer = $Global:SECDUMP_SQLServer
$conn = New-SQLconnection $SQLServer "secdump"
if ($conn.state -eq "Closed") {
	$conn
	Error-Log "Failed to establish a connection to $SQLServer"
	EXIT
} else {
	Echo-Log "SQL Connection to $SQLServer succesfully established."
}

Get_Exch_Mailbox_Sec 
Get_Exch_Mailbox_Addresses
Get_Exch_MailBoxStats

# ------------------------------------------------------------------------------
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)