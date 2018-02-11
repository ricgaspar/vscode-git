# ---------------------------------------------------------
# Repair_Users_CtxProf
#
# Marcel Jussen
# 9-3-2015
# ---------------------------------------------------------

# Pre-defined variables
$Global:SECDUMP_SQLServer = "vs064.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"
$Global:SQLconn

# ---------------------------------------------------------
Import-Module VNB_PSLib
# ---------------------------------------------------------

$Global:Changes_Proposed = 0
$Global:Changes_Committed = 0

$Global:DEBUG = $False

Function Create-Folder($path) {
	$temp = Test-DirExists $path
	if($temp -ne $true) { 
		Echo-Log "$Username : REPAIR - Creating missing folder $path"
		[Void](md -Path $Path)
		$Global:Changes_Committed ++
	}
}

Function Create_User_CtxProf {
	param (
		$Username
	)
	
	# Convert to uppercase
	$Username = $Username.ToUpper()
	
	if($Global:DEBUG) {
		Echo-Log "** Debug: Creating home for $Username"
		return
	}	
	
	$Result = Get-ADUserDN $Username
	if ($Result -ne $null) {		
		$Userhomepath = ("\\vs035\tsprofile$\" + $Username)		
		if(Test-DirExists($Userhomepath)) {			
			return -1
		} else {
			Echo-Log "$Username : Creating Citrix profile $Userhomepath for user $Username"
			
			[Void]([System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"))			
			$OUTPUT= [System.Windows.Forms.MessageBox]::Show("We are proceeding with next step." , "Status" , 4)
			if ($OUTPUT -eq "YES" ) {
				[void](md -Path $Userhomepath)
				
				$DefCtxProfile = "\\VS035.nedcar.nl\TSProfileman$\*"
				Echo-Log "$Username : Copying default Citrix profile to $Userhomepath"
				Copy-Item $DefCtxProfile $Userhomepath -Recurse -Force -ErrorAction SilentlyContinue
			}								
		}
		
		if(Test-DirExists($Userhomepath)) {						
								
		} else {
			Echo-Log "ERROR: The Citrix profile $Userhomepath for user $Username was not successfully created."
		}				
	}	
}

Function Repair_User_CtxProf {
	param (
		$Username
	)
	
	# Convert to uppercase
	$Username = $Username.ToUpper()
	$Userhomepath = ("\\vs035\tsprofile$\" + $Username)
	$Result = Search-AD-User $Username
	if ($Result -ne $null) {								
		if(Test-DirExists($Userhomepath)) {								
			
		} else {
			Echo-Log "Username: The Citrix path $Userhomepath for user $Username does not exist."
			Create_User_CtxProf $Username
		}				
	} else {
			Echo-Log "ERROR: The user $Username was not found in AD."
			
			[Void]([System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms"))			
			$OUTPUT= [System.Windows.Forms.MessageBox]::Show("We are proceeding with next step." , "Status" , 4)
			if ($OUTPUT -eq "YES" ) {
				Remove-Item $Userhomepath -ErrorAction SilentlyContinue -Force -Recurse
			} else { 
 				
			} 							
	}
}

# ------------------------------------------------------------------------------
# Start script
cls
$ErrorVal=0
$ScriptName = $myInvocation.MyCommand.Name

$cdtime = Get-Date –f "yyyyMMdd-HHmmss"
$logfile = "Secdump-Repair_Users_Homes-$cdtime"
$GlobLog = Init-Log -LogFileName $logfile
Echo-Log ("="*60)
Echo-Log "Log file      : $GlobLog"
Echo-Log "Started script: $ScriptName"
Echo-Log ("-"*60)

if($Global:DEBUG) { Echo-Log "** DEBUG mode: changes are not committed." }

Echo-Log "Inventory users accounts in the domain."
$userCol = Get-ADUsersSAM

Echo-Log "Checking homes for user accounts."
foreach($User in $userCol) {
	$path = $User.Path
	if($path -ne $null) {
		$path = $path.ToUpper()
		if($path.Contains("OU=NEDCAR,DC=NEDCAR,DC=NL")) {			
			$obj = [ADSI]$path
			$SamAccountName = $obj.sAMAccountName.value
			Repair_User_CtxProf $SamAccountName
		}
	}
}

Echo-Log ("-"*60)
Echo-Log "Inventory folders on \\vs035\tsprofile$"
$folders = Get-ChildItem "\\vs035\tsprofile$" | where {$_.Attributes -eq 'Directory'}
Echo-Log "Checking user assignment and acl per folder."
foreach($Username in $folders) {
	Repair_User_CtxProf $Username.BaseName
}

Echo-Log ("-"*60)
Echo-Log "End script $ScriptName"
Echo-Log "Bye bye."
Echo-Log ("="*60)

if ($Global:Changes_Committed -ne 0) {
	$Title = "Repair User home directories. $cdtime ($Global:Changes_Committed changes committed)" 	
} else {
	$Title = "Repair User home directories. $cdtime (No changes committed)" 
}

if($Global:DEBUG) {
	Echo-Log "** Debug: Sending resulting log as a mail message."
} 

$SendTo = "nedcar-events@kpn.com"
$dnsdomain = Get-DnsDomain
$computername = gc env:computername
$SendFrom = "$computername@$dnsdomain"

# Send-HTMLEmailLogFile -FromAddress $SendFrom -SMTPServer "smtp.nedcar.nl" -ToAddress $SendTo -Subject $title -LogFile $GlobLog -Headline $Title
