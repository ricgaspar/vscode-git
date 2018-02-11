#
# Marcel Jussen
#

$username = "q055817"
$jpgfile = "C:\Scripts\Powershell\me.jpg"

$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$root = $dom.GetDirectoryEntry()
$search = [System.DirectoryServices.DirectorySearcher]$root
$search.Filter = "(&(objectclass=user)(objectcategory=person)(samAccountName=$username))"
$result = $search.FindOne()
if ($result -ne $null)
{
	$user = $result.GetDirectoryEntry()
 	[byte[]]$jpg = Get-Content $jpgfile -encoding byte
 
  	# Clear AVATAR
 	$user.Properties["thumbnailPhoto"].Clear()
 	$user.setinfo() 	
}
else {
	Write-Host $struser " does not exist"
}

