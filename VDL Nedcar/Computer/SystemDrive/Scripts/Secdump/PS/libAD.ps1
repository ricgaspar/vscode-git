# ---------------------------------------------------------
#
# Active Directory Functions
# Marcel Jussen
# 13-4-2014
#
# ---------------------------------------------------------

Function Get-HostName 
# ---------------------------------------------------------
# Return the DNS host name of the current computer
# ---------------------------------------------------------	
{
	return ([system.net.dns]::GetHostByName("localhost")).hostname
}

Function Get-ADInfo
# ---------------------------------------------------------
# Return information of the domain this computer belongs to.
# ---------------------------------------------------------	
{
    $ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $ADDomainName = $ADDomain.Name
    $Netbios = $ADDomain.Name.Split(".")[0].ToUpper()
    $ADServer = $ADDomain.InfrastructureRoleOwner.Name
    $FQDN = "DC=" + $ADDomain.Name -Replace("\.",",DC=")
 
    $Results = New-Object Psobject
    $Results | Add-Member Noteproperty Domain $ADDomainName
    $Results | Add-Member Noteproperty FQDN $FQDN
    $Results | Add-Member Noteproperty Server $ADServer
    $Results | Add-Member Noteproperty Netbios $Netbios
    Write-Output $Results
}

function Get-DnsDomain {
# ---------------------------------------------------------
# Return the DNS name of the domain this computer belongs to.
# ---------------------------------------------------------		
	$ADInfo = Get-ADInfo
	return $ADInfo.Domain
}

Function Get-NetbiosDomain
# ---------------------------------------------------------
# Return the Netbios name of the domain this computer belongs to.
# Returns an array of names when successfull.
# ---------------------------------------------------------	
{
	$ADInfo = Get-ADInfo
	return $ADInfo.Netbios	
}

Function Get-DN {
# ---------------------------------------------------------
# Search current domain with a search filter
# Default search is for a computer with the name of $objectname 
# Returns the ADSPATH (DN) for the account or $null if not found
# ---------------------------------------------------------
	param (
		[string]$objectname = $Env:COMPUTERNAME,
		[string]$Filter = "(&(objectCategory=computer)(name=$objectname))"
	)				
	$colresults = Search-AD $Filter "path"
	if ($colResults -eq $null) { return $null }
	Foreach ($col in $colResults) { $result = $col.Path }
	return $result
}

function Search-AD { 
# ---------------------------------------------------------
# Search current domain with a search filter and propery list
# Returns an object with all found AD objects
# ---------------------------------------------------------
	Param ([string]$ADSearchFilter = "(&(objectCategory=Computer)(OperatingSystem=Windows*Server*))",
         [string]$colProplist = "name"
    )    
	$objDomain = New-Object System.DirectoryServices.DirectoryEntry
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objSearcher.SearchRoot = $objDomain
	$objSearcher.PageSize = 5000
	$objSearcher.Filter = $ADSearchFilter      
	foreach ($i in $colPropList) {
		$objSearcher.PropertiesToLoad.Add($i)
	}
	$colResults = $objSearcher.FindAll()	
	return $colResults
}

function Search-AD-User {
# ---------------------------------------------------------
# Search current domain for specific user account name
# ---------------------------------------------------------
	Param (
		[string]$Username = $null
    ) 
	if([string]::IsNullOrEmpty($Username)) { return $null }	
	$Result = Get-Dn $Username  "(&(objectCategory=User)(SamAccountName=$Username))"	
	return $Result
}

function Search-AD-Computer {
# ---------------------------------------------------------
# Search current domain for specific computer account name
# ---------------------------------------------------------
	Param (
		[string]$Computername = $null
    )         
	if([string]::IsNullOrEmpty($Computername)) { return $null }	
	$Result = Get-Dn $Computername  "(&(objectCategory=Computer)(name=$Computername))"	
	return $Result
}

function Search-AD-Server {
# ---------------------------------------------------------
# Search current domain for specific server account name
# ---------------------------------------------------------
	Param (
		[string]$Computername
    )         
	if([string]::IsNullOrEmpty($Computername)) { return $null }
	$Result = Get-Dn $Computername  "(&(objectCategory=Computer)(OperatingSystem=Windows*Server*)(name=$Computername))"	
	return $Result
}

