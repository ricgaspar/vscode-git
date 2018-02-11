
cls

$SCRIPTLOG = $env:SystemDrive + "\Windows\Pathclog\Remove-Unauth-LocalAdmins.log"

Function Append-Log {
	param (
		[string]$Message
	)	
	$logTime = Get-Date –f "yyyy-MM-dd HH:mm:ss"
	$logentry = $logTime + " : " + $message
	Write-host $logentry
	Add-Content $SCRIPTLOG $logentry -ErrorAction SilentlyContinue
}

Function Remove_FromLocalGroup {
	param (
		$group,
		$member
	)
	
	try {
		Append-Log "Removing $member from local administrators"
		$group.Remove("WinNT://" + $Mbr) 
	}
	catch {
		Append-Log "Removal of member $member failed"
	}
}

$ScriptName = $myInvocation.MyCommand.Name
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# $strComputer = $env:COMPUTERNAME
$strDomain = $env:USERDOMAIN
$strComputer = 'VDLNC01724T'

# Read exception list located in script directory
$ExceptionList = Get-Content ($scriptPath + '\Remove_Unauth_LocalAdmins_exceptionlist.txt')

Append-Log "Listing local administrators on computer $strComputer"
$computer = [ADSI]("WinNT://" + $strComputer + ",computer") 
$group = $computer.psbase.children.find("Administrators") 
$members = $group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name",'GetProperty',$null,$_,$null)}

foreach($mbr in $members) {
	if($ExceptionList -match $Mbr) {
		Append-Log "Skipping [$mbr]"
	} else {
		$member = $strDomain + '\' + $Mbr
		Append-Log "Removing [$mbr]"
		# Remove_FromLocalGroup -group $group -member $member	
	}	
}

Append-Log "Done."