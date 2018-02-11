# ---------------------------------------------------------
# Update AD computer object with logged on user information
# VDL Nedcar IT - Marcel Jussen
# 15-05-2013
# ---------------------------------------------------------

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

Function Create-Computer-Description {
	$strComputer = "."
	$colItems = get-wmiobject -class "Win32_ComputerSystem" -namespace "root\CIMV2" -computername $strComputer
	foreach ($objItem in $colItems) {
		$Manufacturer = $objItem.Manufacturer 
		$Model = $objItem.Model
	}
	$Result = $null
	if(($Manufacturer -ne $null) -and ($Model -ne $null)) { 
		$Result = $Manufacturer + " (" + $Model + ")"
	}
	return $result
}

Function Set-ADObj-Description {
# ---------------------------------------------------------
# Sets or clears the description field of a domain object
# Input LDAP path
# Returns null in all cases.
# ---------------------------------------------------------
	param ( 
		[string]$DN, 
		[string]$Description = ""
	)
	if (($DN -eq $null) -or ($DN.length -eq 0)) { return $null }	
	$obj = [ADSI]$DN
	if($obj -ne $null) {		
		$Cur =[string]$obj.Description
		if($Cur -ne $null) { 
  			if(($Description -ne $null) -and ($Description.length -gt 0)) {
				# Change field when input value is not empty and different from current value				
				if ( $Cur.CompareTo($Description) -ne 0 ) {
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

Function Set-ADObj-Displayname {
# ---------------------------------------------------------
# Sets or clears the description field of a domain object
# Input LDAP path
# Returns null in all cases.
# ---------------------------------------------------------
	param ( 
		[string]$DN, 
		[string]$Displayname = ""
	)
	if (($DN -eq $null) -or ($DN.length -eq 0)) { return $null }	
	$obj = [ADSI]$DN
	if($obj -ne $null) {		
		$Cur = [string]$obj.Displayname
		if($Cur -ne $null) { 
  			if(($Displayname -ne $null) -and ($Displayname.length -gt 0)) {
				# Change field when input value is not empty and different from current value
				if ( $Cur.CompareTo($Displayname) -ne 0 ) {
  					$obj.Put("displayname", $Displayname)
    				$obj.SetInfo()
				}
			} else {
				# Erase field when input value is empty
				$obj.PutEx(1, "displayname", 0)
    			$obj.SetInfo()			
			}
		} else {
			# Change value is current value is empty and new value is not empty.
			if(($Displayname -ne $null) -and ($Displayname.length -gt 0)) {
				$obj.Put("displayname", $Displayname)
    			$obj.SetInfo()				
			}
		}
	}
  	return $null
}

Clear

# Check if domain is available
$ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$ADDomainName = $ADDomain.Name
if($ADDomainName -eq "nedcar.nl") {

	# Retrieve computer object in domain
	$Computername = gc env:computername
	$LDAPComputer = Get-Dn $Computername
	if($LDAPComputer -ne $null) {
		Write-Host "$Computername $LDAPComputer"
		
		# Retrieve computer description with WMI info
		$ComputerDescription = Create-Computer-Description 
		Write-Host $ComputerDescription
		
		# Set AD Computer description field.
		if($ComputerDescription -ne $null) {
			Set-ADObj-Description $LDAPComputer $ComputerDescription	
		}				
	}
	
	# Retrieve user object in domain
	$Username = gc env:username	
	$LDAPUser = Get-Dn $Username "(&(objectCategory=User)(name=$Username))"
	if($LDAPUser -ne $null) {
		Write-Host "$Username $LDAPUser"		
		$UserObj = [adsi]$LDAPUser
		$UserDisplayName = $null
		if($UserObj -ne $null) { $UserDisplayName = $UserObj.displayName }
		if($UserDisplayName -ne $null) {
			Write-Host $UserDisplayName			
			$ComputerDisplayname = $Username.ToUpper() + "; " + $UserDisplayName
			Set-ADObj-Displayname $LDAPComputer $ComputerDisplayname
		}
	}
	
	
	
}