function collectAD_Servers {
# ---------------------------------------------------------
# Return all server SAM account names in the domain
# ---------------------------------------------------------
	$ADSearchFilter = "(&(objectCategory=Computer)(OperatingSystem=Windows*Server*))"
	$colProplist = "name"
	$colResults = Search-AD $ADSearchFilter $colProplist
	return $colResults
}

function collectAD_Computers {
# ---------------------------------------------------------
# Return all computer SAM account names in the domain
# This in effect returns ALL computer accounts in the domain.
# ---------------------------------------------------------
	$ADSearchFilter = "(objectCategory=Computer)"
	$colProplist = "name"
	$colResults = Search-AD $ADSearchFilter $colProplist
	return $colResults
}

Function collectAD_Desktops {
# ---------------------------------------------------------
# Return all desktop computer SAM account names in the domain
# ---------------------------------------------------------
	$ADSearchFilter = "(&(objectClass=computer)(|(operatingSystem=Windows 2000 Professional)(operatingSystem=Windows XP*)(operatingSystem=*Vista*)(operatingSystem=Windows 7*)(operatingSystem=Windows 8*)))"
	$colProplist = "name"
	$colResults = Search-AD $ADSearchFilter $colProplist
	return $colResults
}

function collectAD_Users {
# ---------------------------------------------------------
# Return all user SAM account names in the domain
# ---------------------------------------------------------
	$ADSearchFilter = "(&(objectCategory=User))"
	$colProplist = "name"
	$colResults = Search-AD $ADSearchFilter $colProplist
	return $colResults
}

function collectAD_Users_SAM {
# ---------------------------------------------------------
# Return all user SAM account names in the domain
# ---------------------------------------------------------
	$ADSearchFilter = "(&(objectCategory=User))"
	$colProplist = "SamAccountname"
	$colResults = Search-AD $ADSearchFilter $colProplist
	return $colResults
}


function collectAD_Groups {
# ---------------------------------------------------------
# Return all user SAM account names in the domain
# ---------------------------------------------------------
	$ADSearchFilter = "(&(objectCategory=group))"
	$colProplist = "name"
	$colResults = Search-AD $ADSearchFilter $colProplist
	return $colResults
}

function Get-AdDomainPath {
# ---------------------------------------------------------
# Return the domain this computer belongs to and returns
# it as a path identifier for LDAP queries.
# ---------------------------------------------------------
	$domain = [ADSI]""
	$dn = $domain.distinguishedName
	return $dn
}

Function Set-AD-Account-ChngPwdAtNextLogon {
# ---------------------------------------------------------
# Set property to change password at next logon
# ---------------------------------------------------------
	Param (
        [string]$path
    )
	if([string]::IsNullOrEmpty($path)) { return $null }	
	$account=[ADSI]$path
	if ($account -eq $null ) { return $null } 	
	$PLSValue = 0 
    $account.psbase.invokeSet("pwdLastSet",$PLSValue) 
	$account.psbase.CommitChanges()   
}

Function Set-AD-Account-Pwd {
	Param (
        [string]$path,
		[string]$password
    )
	if([string]::IsNullOrEmpty($path)) { return $null }
	if([string]::IsNullOrEmpty($password)) { return $null }	
	$account=[ADSI]$path
	if ($account -eq $null ) { return $null } 	
	
    $account.psbase.invoke("SetPassword",$password) 
	$account.psbase.CommitChanges()
}

Function Get-AD-Account-DisabledStatus {
# ---------------------------------------------------------
# Returns true if AD account is disabled, false if not and $null if not found.
# ---------------------------------------------------------
	Param (
        [string]$path
    )
	if([string]::IsNullOrEmpty($path)) { return $null }
	$account=[ADSI]$path
	if ($account -eq $null ) { return $null } 
	$uac = $account.userAccountControl.get_Value()	
	$disabled = (($uac -bor 0x0002) -eq $uac)
	return $disabled
}

Function Enable-AD-Account {
# ---------------------------------------------------------
# Enable a Active Directory user/computer account
# Input LDAP path
# Return status of account
# ---------------------------------------------------------
	Param (
        [string]$path
    )
	if([string]::IsNullOrEmpty($path)) { return $null }
	$account=[ADSI]$path
	$account.psbase.invokeset("AccountDisabled", "False")
	$account.setinfo()
	$result = Get-AD-Account-DisabledStatus $path
	return $result
}

