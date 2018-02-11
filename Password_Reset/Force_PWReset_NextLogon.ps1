. C:\Scripts\Secdump\PS\libAD.ps1

cls

$EndDate="9:00"
$users = Get-Content D:\Scripts_Source\Powershell\Password_Reset\users.txt
foreach($usr in $users) {
	
	$uad = Get-ADUser -identity $usr -properties *
	$PasswordSet = [datetime]$uad.PassWordLastSet	
	$Displayname = $uad.DisplayName 	
	
	$dd = NEW-TIMESPAN –Start $PasswordSet –End $EndDate	
	if(($dd.Days -gt 0) -and ($dd.Hours -ge 0)) {
		if($usr -ne 'MJ90624') {
			write-host "$Usr; $Displayname; $PasswordSet"		
			$DN = Search-AD-User $usr
			$account = [adsi]($DN)
			$PLSValue = 0 
    		$account.psbase.invokeSet("pwdLastSet",$PLSValue) 
			$account.psbase.CommitChanges()
		}
	}
}