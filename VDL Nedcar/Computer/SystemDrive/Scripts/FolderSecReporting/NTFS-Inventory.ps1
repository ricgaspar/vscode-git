# ---------------------------------------------------------
#
# Collect NTFS information of root folders and their 
# subfolders from public file shares.
#
# Marcel Jussen
# 19-11-2014
# ---------------------------------------------------------

param ( 
	[string]$ComputerName = $Env:COMPUTERNAME
)

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

# ---------------------------------------------------------

Function Get-Public-FileShares {
	Param (
		[Parameter(Mandatory=$false)]
		[Alias('Computer')][String[]]$ComputerName=$Env:COMPUTERNAME,
	
		[Parameter(Mandatory=$false)]
		[Alias('Cred')][System.Management.Automation.PsCredential]$Credential
	)
	
	#test server connectivity
	$PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
	if($PingResult) {
		#check the credential whether trigger
		if($Credential) {
			$SharedFolders = Get-WmiObject -Class Win32_Share `
				-ComputerName $ComputerName -Credential $Credential -ErrorAction SilentlyContinue | Where-Object {$_.Type -eq 0} | sort path 
		} else {
			$SharedFolders = Get-WmiObject -Class Win32_Share `
				-ComputerName $ComputerName -ErrorAction SilentlyContinue | Where-Object {$_.Type -eq 0} | sort path 
		}	
		return $SharedFolders
	}
}