Function Disable-AD-Account {
# ---------------------------------------------------------
# Enable a Active Directory user/computer account
# Input LDAP path
# Return status of account
# ---------------------------------------------------------
	Param (
        [string]$path
    )
	if([string]::IsNullOrEmpty($path)) { return $null }
	$account=[ADSI]$path
	$account.psbase.invokeset("AccountDisabled", "True")
	$account.setinfo()	
	$result = Get-AD-Account-DisabledStatus $path
	return $result
}

function Get-Computers {
# ---------------------------------------------------------
# Get the name of all computer accounts in the domain
# and return them as an array
# ---------------------------------------------------------
	# Define the AD root object where to look for the computers.
	$Path = Get-AdDomainPath
	$Dom = "LDAP://" + $Path
	
	$objDomain = New-Object System.DirectoryServices.DirectoryEntry
	$Root = New-Object DirectoryServices.DirectoryEntry $Dom 
	
	# Create a selector and start searching from the root
	$Selector = New-Object DirectoryServices.DirectorySearcher
	$Selector.SearchRoot = $Root 
	$Selector.Filter = "(objectclass=computer)";
	
	$AdObjects = $Selector.findall() | where {$_.properties.objectcategory -match "CN=Computer"}
	
	# Loop over all AD Objects found an add the name of each object
	# to the clients array.
	[array]$Clients = $Null
	foreach ( $AdObject in $AdObjects ){ 
		$Properties = $AdObject.properties
		[string]$Name=$Properties.cn
		$Name = $Name.Trim()
		$Clients+= ,$Name
	}
	return $Clients
}

Function Set-ADObj-Description {
# ---------------------------------------------------------
# Sets or clears the description field of a Domain object
# Input LDAP path
# Returns null in all cases.
# ---------------------------------------------------------
	param ( 
		[string]$DN, 
		[string]$Description = ""
	)
	if([string]::IsNullOrEmpty($DN)) { return $null }
	$obj = [ADSI]$DN
	if($obj -ne $null) {		
		$Cur = $obj.Description
		$CurVal = $Cur.value
		if($Cur -ne $null) { 
  			if(($Description -ne $null) -and ($Description.length -gt 0)) {
				# Change field when input value is not empty and different from current value
				if ( $CurVal.CompareTo($Description) -ne 0 ) {
  					$obj.Put("description", $Description)
    				$obj.SetInfo()
				}
			} else {
				# Erase field when input value is empty
				$obj.PutEx(1, "description", 0)
    			$obj.SetInfo()			
			}
		} else {
			# Change value is current value is empty and new value is not empty.
			if(($Description -ne $null) -and ($Description.length -gt 0)) {
				$obj.Put("description", $Description)
    			$obj.SetInfo()				
			}
		}
	}
  	return $null
}

Function Set-ADObj-Info {
# ---------------------------------------------------------
# Sets or clears the information field of an AD object
# Input LDAP path and info field
# Returns null in all cases.
# ---------------------------------------------------------
	param ( 
		[string]$DN, 
		[string]$Info = ""
	)
	
	if([string]::IsNullOrEmpty($DN)) { return $null }
  	$obj = [ADSI]$DN	
	if($obj -ne $null) {
		$Cur = $obj.info	
		if($Cur.Value -eq $null) {
			if($Info.length -gt 0) {
				# Compare if info is really new
				if ( $Cur.CompareTo($Info) -ne 0 ) {
					$obj.Put("info", $Info)
    				$obj.SetInfo()
				}
			}
		} else {
			if($Info.length -gt 0) {
				# Compare if info is really new
				if ( $Cur.CompareTo($Info) -ne 0 ) {
					$obj.Put("info", $Info)
    				$obj.SetInfo()
				}
			} else {
				# Erase field when input value is empty
				if($Cur -ne $null) {
					$obj.PutEx(1, "info", 0)
    				$obj.SetInfo()
				}
			}
		}
	}
	return $null  
}

Function Get-ADObj-Info {
# ---------------------------------------------------------
# Returns the information text of a Domain object
# ---------------------------------------------------------
	param ( 
		[string]$DN 
	)
	if([string]::IsNullOrEmpty($DN)) { return $null }
	$obj = [ADSI]$DN
	if($obj -ne $null) { return $obj.Info } 
	else { return $null	}
}

