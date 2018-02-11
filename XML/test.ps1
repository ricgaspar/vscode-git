function Write-CMLogEntry {
	param(
		[parameter(Mandatory=$true, HelpMessage="Value added to the smsts.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
 
        [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("1", "2", "3")]
        [string]$Severity,
 
		[parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "VNB-OSD-Configure-Service.log"
	)
    # Determine log file location
    $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName
 
    # Construct time stamp for log entry
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
 
    # Construct date for log entry
    $Date = (Get-Date -Format "MM-dd-yyyy")
 
    # Construct context for log entry
    $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
 
    # Construct final log entry
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""DynamicApplicationsList"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
     
    # Add value to log file
    try {
    	Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
		Write-Host $Value
	}
    catch [System.Exception] {
    	Write-Warning -Message "Unable to append log entry to smsts.log file"
	}
}

Function Get-ApplicationID {
	Param (
		[Parameter(Mandatory=$True)]
		[xml]$XML
	)	
	begin {
		Write-CMLogEntry "Determine highest application ID." -severity 1
	}
	process {
		$HID = 0
		try {
			foreach ($Apps in $Xml.Applications.ChildNodes) {
				foreach($Application in $Apps.ChildNodes) {				
					$AppId = [int]($Application.Id)
					if ($AppId -gt $HID) { $HID = $AppID }							
				}
			}
			Write-CMLogEntry "Found highest application ID: $($HID)" -severity 1
		}
		catch {
			Write-CMLogEntry "An error occured while reading application ID's" -severity 3
		}
		$HID
	}
}

Function Test-ApplicationID {
	[CmdletBinding()]
	Param (
		[xml]$XML,
		[string]$Name
	)	
	begin {
		Write-CMLogEntry "Searching application: '$($Name)'" -severity 1
	}
	process {
		$IdFound = $null
		try {		
			$IdFound = $AppsXML.Applications.ApplicationGroup.Application | ? { $_.Name -eq $AppDesc }
			if ($IdFound -eq $null) { 
				Write-CMLogEntry "The application was not found." -severity 1
			} else {
				Write-CMLogEntry "The application was found with ID: $($IdFound.Id)" -severity 1
			}
		}
		catch {
			Write-CMLogEntry "An error occured while searching for an application." -severity 3
		}
		$IdFound
	}
}

Function New-ApplicationGroup {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[xml]$XML,
		
		[Parameter(Mandatory=$True)]
		[string]$Name		
	)
	begin {
		Write-CMLogEntry "Creating application group: '$($Name)'" -severity 1
	}
	process {
		$FoundGroup = $null
		try {
			$FoundGroup = $AppsXML.Applications.ApplicationGroup | ? { $_.Name -eq $ADAppGroupName} 
			if($FoundGroup -eq $null) {				
				$NewAppGroup = $AppsXML.CreateElement("ApplicationGroup")
				$NewAppGroup.SetAttribute('Name', $ADAppGroupName)
				$FoundGroup = $NewAppGroup
			} else {
				Write-CMLogEntry "The application group already exists." -severity 1
			}
		}
		catch {
			Write-CMLogEntry "An error occured while creating a new application group." -severity 3
		}
		$FoundGroup
	}
}

Function New-SelectedApplication {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[xml]$XML,
		
		[Parameter(Mandatory=$True)]
		[int]$ID
	)
	
	begin {
		Write-CMLogEntry "Adding preselected application ID '$($Id)'" -severity 1
	}
	process {
		$FoundSelect = $null
		try {
			$FoundSelect = $XML.Applications.SelectedApplications
			if($FoundSelect) {
				Write-CMLogEntry "Selected applications element was found." -severity 1					
				$FoundSelectID = $FoundSelect.SelectApplication | ? { $_.'Application.Id' -eq $ID }
				if($FoundSelectID -ne $null) {
					Write-CMLogEntry "The application Id '$ID' was already selected. No need to add." -severity 1	
				} else {					
					Write-CMLogEntry "The application Id '$ID' was not found in the list of selected applications." -severity 1	
					Write-CMLogEntry "Adding application Id '$ID' to the list of selected applications." -severity 1	
					# create new SelectedApplication
					$NewSelectApplication = $XML.CreateElement("SelectApplication")
					$NewSelectApplication.SetAttribute('Application.Id', $ID)
					# Add SelectApplication to SelectedApplications
					[Void]($XML.Applications.SelectedApplications.AppendChild($NewSelectApplication))				
				}
			} else {
				Write-CMLogEntry "Creating selected applications element." -severity 1
				# Create new SelectedApplications element
				$RootElement = $XML.Applications
				$NewSelectedApplications = $AppsXML.CreateElement("SelectedApplications")
				
				Write-CMLogEntry "Adding application Id '$ID' to the list of selected applications." -severity 1
				# create new SelectApplication
				$NewSelectApplication = $AppsXML.CreateElement("SelectApplication")
				$NewSelectApplication.SetAttribute('Application.Id', $ID)				
				# Add SelectApplication to SelectedApplications
				[Void]($NewSelectedApplications.AppendChild($NewSelectApplication))				
				# Add SelectedApplications to Applications
				
				[Void]($RootElement.AppendChild($NewSelectedApplications))				
			}
			$XML
		}
		catch {
			Write-CMLogEntry "An error occured while accessing selected applications element." -severity 3
			$XML
		}
	}	
}

Function Get-TSEnvComputerName {
	Begin {
		# Construct TSEnvironment object
    	try {
        	$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    	}
    	catch [System.Exception] {
        	Write-CMLogEntry -Value "Unable to construct Microsoft.SMS.TSEnvironment object" -Severity 1			
    	}
	}	
	Process {
		if($TSEnvironment) {
			# Retrieve the computer name
			Write-CMLogEntry -Value "Retrieve computer name from TS OSDComputername" -Severity 1
    		$ComputerName = $TSEnvironment.Value("OSDComputerName")
    		if($ComputerName -eq "") { 
				Write-CMLogEntry -Value "OSDComputerName was empty" -Severity 1
				Write-CMLogEntry -Value "Retrieve computer name from _SMSTSMachineName" -Severity 1
				$ComputerName = $TSEnvironment.Value("_SMSTSMachineName") 
			}
    		Write-CMLogEntry -Value "Computername: $Computername" -Severity 1
			$ComputerName
		} else {
			$null
		}
	}
}

Function Get-SCCMSiteCode {
	[CmdletBinding()]
    Param (
		[Parameter(Mandatory=$True)]
		$SiteServer         
    )	
	Try {        		
		# Enable terminating error with ErrorAction
		$providerLocation = gcim -ComputerName $siteServerName -Namespace root\sms SMS_ProviderLocation -filter "ProviderForLocalSite='True'" -ErrorAction Stop
		$providerLocation.SiteCode
    }
    Catch {	
		# Catch terminating error
		$ErrorMessage = $_.Exception.Message
    	$FailedItem = $_.Exception.ItemName
		Write-CMLogEntry "ERROR $FailedItem $ErrorMessage" -Severity 3
		exit $null
    }
}

Function Get-SCCMApplicationData {
	process {
		$ApplicationData = $null
		try {
			$SiteServerName = 'S007'
			$SiteCode = Get-SCCMSiteCode -SiteServer $SiteServerName
			Write-CMLogEntry -Value "SCCM Site code: $SiteCode" -Severity 1
			$ApplicationData = Get-WmiObject SMS_ApplicationLatest -Namespace "root\SMS\site_$SiteCode" -ComputerName $SiteServerName | ?{$_.IsLatest -eq $true}
		}
		catch {
			Write-CMLogEntry -Value "ERROR: an error occured while accessing SCCM server." -Severity 3
		}
		$ApplicationData
	}
}

Function Get-ComputerApplications {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[string]$ComputerName,
				
		[Parameter(Mandatory=$True)]
		# Each group name must start with this prefix
		[string]$Prefix = "SCCM_Deploy", 
		
		# We do not use a suffix in the application name so it is not mandatory but still usable
		[string]$Suffix = ""    
	)	
	Begin {
		try {
    		# Search Active Directory for this computer name
    		$ADObjectDN = ([ADSISEARCHER]"samaccountname=$($ComputerName)`$").Findone().Properties.distinguishedname
			# Find all groups to which this computer is a member of
			$AllGroups =([ADSISEARCHER]"member:1.2.840.113556.1.4.1941:=$ADObjectDN").FindAll() 
		}
		catch {
			Write-CMLogEntry -Value "Error while accessing Active Directory." -Severity 3 ;	exit $null
		}
	}
	Process {    			
    	# Filter the groups from the list whe need and retrieve the description field
    	$DescList = $AllGroups.Path `
        	| Where { ($_ -replace '^LDAP://CN=([^,]+).+$','$1').StartsWith($Prefix) -and ($_ -replace '^LDAP://CN=([^,]+).+$','$1').EndsWith($Suffix) } `
        	| Foreach { ([ADSI]"$_").Description }
		$DescList
	}
}

