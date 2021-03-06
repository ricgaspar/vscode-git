<#
.SYNOPSIS
    VNB Library - Active Directory functions

.CREATED_BY
	Marcel Jussen

.CHANGE_DATE
	4-6-2017
 
.DESCRIPTION
    Functions to search and change user/computer/group objects
#>
#Requires -version 3.0

function Get-Domain {
# ---------------------------------------------------------
# Return information of the domain this computer belongs to.
# Returns NULL if anything goes wrong
# ---------------------------------------------------------
    [Cmdletbinding()]    
    Param(    	        
		[Parameter(ValueFromPipeline=$False, ValueFromPipelineByPropertyName=$True)]
		[string]
        $DomainController,        
        [Parameter()]
        [Management.Automation.PSCredential]
		$Credential    
    )
	
	process {
		try {
    		if(!$DomainController) {
        		return [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()        		
			}
    
    		if($Creds) {
        		$Context = new-object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",
                                                                                $DomainController,
                                                                                $Creds.UserName,
                                                                                $Creds.GetNetworkCredential().Password)
    		} else {
        		$Context = new-object DirectoryServices.ActiveDirectory.DirectoryContext("DirectoryServer",$DomainController)
    		}    
    		return [DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)
		}
		catch {
			return $null
		}
	}
}
Set-Alias Get-ActiveDirectoryDomain Get-Domain
Set-Alias Get-ADDomain Get-Domain

Function Get-ADInfo {
# ---------------------------------------------------------
# Return information of the domain this computer belongs to.
# ---------------------------------------------------------
	[Cmdletbinding()]    
    Param(    	
        [Parameter()]
		[string]
        $DomainController,
        
        [Parameter()]
        [Management.Automation.PSCredential]
		$Credential
    
    )
	
	process {
		try { 
    		$ADDomain = Get-Domain -DomainController $DomainController -Credential $Credential
		
    		$ADDomainName = $ADDomain.Name
    		$Netbios = $ADDomain.Name.Split(".")[0].ToUpper()
    		$ADServer = $ADDomain.InfrastructureRoleOwner.Name
    		$FQDN = "DC=" + $ADDomain.Name -Replace("\.",",DC=") 
		
    		$Results = New-Object Psobject
			$Results | Add-Member Noteproperty Forest $ADDomainName
    		$Results | Add-Member Noteproperty Domain $ADDomainName
    		$Results | Add-Member Noteproperty FQDN $FQDN
			$Results | Add-Member Noteproperty DC $ADServer
    		$Results | Add-Member Noteproperty Server $ADServer
    		$Results | Add-Member Noteproperty Netbios $Netbios		
			
    		return $Results
		}
		catch {
			return $null
		}
	} # process end
}
Set-Alias Get-ActiveDirectoryInfo Get-ADInfo

function Get-DnsDomain {
# ---------------------------------------------------------
# Return the DNS name of the domain this computer belongs to.
# ---------------------------------------------------------	
	begin {         
    } # begin end
	process {
		$ADInfo = Get-ADInfo
		[system.string]($ADInfo.Domain)
	}
}

Function Get-NetbiosDomain
# ---------------------------------------------------------
# Return the Netbios name of the domain this computer belongs to.
# ---------------------------------------------------------
{
	begin {         
    } # begin end
	process {
		$ADInfo = Get-ADInfo
		[system.string]($ADInfo.Netbios)
	}
}