Function Get-ADObj-Description {
# ---------------------------------------------------------
# Returns the description text of a Domain object
# ---------------------------------------------------------
	param ( 
		[string]$DN 
	)
	$obj = [ADSI]$DN
	if([string]::IsNullOrEmpty($DN)) { return $null }
	if($obj -ne $null) { return $obj.Description } 
	else { return $null	}
}

function IsComputerAlive {
# ---------------------------------------------------------
# Ping the specified system to check if it is
# switched on.
# ---------------------------------------------------------
	param ( 
		[string] $Computer
	)
	if([string]::IsNullOrEmpty($Computer)) { return $null }	
	$WmiFilter = "Address='" + $Computer + "'"
	$WmiObject = Get-WmiObject -Class Win32_PingStatus -Filter $WmiFilter
	$StatusCode = $WmiObject.StatusCode
	$IsAlive = ($StatusCode -eq 0)
	return $IsAlive
}

function Get-ComputerAdDescription {	
# ---------------------------------------------------------
# Get The computer description that is stored in the 
# active directory.
# ---------------------------------------------------------
	param ( 
		[string] $Computer
	)	
	if([string]::IsNullOrEmpty($Computer)) { return $null }		
	$Path = Get-DN $Computer "(&(objectCategory=Computer)(name=$Computer))"
	If ($Path -ne $null) { $Description = Get-ADObj-Description $Path }
	else { $Description = $null } 
	return $Description
}

Function Set-AD-AccountDescription {
# ---------------------------------------------------------
# Set the Active Directory account description 
# ---------------------------------------------------------
	Param (
        [string]$path,
		[string]$description = ""
	)
	if([string]::IsNullOrEmpty($path)) { return $null }	
	Set-ADObj-Description $path $description
	return $null
}

Function Set-ComputerAdDescription
# ---------------------------------------------------------
# Set the Active Directory computer description 
# ---------------------------------------------------------
{
	Param ([string]$path, 
		[string]$description
	)	
	if([string]::IsNullOrEmpty($Computer)) { return $null }
	Set-ADObj-Description $path $description
	return $null
}

function Get-ComputerComment {
# ---------------------------------------------------------
# Get The computer description that is currently stored
# in the computers registry.
# ---------------------------------------------------------
	param ( 
		[string] $Computer
	)	
	if([string]::IsNullOrEmpty($Computer)) { return $null }
	$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey( "LocalMachine", $Computer )
	if ( $Registry -eq $Null ) { return $null }
	$RegKey= $Registry.OpenSubKey( "SYSTEM\CurrentControlSet\Services\lanmanserver\parameters" )	
	if ( $RegKey -eq $Null ) { return $null	}
	[string]$Description = $RegKey.GetValue("srvcomment")
	if ( $Description -eq $Null ) {	$Description = "" }
		
	return $Description
}