Function Get-TSEnvApplicationList {
	Begin {
		# Construct TSEnvironment object
    	try {
        	$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    	}
    	catch [System.Exception] {
        	Write-CMLogEntry -Value "Unable to construct Microsoft.SMS.TSEnvironment object" -Severity 1			
    	}
	}	
	Process {
		if($TSEnvironment) {			
			Write-CMLogEntry -Value "Retrieve application list from TS OSDComputername" -Severity 1
    		$ApplicationListXML = [xml]($TSEnvironment.Value("ApplicationList"))
    		if($ApplicationListXML -eq "") { 
				Write-CMLogEntry -Value "ApplicationList was empty" -Severity 1				
			}    		
			$ApplicationListXML
		} else {
			$null
		}
	}
}

Function Set-TSEnvApplicationList {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[xml]$XML	
	)
	Begin {
		# Construct TSEnvironment object
    	try {
        	$TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    	}
    	catch [System.Exception] {
        	Write-CMLogEntry -Value "Unable to construct Microsoft.SMS.TSEnvironment object" -Severity 1			
    	}
	}	
	Process {
		if($TSEnvironment) {			
			Write-CMLogEntry -Value "Set TS environment variable ApplicationList." -Severity 1
    		$ApplicationListXML = [xml]($TSEnvironment.Value("ApplicationList"))
    		if($ApplicationListXML -eq "") { 				
				$tsenv.Value("ApplicationList") = $XML
			}    					
		} else {
			$null
		}
	}
}