function Search-AD { 
# ---------------------------------------------------------
# Search current domain with a search filter and propery list
# Returns an object with all found AD objects
# ---------------------------------------------------------

# ---------------------------------------------------------
# To search Active Directory and create a list with sorted names do this:
#
# Object-List = Search-AD
# $ComputerList = @()
# foreach ($objResult in $ObjectList) {
#   $ObjItem = $objResult.Properties
#   $ObjComputer = New-Object System.Object
#   $ObjComputer | Add-Member -MemberType NoteProperty -Name Name -Value $($ObjItem.name) -Force
#   $ObjComputer | Add-Member -MemberType NoteProperty -Name AdsPath -Value $($ObjItem.adspath) -Force
#   $ComputerList += $ObjComputer			
# }
# $ComputerList = $ComputerList | sort @{expression={$_.Name};Descending=$false}

# foreach($Computer in $ComputerList) {
#	$Computer.Name
# }
#
# ---------------------------------------------------------

	[CmdletBinding()]
    param (        
        [Parameter(Position=0, ValuefromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$ADSearchFilter = "(&(objectCategory=Computer)(OperatingSystem=Windows*Server*))",
		
		[Parameter(Position=1, ValuefromPipeline=$false)]
        [System.Array]
		$colProplist = "name",
		
		[Parameter(Position=2, ValuefromPipeline=$false)]
        [System.String]
		$OU
    ) # param end
    
    begin {		
		if([string]::IsNullOrEmpty($OU)) { 
			$domain = New-Object System.DirectoryServices.DirectoryEntry
			$OU = 'LDAP://' + $domain.distinguishedName
		}
    } # begin end
    
    process { 
        try {			
			$objDomain = New-Object System.DirectoryServices.DirectoryEntry($OU)			
			$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
			$objSearcher.SearchRoot = $objDomain
			$objSearcher.PageSize = 5000
			$objSearcher.Filter = $ADSearchFilter      
			foreach ($i in $colPropList) {
				[Void]($objSearcher.PropertiesToLoad.Add($i))
			}
			$colResults = $objSearcher.FindAll()
        } # try end
 
        catch {
            return $null
        } # catch end
 
        finally {
			$colResults
        } # finally end
    } # process end
     
    end {
    } # end end	
}

Function Get-ADObjectDN {
# ---------------------------------------------------------
# Search current domain with a search filter
# Default search is for a computer with the name of $objectname 
# Returns the ADSPATH (DN) for the account or $null if not found
# ---------------------------------------------------------	
	[CmdletBinding()]
	param (
		[Parameter(Position=0,ValuefromPipeline=$true)]
		[system.string]
		$ObjectName = $Env:COMPUTERNAME,
		
		[Parameter(Position=1,ValuefromPipeline=$false)]
		[system.string]
		$Filter = "(&(objectCategory=computer)(name=$ObjectName))",
		
		[Parameter(Position=2,ValuefromPipeline=$false)]
		[system.string]
		$OU
		
	) # param end
	
	begin {
		$result = $null
    } # begin end
	
	process {
		try {
			$colresults = Search-AD -ADSearchFilter $Filter -colPropList "path" -OU $OU
			if ($colResults) { 
				Foreach ($col in $colResults) { 
					$result = $col.Path 
				}
			}
		} # try end
		
		catch {
            return $null 
        } # catch end		
	} # process end
	
	end {
		return $result
	}
}
Set-Alias Get-DN Get-ADObjectDN

function Get-ADUserDN {
# ---------------------------------------------------------
# Search current domain for specific user account name
# ---------------------------------------------------------
	[CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$false)]		
        [System.String]
        $Username = $env:USERNAME,
		
		[Parameter(Position=1,ValuefromPipeline=$false)]
		[system.string]
		$OU
 
    ) # param end
    
    begin {         
    } # begin end
    
    process { 
        try {
			Get-ADObjectDN -ObjectName $Username -Filter "(&(objectCategory=User)(SamAccountName=$Username))" -OU $OU
        } # try end
 
        catch {
            return $null
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias -Name 'Search-ADUser' -Value 'Get-ADUserDN'
Set-Alias -Name 'Search-AD-User' -Value 'Get-ADUserDN'

function Get-ADGroupDN {
# ---------------------------------------------------------
# Search current domain for specific user account name
# ---------------------------------------------------------
	[CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true)]		
        [System.String]
        $Groupname = $env:USERNAME,
		
		[Parameter(Position=1,ValuefromPipeline=$false)]
		[system.string]
		$OU
 
    ) # param end
    
    begin {         
    } # begin end
    
    process { 
        try {
			Get-ADObjectDN -ObjectName $Username -Filter "(&(objectCategory=Group)(SamAccountName=$Groupname))" -OU $OU
        } # try end
 
        catch {
            return $null
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias -Name 'Search-ADGroup' -Value 'Get-ADGroupDN'
Set-Alias -Name 'Search-AD-Group' -Value 'Get-ADGroupDN'

function Get-ADComputerDN {
# ---------------------------------------------------------
# Search current domain for specific computer account name
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$false)]
		[system.string]
		$Computername = $Env:COMPUTERNAME,
		
		[Parameter(Position=1,ValuefromPipeline=$false)]
		[system.string]
		$OU
    )
	
	begin {         
    } # begin end
		
	process { 
        try {
			Get-ADObjectDN -ObjectName $Computername -Filter "(&(objectCategory=Computer)(name=$Computername))" -OU $OU
        } # try end
 
        catch {
            return $null
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias -Name 'Search-ADComputer' -Value 'Get-ADComputerDN'
Set-Alias -Name 'Search-AD-Computer' -Value 'Get-ADComputerDN'

function Get-ADServerDN {
# ---------------------------------------------------------
# Search current domain for specific server account name
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[system.string]
		$Computername,
		
		[Parameter(Position=1,ValuefromPipeline=$false)]
		[system.string]
		$OU
    )
	
	begin {         
    } # begin end
	
	process { 
        try {
			Get-ADObjectDN -ObjectName $Computername -Filter "(&(objectCategory=Computer)(OperatingSystem=Windows*Server*)(name=$Computername))" -OU $OU
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end		
}
Set-Alias -Name 'Search-ADServer' -Value 'Get-ADServerDN'
Set-Alias -Name 'Search-AD-Server' -Value 'Get-ADServerDN'

function Get-ADServers {
# ---------------------------------------------------------
# Return all server SAM account names in the domain
# ---------------------------------------------------------	
	begin {         
    } # begin end
	
	process { 
        try {
			$ADSearchFilter = '(&(objectCategory=Computer)(OperatingSystem=Windows*Server*))'
			$colProplist = 'name'
			Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist 
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {			
        } # finally end
    } # process end
     
    end {
    } # end end
}

function Get-ADComputers {
# ---------------------------------------------------------
# Return all computer SAM account names in the domain
# This in effect returns ALL computer accounts in the domain.
# ---------------------------------------------------------
	begin {         
    } # begin end
	
	process { 
        try {
			$ADSearchFilter = '(objectCategory=Computer)'
			$colProplist = 'name'
			Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end
}

Function Get-ADDesktops {
# ---------------------------------------------------------
# Return all desktop computer SAM account names in the domain
# ---------------------------------------------------------
	begin {         
    } # begin end
	
	process { 
        try {
			$ADSearchFilter = "(&(objectClass=computer)(|(operatingSystem=Windows 2000 Professional)(operatingSystem=Windows XP*)(operatingSystem=*Vista*)(operatingSystem=Windows 7*)(operatingSystem=Windows 8*)(operatingSystem=Windows 10*)))"
			$colProplist = 'name'
			Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end
}

function Get-ADUsers {
# ---------------------------------------------------------
# Return all user SAM account names in the domain
# ---------------------------------------------------------
	begin {         
    } # begin end
	
	process { 
        try {
			$ADSearchFilter = "(&(objectCategory=User))"
			$colProplist = 'name'
			Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}

function Get-ADUsersSAM {
# ---------------------------------------------------------
# Return all user SAM account names in the domain
# ---------------------------------------------------------
	begin {         
    } # begin end
	
	process { 
        try {
			$ADSearchFilter = "(&(objectCategory=User))"
			$colProplist = "SamAccountname"
			Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias -Name 'collectAD_Users_SAM' -Value 'Get-ADUsersSAM'

function Get-ADGroups {
# ---------------------------------------------------------
# Return all user SAM account names in the domain
# ---------------------------------------------------------
	begin {         
    } # begin end
	
	process { 
        try {
			$ADSearchFilter = "(&(objectCategory=group))"
			$colProplist = "name"
			Search-AD -ADSearchFilter $ADSearchFilter -colProplist $colProplist
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}

function Get-AdDomainPath {
# ---------------------------------------------------------
# Return the domain this computer belongs to and returns
# it as a path identifier for LDAP queries.
# ---------------------------------------------------------
	begin {         
    } # begin end
	
	process { 
        try {
			$domain = [ADSI]""
			$domain.distinguishedName
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}

Function Set-ADAccountChngPwdAtNextLogon {
# ---------------------------------------------------------
# Set property to change password at next logon
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
		$Path
    ) # end param
	
	begin {         
    } # begin end
	
	process { 
        try {
			$account=[ADSI]$Path
			if ($account -ne $null ) { 
				$PLSValue = 0 
    			$account.psbase.invokeSet("pwdLastSet",$PLSValue) 
				$account.psbase.CommitChanges()   
			} 	
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end		
}
Set-Alias -Name 'Set-AD-Account-ChngPwdAtNextLogon' -Value 'Set-ADAccountChngPwdAtNextLogon'

Function Set-ADAccountPwd {
# ---------------------------------------------------------
#
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [System.String]
		$Path,
		
		[Parameter(Position=1, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Alias("NewPassword","PW")]
		[System.String]
		$Password
		
    ) # end param
	
	begin {         
    } # begin end
	
	process { 
        try {
			$account=[ADSI]$Path
			if ($account) { 
				$account.psbase.invoke("SetPassword", $Password) 
				$account.psbase.CommitChanges()
			}
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end		
	
}
Set-Alias -Name 'Set-AD-Account-Pwd' -Value 'Set-ADAccountPwd'

Function Get-ADAccountDisabledStatus {
# ---------------------------------------------------------
# Returns true if AD account is disabled, false if not and $null if not found.
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [System.String]
		$Path
    )
	
	begin {
		$disabled = $null
    } # begin end
	
	process { 
        try {
			$account=[ADSI]$path
			if ($account) { 
				$uac = $account.userAccountControl.get_Value()	
				$disabled = [bool] (($uac -bor 0x0002) -eq $uac)
			} 			
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {			
        } # finally end
    } # process end
     
    end {
		$disabled
    } # end end	
	
}
Set-Alias -Name 'Get-AD-Account-DisabledStatus' -Value Get-ADAccountDisabledStatus

Function Enable-ADAccountStatus {
# ---------------------------------------------------------
# Enable a Active Directory user/computer account
# Input LDAP path
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [System.String]
		$Path
    )
	
	begin {		
		$status = Get-ADAccountDisabledStatus $Path
    } # begin end
	
	process { 
        try {			
			$account=[ADSI]$path
			if($account) {
				$account.psbase.invokeset('AccountDisabled', 'False')
				$account.setinfo()
				$status = Get-ADAccountDisabledStatus $Path
			}
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
			
        } # finally end
    } # process end
     
    end {
		$status
    } # end end	
}
Set-Alias -Name 'Enable-AD-Account' -Value 'Enable-ADAccountStatus'
Set-Alias -Name 'Enable-ADAccount' -Value 'Enable-ADAccountStatus'

Function Disable-ADAccountStatus {
# ---------------------------------------------------------
# Enable a Active Directory user/computer account
# Input LDAP path
# Return status of account
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [System.String]
		$Path
    )
	
	begin {		
		$status = Get-ADAccountDisabledStatus $Path
    } # begin end
	
	process { 
        try {			
			$account=[ADSI]$path
			if($account) { 
				$account.psbase.invokeset("AccountDisabled", "True")
				$account.setinfo()
				$status = Get-ADAccountDisabledStatus $Path
			}
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
			
        } # finally end
    } # process end
     
    end {
		$status 
    } # end end	
}
Set-Alias -Name 'Disable-AD-Account' -value 'Disable-ADAccountStatus'
Set-Alias -Name 'Disable-ADAccount' -value 'Disable-ADAccountStatus'

Function Remove-ADObject {
# ---------------------------------------------------------
# Delete a Active Directory user/computer object
# Input LDAP path
# Return status of account
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [System.String]
		$Path
    )
	
	begin {		
    } # begin end
	
	process { 
        try {			
			$account=[ADSI]$path
			if($account) {
				try {$account.deletetree()}
				catch{}
			}
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
			
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias -Name 'Remove-ADAccount' -value 'Remove-ADObject'

function Get-ADComputersInArray {
# ---------------------------------------------------------
# Get the name of all computer accounts in the domain
# and return them as an array
# ---------------------------------------------------------
	begin {		
		# Define the AD root object where to look for the computers.
		$Path = Get-AdDomainPath
		$Dom = "LDAP://" + $Path		
    } # begin end
	
	process { 
        try {			
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
				[system.string]$Name=$Properties.name
				$Name = $Name.Trim()
				$Clients+= ,$Name
			}	
			
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
			$Clients
        } # finally end
    } # process end
     
    end {
    } # end end	
}

Function Set-ADObjDescription {
# ---------------------------------------------------------
# Sets or clears the description field of a Domain object
# Input LDAP path
# Returns null in all cases.
# ---------------------------------------------------------
	[CmdletBinding()]
	param ( 
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
        [System.String]
		$Path, 
		
		[Parameter(Position=1, Mandatory=$false)]		
        [System.String]
		$Description = ""
	)
	
	process { 
        try {			
			$obj = [ADSI]$Path
			if($obj) {		
				$Cur = $obj.Description
				$CurVal = $Cur.value
				if($Cur) { 
  					if(($Description) -and ($Description.length -gt 0)) {
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
  	
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
			
        } # finally end
    } # process end
     
    end {
    } # end end	
}

Function Set-ADObjInfo {
# ---------------------------------------------------------
# Sets or clears the information field of an AD object
# Input LDAP path and info field
# Returns null in all cases.
# ---------------------------------------------------------
	[CmdletBinding()]
	param ( 
		[Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$Path, 
		
		[Parameter(Position=1, Mandatory=$false)]        
		[System.String]
		$Info = ""
	)
	
	begin {         
    } # begin end
    
    process { 
        try {
			$obj = [ADSI]$Path	
			if($obj) {
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
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end  	  
}
Set-Alias Set-ADObj-Info Set-ADObjInfo
Set-Alias Set-ADObjectInfo Set-ADObjInfo

Function Get-ADObjInfo {
# ---------------------------------------------------------
# Returns the information text of a Domain object
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$Path 
	)
	
	begin {         
    } # begin end
    
    process { 
        try {
			$obj = [ADSI]$Path
			if($obj) { $obj.Info } 	
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias Get-ADObj-Info Get-ADObjInfo
Set-Alias Get-ADObjectInfo Get-ADObjInfo

Function Get-ADObjDescription {
# ---------------------------------------------------------
# Returns the description text of a Domain object
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[System.String]
		$Path 
	)
	
	begin {         
    } # begin end
    
    process { 
        try {
			$obj = [ADSI]$Path
			if($obj) { $obj.Description } 	
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias Get-ADObjectDescription Get-ADObjDescription

function Get-ComputerAdDescription {	
# ---------------------------------------------------------
# Return the computer description that is stored in
# active directory.
# ---------------------------------------------------------
	[CmdletBinding()]
	param (
		[Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]		
		[System.String]
		$Computername			
	)
	
	begin {         
		$Description = $null
    } # begin end
    
    process { 
        try {
			$Path = Get-ADObjectDN $Computername "(&(objectCategory=Computer)(name=$Computername))"
			If ($Path ) { $Description = Get-ADObjDescription -Path $Path }		
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {
			$Description
        } # finally end
    } # process end
     
    end {
    } # end end
}

Function Set-ADAccountDescription {
# ---------------------------------------------------------
# Set the Active Directory account description 
# ---------------------------------------------------------
	[CmdletBinding()]
	Param (
		[Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
		$Path,
		
		[System.String]
		$Description = ""
	)
	
	begin {         		
    } # begin end
    
    process { 
        try {
			Set-ADObjDescription -Path $Path -Description $Description
        } # try end
 
        catch {
            return $null 
        } # catch end
 
        finally {			
        } # finally end
    } # process end
     
    end {
    } # end end	
}
Set-Alias -Name 'Set-ComputerAdDescription' -Value 'Set-ADAccountDescription'

function Sync-DomainComputersComment {
# ---------------------------------------------------------
# Query all computers in the current domain and sync
# the comment for each of them.
# ---------------------------------------------------------
	Process {
		try {
			$Servers = Get-ADServers			
			foreach ( $Computer in $Servers ) {
				$ComputerProps = $Computer.Properties
				$Computername = $ComputerProps.name
				if ( (Test-ComputerAlive $Computername) ) { Sync-ComputerComment $Computername }
			}
		}
		catch {
			return $null
		}
	}
}

Function New-DomainGlobalGroup {
# --------------------------------------------------------- 
# Create a new domain global group
# ---------------------------------------------------------	
	[CmdletBinding()]
	Param (
		[parameter(Mandatory=$True)]
		[system.string]
		$Groupname,
		
		[parameter(Mandatory=$True)]
		[system.string]
		$SamAccountName,
		
		[parameter(Mandatory=$True)]
        [system.string]
		$OU,
		
		[parameter(Mandatory=$True)]
		[system.string]
		$Description
    )
	
	Begin {
		$Result = $null
	}
	
	Process {
		try {
			$ADSearchFilter = "(&(objectCategory=group)(name=$Groupname))"	
			$ADResult = Search-AD-Group $ADSearchFilter				
			if ($ADResult -eq 0) {	
				$objOU = [ADSI]$OU
				$objGroup = $objOU.Create("group", "CN=" + $GroupName)
				$objGroup.Put("sAMAccountName", $SamAccountName )
				$objGroup.Put("description", $Description )
				$objGroup.SetInfo()
			}
		}
		catch {
			return $null
		}
		$Result = Search-AD-Group $Groupname
		return $Result	
	}
}

Function New-DomainLocalGroup {
# --------------------------------------------------------- 
# Create a new domain local group
# ---------------------------------------------------------	
	[CmdletBinding()]
	Param (
		[parameter(Mandatory=$True)]
		[system.string]
		$Groupname,
		
		[parameter(Mandatory=$True)]
		[system.string]
		$SamAccountName,
		
		[parameter(Mandatory=$True)]
        [system.string]
		$OU,
		
		[parameter(Mandatory=$True)]
		[system.string]
		$Description
    )	
	
	Begin {
		$ADS_GROUP_TYPE_LOCAL_GROUP = 0x00000004
		$ADSearchFilter = "(&(objectCategory=group)(name=$Groupname))"	
		$Result = Search-AD-Group $ADSearchFilter
	}
	Process {						
		try {
			if ($Result -eq 0) {	
				$objOU = [ADSI]$OU
				$objGroup = $objOU.Create("group", "CN=" + $GroupName)
				$objGroup.Put("sAMAccountName", $SamAccountName )
				$objGroup.Put("groupType", $ADS_GROUP_TYPE_LOCAL_GROUP )
				$objGroup.Put("description", $Description )
				$objGroup.SetInfo()
			}
		}
		catch {
			return $null
		}
		$Result = Search-AD-Group $Groupname
		return $result
	}		
}

Function Get-DomainGroupMembers {
# --------------------------------------------------------- 
# Return DN paths of members of a domain group
# ---------------------------------------------------------	
	[CmdletBinding()]
	Param (
		[Parameter(Position=0,ValuefromPipeline=$True)]
		[system.string]
		$DomainGroupPath		
    )			
	Process {	
		Try {			
			$Group = [adsi]$DomainGroupPath 
			$result = $Group.member
		}
		Catch {
			$result = $null
		}
		return $Result
	}
}

Function Add-UserToDomainGroup {
# --------------------------------------------------------- 
# Add a user DN to a domain group
# ---------------------------------------------------------	
	[CmdletBinding()]
	Param (
		[parameter(Mandatory=$True)]
		[system.string]
		$DomainGroupPath,
		
		[parameter(Mandatory=$True)]
		[system.string]
		$DomainUserPath
    )
	Process {
		try {
			#Check if group exists
			$Result = [adsi]$DomainGroupPath
			if ($Result -ne 0) { 	
				# Check if user exists
				$Result = [adsi]$DomainUserPath     		
				if ($Result -ne $null) { 			
					# Check if user is already a member of this group			
					$Result = Get-DomainGroupMembers $DomainGroupPath 
					$UPath = $DomainUserPath.Replace("LDAP://","")
					$Found = $Result  -ccontains $UPath
					if ($Found -eq $false ) {
						$Group = [adsi]$DomainGroupPath
    					$Group.Add($DomainUserPath) 
					}
				}
			}
		}
		catch {
			return $null
		}
	}
}
Set-Alias -Name 'Add-User-To-Domain-Group' -Value 'Add-UserToDomainGroup'

# --------------------------------------------------------- 
# Export aliases
# --------------------------------------------------------- 
export-modulemember -alias * -function *