function Set-ComputerComment {
# ---------------------------------------------------------
# Set the computer description stored
# in the computers registry.
# ---------------------------------------------------------

	param ( 
		[string] $Computer, 
		[string] $Description 
	)
	
	if([string]::IsNullOrEmpty($Computer)) { return $null }
	$Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey( "LocalMachine", $Computer )
	if ( $Registry -eq $Null ) { return $Null }
	$RegPermCheck = [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree 
	$RegKeyRights = [System.Security.AccessControl.RegistryRights]::SetValue
	$RegKey = $Registry.OpenSubKey( "SYSTEM\CurrentControlSet\Services\lanmanserver\parameters", $RegPermCheck, $RegKeyRights )
	if ( $RegKey -eq $Null ) { return $Null }
	$RegKey.SetValue("srvcomment", $Description )
}

function SyncComment {
# ---------------------------------------------------------
# Check the comment for the specified computer stored in
# it's local registry and compare it with the description
# stored in the active directory.
# If the values are different the local computer comment
# will be overwritten with the AD description.
# ---------------------------------------------------------
	param ( 
		[string]$Computer = $Env:COMPUTERNAME
	)	
	if([string]::IsNullOrEmpty($Computer)) { return $null }	
	$NtComment = Get-ComputerComment $Computer	
	$AdComment = Get-ComputerAdDescription $Computer		
	if ( $NtComment -cne $AdComment ) {
		Set-ComputerComment $Computer $AdComment
	}
}

function SyncComments {
# ---------------------------------------------------------
# Query all computers in the current domain and sync
# the comment for eatch of them.
# ---------------------------------------------------------
	$Computers = Get-Computers
	foreach ( $Computer in $Computers ) {
		$Online = IsComputerAlive $Computer
		if ( $Online ) {
			SyncComment $Computer 
		}
	}
}

Function ResolveDNS {
# ---------------------------------------------------------
# Resolve DNS name to IP address
# ---------------------------------------------------------
	param ( 
		[string]$DNSName 
	)
	if([string]::IsNullOrEmpty($DNSName)) { return $null }	
	$result = [System.Net.DNS]::GetHostAddresses($DNSName)
	return $result
} 

Function ResolveIP {
# ---------------------------------------------------------
# Resolve IP address to DNS name
# ---------------------------------------------------------
	param ( 
		[string]$IPName
	)
	if([string]::IsNullOrEmpty($IPName)) { return $null }	
	$result = [System.Net.DNS]::GetHostByAddress($IPName)
	return $result
} 

Function Create-Domain-Global-Group
{
	Param (
		[string]$Groupname,
		[string]$SamAccountName,
        [string]$OU,
		[string]$Description = ""
    )
	if([string]::IsNullOrEmpty($Groupname)) { return $null }
	if([string]::IsNullOrEmpty($SamAccountName)) { return $null }
	if([string]::IsNullOrEmpty($OU)) { return $null }
	if([string]::IsNullOrEmpty($Description)) { $Description = "" }
	
	$ADSearchFilter = "(&(objectCategory=group)(name=$Groupname))"	
	$Result = Search-AD-Group $ADSearchFilter				
	if ($Result -eq 0) {	
		$objOU = [ADSI]$OU
		$objGroup = $objOU.Create("group", "CN=" + $GroupName)
		$objGroup.Put("sAMAccountName", $SamAccountName )
		$objGroup.Put("description", $Description )
		$objGroup.SetInfo()
		
		$Result = Search-AD-Group $Groupname				
	} 
	return $Result	
}

Function Create-Domain-Local-Group
{
	$ADS_GROUP_TYPE_LOCAL_GROUP = 0x00000004
	
	Param (
		[string]$Groupname,
		[string]$SamAccountName,
        [string]$OU,
		[string]$Description = ""
    )	
	if([string]::IsNullOrEmpty($Groupname)) { return $null }
	if([string]::IsNullOrEmpty($SamAccountName)) { return $null }
	if([string]::IsNullOrEmpty($OU)) { return $null }
	if([string]::IsNullOrEmpty($Description)) { $Description = "" }
	
	$ADSearchFilter = "(&(objectCategory=group)(name=$Groupname))"	
	$Result = Search-AD-Group $ADSearchFilter				
	if ($Result -eq 0) {	
		$objOU = [ADSI]$OU
		$objGroup = $objOU.Create("group", "CN=" + $GroupName)
		$objGroup.Put("sAMAccountName", $SamAccountName )
		$objGroup.Put("groupType", $ADS_GROUP_TYPE_LOCAL_GROUP )
		$objGroup.Put("description", $Description )
		$objGroup.SetInfo()
		
		$Result = Search-AD-Group $Groupname
	}	
	return $result
}

Function Get-Domain-Group-Members
{	
	Param (
		[string]$DomainGroupPath		
    )			
	if([string]::IsNullOrEmpty($DomainGroupPath)) { return $null }
	$Group = [adsi]$DomainGroupPath 
	return $Group.member
}

Function Add-User-To-Domain-Group
{
	Param (
		[string]$DomainGroupPath,
		[string]$DomainUserPath     		
    )
	if([string]::IsNullOrEmpty($DomainGroupPath)) { return $null }
	if([string]::IsNullOrEmpty($DomainUserPath)) { return $null }	
	
	#Check if group exists
	$Result = [adsi]$DomainGroupPath
	if ($Result -ne 0) { 	
		# Check if user exists
		$Result = [adsi]$DomainUserPath     		
		if ($Result -ne $null) { 			
			# Check if user is already a member of this group			
			$Result = Get-Domain-Group-Members $DomainGroupPath 
			$UPath = $DomainUserPath.Replace("LDAP://","")
			$Found = $Result  -ccontains $UPath
			if ($Found -eq $false ) {
				$Group = [adsi]$DomainGroupPath
    			$Group.Add($DomainUserPath) 
			}
		}
	}
}