#----------------------------------------------------
cls
$ComputerName = Get-TSEnvComputerName
$ComputerName = 'VDLNCHPV01801'
Write-CMLogEntry -Value "Computername: $ComputerName" -Severity 1

$ApplicationData = Get-SCCMApplicationData
Write-CMLogEntry -Value "Retrieved applications from SCCM: $($ApplicationData.Count) applications" -Severity 1

$Prefix = "SCCM_Deploy"
$ADApplicationList = Get-ComputerApplications -Computername $ComputerName -Prefix $Prefix

# Read the input file if we found AD applications
if($ADApplicationList) { 
	$AppsXML = Get-TSEnvApplicationList
}
	
ForEach ($AppDesc in $ADApplicationList) {
	Write-CMLogEntry -Value "Found AD application: $AppDesc" -Severity 1
	$SCCMAppData = $ApplicationData | Where-Object { $_.LocalizedDisplayName -eq $AppDesc } | Select CI_ID,ModelName,LocalizedDisplayName
	
	if($SCCMAppData) {
		$AppGuid = $SCCMAppData.ModelName	
		$AppDesc = $SCCMAppData.LocalizedDisplayName		
		Write-CMLogEntry -Value "Found application GUID: $AppGuid" -Severity 1
	}				
		
	# What is the highest Application ID in the XML
	$Id = Get-ApplicationID -XML $AppsXML	

	# Create new Application Group
	$ADAppGroupName = 'Active Directory based applications'
	$NewAppGroup = New-ApplicationGroup -XML $AppsXML -Name $ADAppGroupName

	# First, check if the application is already registered in the XML
	$FoundID = Test-ApplicationID -XML $AppsXML -Name $AppDesc
	if( $FoundID -eq $null ) {	
		# Increment the application ID by one.
		$Id++

		# Create a new Application in Application Group
		$NewApplication = $AppsXML.CreateElement("Application")
		$NewApplication.SetAttribute('DisplayName', $AppDesc)
		$NewApplication.SetAttribute('Name', $AppDesc)
		$NewApplication.SetAttribute('Id', $Id)
		$NewApplication.SetAttribute('Guid', $($AppGuid))

		# Create Setter and append to Application element
		$NewAppSetter = $AppsXML.CreateElement("Setter")
		$NewAppSetter.SetAttribute('Property', 'description')
		[Void]($NewApplication.AppendChild($NewAppSetter))

		# Create Dependencies and append to Application element
		$NewAppDependencies = $AppsXML.CreateElement("Dependencies")
		[Void]($NewApplication.AppendChild($NewAppDependencies))
		$NewAppFilters = $AppsXML.CreateElement("Filters")
		[Void]($NewApplication.AppendChild($NewAppFilters))

		# Create Application Mappings 
		$NewAppApplicationMappings = $AppsXML.CreateElement("ApplicationMappings")

		# Create WMI Match within Application Mappings
		$NewMatch = $AppsXML.CreateElement("Match")
		$NewMatch.SetAttribute('Type', 'WMI')
		$NewMatch.SetAttribute('OperatorCondition', 'OR')
		$NewMatch.SetAttribute('DisplayName', $AppDesc)

		# Create Setter withing Match
		$NewMatchSetter = $AppsXML.CreateElement("Setter")
		$NewMatchSetter.SetAttribute('Property', 'Name')
		$NewMatchSetter.set_InnerText($AppDesc)
		[Void]($NewMatch.AppendChild($NewMatchSetter))

		# Append Match to Application Mappings element
		[Void]($NewAppApplicationMappings.AppendChild($NewMatch))

		# Create WMI Match within Application Mappings
		$NewMatch = $AppsXML.CreateElement("Match")
		$NewMatch.SetAttribute('Type', 'MSI')
		$NewMatch.SetAttribute('OperatorCondition', 'OR')
		$NewMatch.SetAttribute('DisplayName', $AppDesc)

		# Create Setter withing Match
		$NewMatchSetter = $AppsXML.CreateElement("Setter")
		$NewMatchSetter.SetAttribute('Property', 'ProductId')
		$NewMatchSetter.set_InnerText('')
		[Void]($NewMatch.AppendChild($NewMatchSetter))

		# Append Match to Application Mappings element
		[Void]($NewAppApplicationMappings.AppendChild($NewMatch))

		# Append Mappings to Application
		[Void]($NewApplication.AppendChild($NewAppApplicationMappings))

		# Add Application to Application Group
		[Void]($NewAppGroup.AppendChild($NewApplication))
	
		# Add Application Group to Applications
		[Void]($AppsXML.Applications.AppendChild($NewAppGroup))
		
		# Update XML with selected application element
		$AppsXML = New-SelectedApplication -XML $AppsXML -Id $Id			
	
	} else {
		Write-Host "Application '$AppDesc' was already registered as a selectable application."
	
		# Update XML with selected application element
		$AppsXML = New-SelectedApplication -XML $AppsXML -Id $FoundId.Id
	}
} 

# And save the new XML if we found AD applications
if($ADApplicationList) { 
	Set-TSEnvApplicationList -xml $AppsXML
}