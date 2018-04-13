# ---------------------------------------------------------
#
# Create NTFS permissions overview in HTML format
# Marcel Jussen
# 25-1-2011
# ---------------------------------------------------------

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

# ---------------------------------------------------------
cls
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName" 

$global:FolderSecFile = "folder-security.htm"

Function HTML-Header {
	param (
		[string] $outfile = $FolderSecFile,
		[string] $sharename
	)
	
	Echo-Log "Writing header to $outfile"
	if (Test-Path($outfile)) { Remove-Item $outfile -Force -ErrorAction SilentlyContinue }
	Copy-Item "C:\Scripts\Secdump\PS\_template.htm" $outfile
	"  <p>" + $sharename +  "</p>" | Out-File $outfile -Encoding ASCII -Append
	"</div>"| Out-File $outfile -Encoding ASCII -Append
	
	
	"<div id=""content"">" | Out-File $outfile -Encoding ASCII -Append
  	"  <table id=""box-table-a"" summary=""ACL List"">" | Out-File $outfile -Encoding ASCII -Append
	"  <thead>" | Out-File $outfile -Encoding ASCII -Append
	"  <tr>" | Out-File $outfile -Encoding ASCII -Append
	"  <th>Folder</th>" | Out-File $outfile -Encoding ASCII -Append
	"  <th>Trustee</th>" | Out-File $outfile -Encoding ASCII -Append
	"  <th>Type</th>" | Out-File $outfile -Encoding ASCII -Append
	"  <th>Permission</th>" | Out-File $outfile -Encoding ASCII -Append
	"  <th>Object</th>" | Out-File $outfile -Encoding ASCII -Append
	"  </tr>" | Out-File $outfile -Encoding ASCII -Append
	"</thead>" | Out-File $outfile -Encoding ASCII -Append
	"<tbody>" | Out-File $outfile -Encoding ASCII -Append
}

Function HTML-Footer {
	param (
		[string] $outfile = $FolderSecFile
	)
	$date = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	Echo-Log "Writing footer to $outfile"
	
	"  </tbody>" | Out-File $outfile -Encoding ASCII -Append
	"</table>" | Out-File $outfile -Encoding ASCII -Append
	"<p><br>This file was automatically created at " + $date + ".<br>This file is generated once a day. Changes applied during office hours are visible the next day.<p>" | Out-File $outfile -Encoding ASCII -Append
		
   	"</div>" | Out-File $outfile -Encoding ASCII -Append		
	"<div id=""footer"">" | Out-File $outfile -Encoding ASCII -Append
	"  <div class=""left"">" | Out-File $outfile -Encoding ASCII -Append
	"    <p>Copyright Netherlands Car b.v.</p>" | Out-File $outfile -Encoding ASCII -Append
	"  </div>" | Out-File $outfile -Encoding ASCII -Append
	"  <div class=""right textright"">" | Out-File $outfile -Encoding ASCII -Append
	"    <p class=""show""><a href=""#top"">Return to top</a></p>" | Out-File $outfile -Encoding ASCII -Append
	"  </div>" | Out-File $outfile -Encoding ASCII -Append	
	"</div>" | Out-File $outfile -Encoding ASCII -Append
	"</body>" | Out-File $outfile -Encoding ASCII -Append
	"</html>" | Out-File $outfile -Encoding ASCII -Append
}

Function HTML-Record {
	param (
		[string] $outfile = $FolderSecFile,
		[string] $foldername,
		[string] $groupname, 
		[string] $rights, 
		[string] $type, 
		[string] $object
	)
	
	$pos = $groupname.Indexof("\")
	if ($pos -ne 0) {
		$domainname = $groupname.Substring(0, $pos)
		$groupname = $groupname.Substring($pos+1)
	}
	
	$GroupRef= "<a href=""http://vs050/groupmembers.asp?group=$groupname&domain=$DomainName"">$groupname</a>"
	
	"<tr>" | Out-File $outfile -Encoding ASCII -Append
  	"  <td>" + $foldername + "</td>" | Out-File $outfile -Encoding ASCII -Append
  	"  <td>" + $GroupRef + "</td>" | Out-File $outfile -Encoding ASCII -Append
  	"  <td>" + $type + "</td>" | Out-File $outfile -Encoding ASCII -Append
  	"  <td>" + $rights  + "</td>" | Out-File $outfile -Encoding ASCII -Append
  	"  <td>" + $object + "</td>" | Out-File $outfile -Encoding ASCII -Append
  	"</tr>" | Out-File $outfile -Encoding ASCII -Append
}

$SQLconn = New-SQLconnection "s001.nedcar.nl" "secdump"
if ($SQLconn.state -eq "Closed") {
	$SQLconn
	Error-Log "Failed to establish a connection to $SQLServer"
	EXIT
} else {
	Echo-Log "SQL Connection to $SQLServer succesfully established."	
	$computer = $env:COMPUTERNAME
	$SQLQuery = "exec QRY_NTFS_Report '$computer'"
	$SQLresult = Query-SQL $SQLQuery $SQLconn 
	
	$tempshare = $null
	if ($SQLresult -ne $null) {		
		foreach ( $res in $SQLresult) {
			$sharename = $res.sharename.Trim()	
			$path = $res.path.Trim()									
			$foldername = $res.foldername.Trim()
			$groupname = $res.groupname.Trim()
			$rights = $res.rights.Trim()
			$type = "Allowed"
			$object = "This Folder, Subfolders and Files"
						
			Echo-Log "$sharename $path $output"
			if ($tempshare -ne $sharename) {
				if ($tempshare.Length -ne $null) { 
					HTML-Footer $output
				} 
			
				$output = "$path\" + $FolderSecFile
				HTML-Header $output $sharename				
				$tempshare = $sharename
			}
			$output = "$path\" + $FolderSecFile
			
			HTML-Record $output $foldername $groupname $rights $type $object
		}
		HTML-Footer $output 
	}
}

Echo-Log "Ended script $ScriptName"  

Remove-SQLconnection $SQLconn