Function Get-Folder-ACL {
	Param (
		[Parameter(Mandatory=$false)]
		[Alias('Computer')][String[]]$ComputerName=$Env:COMPUTERNAME,
		
		[Parameter(Mandatory=$true)]
		[Alias('Path')][String[]]$SharedFolderPath,				
	
		[Parameter(Mandatory=$false)]
		[Alias('Cred')][System.Management.Automation.PsCredential]$Credential
	)
	
	#test server connectivity
	$PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
	if($PingResult) {
		$Objs = @()
			
		# WMI path cannot contain \ but only \\
		$WMISharedFolderPath = $SharedFolderPath.Replace('\','\\')
		
		# WMI path cannot contain quote character, it must be escaped
		$WMISharedFolderPath = $WMISharedFolderPath.Replace([string]([char]39), [string]"\'")
		if($Credential)
		{	
			$SharedNTFSSecs = Get-WmiObject -Class Win32_LogicalFileSecuritySetting `
			-Filter "Path='$WMISharedFolderPath'" -ComputerName $ComputerName  -Credential $Credential
		}
		else
		{
			$SharedNTFSSecs = Get-WmiObject -Class Win32_LogicalFileSecuritySetting `
			-Filter "Path='$WMISharedFolderPath'" -ComputerName $ComputerName
		}
	
		$SecDescriptor = $SharedNTFSSecs.GetSecurityDescriptor()
		foreach($DACL in $SecDescriptor.Descriptor.DACL)
		{  
			$DACLDomain = $DACL.Trustee.Domain
			$DACLName = $DACL.Trustee.Name
			if($DACLDomain -ne $null)
			{
	          	$UserName = "$DACLDomain\$DACLName"
			}
			else
			{
				$UserName = "$DACLName"
			}
			
			$DACL.AccessMask
			
			#customize the property
			$Properties = @{'ComputerName' = [string]$ComputerName				
				'ACLPath' = [string]$SharedFolderPath
				'SecurityPrincipal' = $UserName
 				'FileSystemRights' = [Security.AccessControl.FileSystemRights]$($DACL.AccessMask -as [Security.AccessControl.FileSystemRights])		
				'AccessControlType' = [Security.AccessControl.AceType]$DACL.AceType
				'AccessControlFlags' = [Security.AccessControl.AceFlags]$DACL.AceFlags }
								
			$SharedNTFSACL = New-Object -TypeName PSObject -Property $Properties
	        $Objs += $SharedNTFSACL
		}
		$Objs |Select-Object ComputerName,ACLPath,SecurityPrincipal,FileSystemRights, `
			AccessControlType,AccessControlFlags -Unique
	} 
	
	return $Objs
}

Function Get-Share-FolderList {
	Param (
		[Parameter(Mandatory=$false)]
		[Alias('Computer')][String[]]$ComputerName=$Env:COMPUTERNAME,
		
		[Parameter(Mandatory=$true)]
		[Alias('Path')][String[]]$FolderPath,
	
		[Parameter(Mandatory=$false)]
		[Alias('Cred')][System.Management.Automation.PsCredential]$Credential
	)	
	
	#test server connectivity
	$PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
	if($PingResult) {
		$Objs = @()
		$UNCFolderPath = '\\' + $ComputerName + '\' + $FolderPath.Replace(':','$')
		$RootFolders = Get-ChildItem -path $UNCFolderPath -Force -errorAction SilentlyContinue | where {$_.psIsContainer -eq $true} 
		
		Foreach($Folder in $RootFolders) {
			$RootFolderPath = [string]$FolderPath
			$RootFolderName = $Folder.Name.Trim()
			$Properties = @{'ComputerName' = [string]$ComputerName				
				'RootFolderPath' = $RootFolderPath.Trim()
				'Path' = [string]$Folder.Name
				'UNCPath' = [string]($UNCFolderPath + '\' + $RootFolderName)
				'ACLPath' = [string]($RootFolderPath + '\' + $RootFolderName)
				}
								
			$SharedNTFSACL = New-Object -TypeName PSObject -Property $Properties
	        $Objs += $SharedNTFSACL
			
			$UNCSubFolderPath = '\\' + $ComputerName + '\' + $FolderPath.Replace(':','$') + '\' + $Folder.name
			$RootSubFolders = Get-ChildItem -path $UNCSubFolderPath -Force -errorAction SilentlyContinue | where {$_.psIsContainer -eq $true} 
			
			Foreach($Subfolder in $RootSubFolders) { 
				$SubFolderPath = [string]$RootFolderName + '\' + [string]$Subfolder.Name
				$ACLPath = $RootFolderPath + '\' + $SubFolderPath
				$Properties = @{
					'ComputerName' = [string]$ComputerName				
					'RootFolderPath' = [string]$FolderPath
					'Path' = [string]$SubFolderPath
					'UNCPath' = [string]($UNCFolderPath + '\' + $SubFolderPath)
					'ACLPath' = [string]($ACLPath)
				}
								
				$SharedNTFSACL = New-Object -TypeName PSObject -Property $Properties
	        	$Objs += $SharedNTFSACL
			}
		}
	}
	
	return $Objs
}

#
# T-SQL
# If string contains quote, add additional quote.
#
Function Re-Quote {
	param ( [string]$Str )	
	$Str.Replace([string]([char]39), [string]([char]39+[char]39))
}

cls

$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName" 

$SQLServer = "vs064.nedcar.nl"
$SQLconn = New-SQLconnection $SQLServer "secdump"
if ($SQLconn.state -eq "Closed") {
	$SQLconn
	Error-Log "Failed to establish a connection to $SQLServer"
	EXIT
} else {
	Echo-Log "SQL Connection to $SQLServer succesfully established."
}

# Delete all previous records from SECDUMP
$query = "delete from FileShares_Reporting where computername='$computername'"
$data = Query-SQL $query $SQLconn

$query = "delete from FileSharesFolders_Reporting where computername='$computername'"
$data = Query-SQL $query $SQLconn

$query = "delete from FileSharesFoldersACL_Reporting where computername='$computername'"
$data = Query-SQL $query $SQLconn

#test server connectivity
$PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
if($PingResult) {

	# Collect all public file shares from computer
	Echo-Log "Collecting shares from computer $Computername"
	$ShareCollection = Get-Public-FileShares -Computer $computername
	foreach($Share in $ShareCollection) {		
		$SharePath = $Share.Path		
		$ShareName = $Share.Name
		$ShareDescription = $share.Description
		Echo-Log "Collecting information from file share: $ShareName"
		# Store share information in SQL table
		$query = "insert into FileShares_Reporting " +       		
       		"(Systemname, Computername, Sharename, Poldatetime, Path, Description) " +
         	" VALUES ( " + 
			"'" + $Env:COMPUTERNAME + "'," + 
			"'" + $computername + "'," +
			"'" + (Re-Quote $ShareName) + "', GetDate(), " +           	
			"'" + (Re-Quote $SharePath) + "'," +           	
			"'" + (Re-Quote $ShareDescription) + "')"					
		$data = Query-SQL $query $SQLconn		
		
		# Collect root folders and 1st subfolders collection from share path
		Echo-Log "Collection folder list from folder: $SharePath"
		$FoldersCollection = Get-Share-FolderList -ComputerName $ComputerName -Path $Share.Path		
		foreach($Folder in $FoldersCollection) {			
			$SharePath = $Folder.Path
			$ACLPath = $Folder.ACLPath
			$UNCPath = $Folder.UNCPath
			
			# Store folder information in SQL table
			$query = "insert into FileSharesFolders_Reporting " +       		
       			"(Systemname, Computername, Sharename, Poldatetime, Path, ACLPath, UNCPath) " +
         		" VALUES ( " + 
				"'" + $Env:COMPUTERNAME + "'," + 
				"'" + $computername + "'," +
				"'" + (Re-Quote $ShareName) + "', GetDate(), " +
				"'" + (Re-Quote $SharePath) + "'," +
				"'" + (Re-Quote $ACLPath) + "'," +
				"'" + (Re-Quote $UNCPath) + "')"					
			$data = Query-SQL $query $SQLconn
		
			# Retrieve NTFS ACL information from path
			$RootFolderPath = $Folder.ACLPath
			Echo-Log "Collecting ACL information from folder: $RootFolderPath"
 			$acllist = Get-Folder-ACL -ComputerName $ComputerName -Path $RootFolderPath
			if($acllist) {
				$count = $acllist.Count
				Echo-Log "Recording $count ACL records."
			}
			foreach($acl in $acllist) {
				$ACLPath = $acl.ACLPath
				$SecurityPrincipal = $acl.SecurityPrincipal
				$FileSystemRights = $acl.FileSystemRights
				$AccessControlType = $acl.AccessControlType
				$AccessControlFlags = $acl.AccessControlFlags
			
				# Store ACL information in SQL table
				$query = "insert into FileSharesFoldersACL_Reporting " +
       			"(Systemname, Computername, Sharename, Poldatetime, ACLPath, SecurityPrincipal, FileSystemRights, AccessControlType, AccessControlFlags) " +
         		" VALUES ( " + 
				"'" + $Env:COMPUTERNAME + "'," + 
				"'" + $computername + "'," +
				"'" + $ShareName + "', GetDate(), " +           	
				"'" + (Re-Quote $ACLPath) + "'," +
				"'" + $SecurityPrincipal + "'," +
				"'" + $FileSystemRights + "'," +
				"'" + $AccessControlType + "'," +
				"'" + $AccessControlflags + "')"					
				$data = Query-SQL $query $SQLconn				
			} 
		}
	}
}

Echo-Log "Ended script $ScriptName"  

Remove-SQLconnection $SQLconn