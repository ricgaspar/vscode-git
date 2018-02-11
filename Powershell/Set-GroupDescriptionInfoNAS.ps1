# ---------------------------------------------------------
#
# Set group descriptions for domain groups related to
# the NedCar NAS servers S171 and S172
# Marcel Jussen
# 13-12-2011
#
# ---------------------------------------------------------
cls
# ---------------------------------------------------------
# Pre-defined variables
$Global:SECDUMP_SQLServer = "s001.nedcar.nl"
$Global:SECDUMP_SQLDB = "secdump"

# ---------------------------------------------------------
# Includes
. C:\Scripts\Secdump\PS\libLog.ps1
. C:\Scripts\Secdump\PS\libAD.ps1
. C:\Scripts\Secdump\PS\libSQL.ps1

# ---------------------------------------------------------
$VbCrLf = "`r`n"  

# ---------------------------------------------------------
$ScriptName = $myInvocation.MyCommand.Name
Init-Log -LogFileName "Secdump-$ScriptName"
Echo-Log "Started script $ScriptName"  

# $groupname = "3150Scan-Update"
# $filter = "(&(objectCategory=Group)(name=$groupname))"
# $proplist = "name"
# $result = Search-AD $filter $proplist
# if ($result -ne $null) { ForEach($rec in $result) { $DN = $rec.Path } }
# Set-ADGroup-Description $DN
# Set-ADGroup-Info $DN
# return

Function Modify-ADGroup-NASDescription {
	param (
		[string]$DN, 
		[string]$Group,
		[string]$Servername,
		[string]$Share
	)
	
	if($DN -eq $null) { return $null }
	
	$now = Get-Date
	$date = $now.ToShortDateString()
  	$Description = "(NAS) [$date] " + $Share.ToUpper()
  	$OldDescription = Get-ADGroup-Description $DN
  	If ($OldDescription -ne $null) {
		$OldDescription = $OldDescription.ToUpper()
    	If ($OldDescription.contains("(NAS)")) {
      	# Check if share is already mention in the description field
      		If ($OldDescription.contains($Share.ToUpper())) {
        		# Do nothing
      		} Else {
        		# Add share to existing NAS description
        		Echo-Log "Add share name to description field"
        		$Description = $OldDescription + ", " + $Share.ToUpper()
        		Set-ADGroup-Description $DN $Description 
      		}
    	} Else {
      		# NAS description not found so set default
      		Echo-Log "Set default NAS description."
      		SetGroupDescription $DN $Description
		}
	} else {    
		# No description was found so set the default.
    	Echo-Log "Description was empty. Setting default."
    	Set-ADGroup-Description $DN $Description
	}
  	return $null
}

Function Modify-ADGroup-NASInfo {
	param (
		$DN, 
		$Group, 
		$Servername, 
		$Share
	)
  	$Info = "NTFS trustee : \\" + $Servername + "\" + $Share 
  	$OldInfo = Get-ADGroup-Info $DN
  	If($OldInfo.Length -gt 0) {
    	# Check if share is already mention in the info field
    	If ($OldInfo.contains($Info)) {
      		# Do nothing
    	} Else {
      		$Info = $OldInfo + $vbCrLF + $Info
      		Set-ADGroup-Info $DN $Info
    	}
  	} Else {
    	Set-ADGroup-Info $DN $Info
  	}
	return $null
}

# ---------------------------------------------------------
# Open SQL Connection (connection name is script name)
$conn = New-SQLconnection $Global:SECDUMP_SQLServer $Global:SECDUMP_SQLDB
if ($conn.state -eq "Closed") { exit }

$query = "exec QRY_DOMAIN_GROUPS_NAS_TOCLEAR"
$data = Query-SQL $query $conn

# Uncomment the line below to activate the procedure
$data = $null

if ($data -ne $null) {
	ForEach($record in $data) {
		$groupname = $record.groupname
		$groupname = $groupname.Replace("NEDCAR\", "")
		$filter = "(&(objectCategory=Group)(name=$groupname))"
		$proplist = "name"
		$result = Search-AD $filter $proplist
		if ($result -ne $null) {
			ForEach($rec in $result) { $DN = $rec.Path }
			If ($DN -ne $null) {
				Echo-Log "Clearing description and info fields of $DN"
				Set-ADGroup-Description $DN
				Set-ADGroup-Info $DN
			} else {
				Echo-Log "Error: cannot find $groupname"
			}
		}
	}
}

$query = "exec QRY_DOMAIN_GROUPS_NAS"
$data = Query-SQL $query $conn

# Uncomment the line below to activate the procedure
$data = $null

$servername = "NEDCAR.NL\Office"
if ($data -ne $null) {
	ForEach($record in $data) {
		$groupname = $record.groupname
		$groupname = $groupname.Trim()
		$sharename = $record.sharename
		$sharename = $sharename.Trim()
		$groupname = $groupname.Replace("NEDCAR\", "")
		$filter = "(&(objectCategory=Group)(name=$groupname))"
		$proplist = "name"
		$result = Search-AD $filter $proplist
		if ($result -ne $null) {
			ForEach($rec in $result) { $DN = $rec.Path }
			If ($DN -ne $null) {	
				Echo-Log "Setting description and info text fields of $DN"
				Modify-ADGroup-NASDescription $DN $groupname $servername $sharename					
				Modify-ADGroup-NASInfo $DN $groupname $servername $sharename
			} else {
				Echo-Log "Error: cannot find $groupname"
			}
		}
	}
}

Remove-SQLconnection $conn
Echo-Log "End script $ScriptName"
# ---------------------------------------------------------