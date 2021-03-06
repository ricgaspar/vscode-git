# ---------------------------------------------------------
#
# Create NTFS permissions overview in HTML format
# Marcel Jussen
# 6-1-2011
# ---------------------------------------------------------

param (
	[string]$Computername = $Env:COMPUTERNAME
)

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

# ---------------------------------------------------------
cls

Function Create_HTML_Report {
	param (
		$table,
		[string]$share,
		[string]$share_name,
		[string]$path,
		[string]$csspath = 'C:\Scripts\FolderSecReporting'
	)	
		
	$domain = Get-NetbiosDomain
	if($domain -ne $null) { $domain = $domain.trim() + "\"	} else { $domain = "NEDCAR\" }	
	$dnsdomain = Get-DnsDomain
	if($dnsdomain -ne $null) { $dnsdomain = $dnsdomain.trim() + "\"	} else { $dnsdomain = "nedcar.nl" }	
	
	Echo-Log "Creating HTML report for share $share_name"
	
	$html_Path = $path + "folder-security.htm"
	
	if($table -ne $null) { 
		$reccount = $table.Count
		if($reccount -le 0) {		
			Echo-Log "There are no records to display. No HTML is created."
			# Remove existing file because there is no content to display
			if(Test-Path($html_Path)) {
				Echo-Log "Removing existing HTML file because there is no content to display."
				Remove-Item -Path $html_Path -Force -ErrorAction SilentlyContinue
			}
			return 0
		}		
	} else {
		Echo-Log "There are no records to display. No HTML is created."
		# Remove existing file because there is no content to display
		if(Test-Path($html_Path)) {
			Echo-Log "Removing existing HTML file because there is no content to display."
			Remove-Item -Path $html_Path -Force -ErrorAction SilentlyContinue
		}
		return 0
	}
	
# HEAD
$html = @'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<html>
<head>
<title>NAS Folder Security</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="pragma" content="no-cache">
'@
	(Get-Content ($csspath + '\css_Styles.html')) | Foreach-object { $html += "$_" }
$html += @'
</head>
<body>
	<div id="wrap">	
	<div id="top" class="show">	
		<p>Skip to: <a href="#footer">bottom</a></p>
	</div>
	<div id="headline" class="show">
	<p>VDL Nedcar - Folder Security Sheet</p>
  	<p>
'@ 
$html += "\\$dnsdomain\office\$share_name"

$html += @'
		</p>
</div>
<div id="content">
  <table id="box-table-b" summary="Warning-NL">
  <thead>
  <tr><th>LET OP:</th></tr>
  </thead>
  <tbody>
  <tr><td>U wordt verzocht rekening te houden met bovenstaande server en sharenaam indien u deze share als driveletter mapt in Citrix of uw eigen werkplek. Indien U de mapping met de verkeerde informatie maakt kan uw data in bepaalde situaties niet beschikbaar zijn.</td></tr>
  </tbody>
  </table>
</div>

<div id="content">
  <table id="box-table-b" summary="Warning-EN">
  <thead>
  <tr><th>ATTENTION:</th></tr>
  </thead>
  <tbody>
  <td>Please make sure you use the correct server and sharename as described herein while mapping a drive in Citrix or your own workstation. If the incorrect information is used your data may be unavailable during certain situations.</td></tr>
  </tbody>
  </table>
</div>
<div id="content">
  <table id="box-table-a" summary="ACL List">
  <thead>
  <tr>
  <th scope="col">Folder</th>
  <th scope="col">Trustee</th>
  <th scope="col">Permission</th>
  </tr>
</thead>
<tbody>
'@ 

	$FolderTemp = $null
	foreach($record in $table) { 
	
				$foldername = $record.SubFolderPath.trim()
				$foldername = $foldername.Replace($path, "")						
				$Trustee = $record.SecurityPrincipal.trim()
				$URLTrustee = $Trustee.Replace($domain, "")
				$PermType = $record.AccessControlType.trim()
				$Permission	= $record.FileSystemRights.trim()
				$FSOObject = $record.AccessControlFlags.trim()
	
				$html += '<TR>'
				if($FolderTemp -ne $Foldername) {
					$FolderTemp = $foldername
					$html += "<TD>$foldername</TD>"
				} else {
					$html += '<TD>&nbsp;</TD>'
				}
				
  				$html += "<TD><a href=""http://vs050.nedcar.nl/groupmembers.asp?group=$URLTrustee"">$Trustee</a></TD>"	  			
  				$html += "<TD>$Permission</TD>"  		
  				$html += '</TR>'
	} 	

$html += @'
</tbody>
</table>
</div>
<hr class="clear" />

<div id="content">
<p>This file was automatically created at 
'@

$html += Get-Date
$html += @'
	<p><p>This file is generated once a day. Changes applied during office hours are visible the next day.</p>
</div>
<hr class="clear" />

<div id="footer">
  <div class="left">
  <p>VDL Nedcar - Information Management</p>
  </div>
  <div class="right textright">
  <p class="show"><a href="#top">Return to top</a></p>
  </div>
</div>

</div>
</body>
</html>

'@				
	Echo-Log "Writing $reccount records in $html_Path"
	Set-Content -Path $html_Path -Value $html -ErrorAction SilentlyContinue
	
}

$ScriptName = $myInvocation.MyCommand.Name
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName" 
Echo-Log "Computername = $computername"

$SQLServer = "vs064.nedcar.nl"
$SQLconn = New-SQLconnection $SQLServer "secdump"
if ($SQLconn.state -eq "Closed") {
	$SQLconn
	Error-Log "Failed to establish a connection to $SQLServer"
	EXIT
} else {
	Echo-Log "SQL Connection to $SQLServer succesfully established."
}

$SQLQuery = "select Sharename from FileShares_Reporting where Computername = '$Computername'"	
$SQLShares = Query-SQL -query $SQLQuery -conn $SQLconn		
foreach ($Share in $SQLShares) {
	$Sharename = $share.sharename
	
	$UNCPath = "\\$Computername\$sharename"
	$UNCPath = $UNCPath.Trim()
	if(!$UNCpath.EndsWith("\")) { $UNCpath += "\" } 
	
	$SQLQuery = "exec [dbo].[FileSharesACL_Report] '$Computername', '$Sharename'"	
	$SQLresult = Query-SQL -query $SQLQuery -conn $SQLconn		
	$share = "$computer\$sharename"	
	
	# Test
	# $UNCpath = 'C:\Temp\'
	Create_HTML_Report -table $SQLResult -share $share -share_name $sharename -path $UNCpath -csspath $scriptPath
}

Echo-Log "Ended script $ScriptName"  

Remove-SQLconnection $SQLconn