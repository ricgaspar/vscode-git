<#
 .NOTES
 ===========================================================================
 Created with: SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.128
 Created on: 16/10/2016 13:00
 Created by: Maurice Daly
 Filename: DellDownloads.ps1
 ===========================================================================
 .DESCRIPTION
 This script allows you to automate the process of keeping your Dell
 driver and BIOS update sources up to date. The script reads the Dell
 SCCM driver pack site for models you have specified and then downloads
 the corresponding latest driver packs and BIOS updates.

 Version 1.0
 -Retreive Dell models and download BIOS and Driver Packs
 Version 2.0
 -Added driver CAB file extract, create new driver pack, category creation
  and import driver functions.
 Version 2.1
 -Added multi-threading
 Version 2.2
 -Added Max Concurrent jobs setting for limiting CPU utilisation
 Version 2.3
 -Replaced Invoke-WebRequest download with BITS enabled downloads for
  improved performance
 Version 2.4
 -Updated code and separated functions. Added required variables via commandline
 Version 3.0
 -Creates BIOS Packages for each model and writes update powershell file for deployment
  with SCCM.
 Version 4.0
 -Added support for MDT driver imports
 -Added operating system selection into the command line
 -Option to skip BIOS downloads
 -Validation for OS driver pack download for each model

 .EXAMPLE
 In the below example the script will run the download and import process for both SCCM and MDT. Both sets of BIOS and Driver packages will be downloaded, in this instance for Windows 10 x64

 DellDownloads.ps1 -ImportInto Both -DownloadType All -SiteServer YourSiteServer -RepositoryPath \\SERVER\Drivers -PackagePath \\SERVER\DriverPacks -WindowsVersion 10 -Architecture x64
 
 In this example the script will run the download and import process for MDT only. Only the Driver packages will be downloaded, in this instance for Windows 10 x64. Note that you will be 
 prompted for a path to a CSV containing the models you wish to download drivers for.

 DellDownloads.ps1 -ImportInto MDT -DownloadType Drivers -RepositoryPath \\SERVER\Drivers -WindowsVersion 10 -Architecture x64 -MDTCSVSource ".\MDTModels.csv"
 

 Use : This script is provided as it and I accept no responsibility for any issues arising from its use.

 Twitter : @modaly_it
 Blog : https://modalyitblog.com/
 
 Credits
	MDT Import Script Source - https://scriptimus.wordpress.com/2012/06/18/mdt-powershell-importing-drivers/
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
	[parameter(Mandatory = $true, HelpMessage = "Import drivers into which product? SCCM, MDT or Both?", Position = 1)]
	[ValidateSet("SCCM", "MDT", "Both")]
	[String]$ImportInto,
	[parameter(Mandatory = $true, HelpMessage = "Download both BIOS & driver packages or just drivers?", Position = 2)]
	[ValidateSet("All", "Drivers")]
	[String]$DownloadType,
	[parameter(Mandatory = $false, HelpMessage = "Site server where the SMS Provider is installed", Position = 3)]
	[ValidateNotNullOrEmpty()]
	[ValidateScript({ Test-Connection -ComputerName $_ -Count 1 -Quiet })]
	[string]$SiteServer,
	[parameter(Mandatory = $true, HelpMessage = "UNC path for downloading and extracting drivers", Position = 4)]
	[ValidateNotNullOrEmpty()]
	[ValidateScript({ Test-Path $_ })]
	[string]$RepositoryPath,
	[parameter(Mandatory = $false, HelpMessage = "UNC path of your driver package repository", Position = 5)]
	[ValidateNotNullOrEmpty()]
	[ValidateScript({ Test-Path $_ })]
	[string]$PackagePath,
	[parameter(Mandatory = $false, HelpMessage = "Source path to the CSV containing your list of models for MDT", Position = 6)]
	[ValidateNotNullOrEmpty()]
	[ValidateScript({ Test-Path $_ })]
	[string]$MDTCSVSource,
	[parameter(Mandatory = $true, HelpMessage = "Please select an operating system", Position = 7)]
	[ValidateSet("7", "8", "8.1", "10")]
	[String]$WindowsVersion,
	[parameter(Mandatory = $true, HelpMessage = "Please select an operating system", Position = 8)]
	[ValidateSet("x86", "x64")]
	[String]$Architecture,
	[parameter(Mandatory = $false, HelpMessage = "Set the maximum number of current jobs", Position = 9)]
	[ValidateSet("1", "2", "3", "4", "5")]
	[String]$MaxConcurrentJobs
)

Clear-Host

# Import SCCM PowerShell Module
$ModuleName = (get-item $env:SMS_ADMIN_UI_PATH).parent.FullName + "\ConfigurationManager.psd1"
Import-Module $ModuleName

# Defaults maximum concurrent jobs to 3 if the value is not set in the commandline
if ($MaxConcurrentJobs -eq $null)
{
	$MaxConcurrentJobs = 5
}

# Query SCCM Site Code
function QuerySiteCode ($SiteServer)
{
	Write-Debug "Determining SiteCode for Site Server: '$($SiteServer)'"
	$SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
	foreach ($SiteCodeObject in $SiteCodeObjects)
	{
		if ($SiteCodeObject.ProviderForLocalSite -eq $true)
		{
			$SiteCode = $SiteCodeObject.SiteCode
			Write-Debug "SiteCode: $($SiteCode)"
			
		}
	}
	Return [string]$SiteCode
}

function QueryModels ($SiteCode)
{
	# ArrayList to store the Dell models in
	$DellProducts = New-Object -TypeName System.Collections.ArrayList
	# Enumerate through all models
	$Models = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_G_System_COMPUTER_SYSTEM | Select-Object -Property Model | Where-Object { ($_.Model -like "*Optiplex*") -or ($_.Model -like "*Latitude*") }
	# Add model to ArrayList if not present
	if ($Models -ne $null)
	{
		foreach ($Model in $Models)
		{
			if ($Model.Model -notin $DellProducts)
			{
				$DellProducts.Add($Model.Model) | Out-Null
			}
		}
	}
	Return $DellProducts
}

function SCCMDownloadAndPackage ($PackagePath, $RepositoryPath, $SiteCode, $DellProducts, $OperatingSystem, $Architecture, $DownloadType, $ImportInto)
{
	$RunDownloadJob = {
		Param ($Model,
			$SiteCode,
			$PackagePath,
			$RepositoryPath,
			$WindowsVersion,
			$Architecture,
			$DownloadType)
		
		# =================== DEFINE VARIABLES =====================
		
		# Define Dell Download Sources
		$DellDownloadList = "http://downloads.dell.com/published/Pages/index.html"
		$DellDownloadBase = "http://downloads.dell.com"
		$DellSCCMDriverList = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/2065.dell-command-deploy-driver-packs-for-enterprise-client-os-deployment"
		$DellSCCMBase = "http://en.community.dell.com"
		
		# Import SCCM PowerShell Module
		$ModuleName = (get-item $env:SMS_ADMIN_UI_PATH).parent.FullName + "\ConfigurationManager.psd1"
		Import-Module $ModuleName
		
		# Directory used for driver downloads
		$DriverRepositoryRoot = ($RepositoryPath.Trimend("\") + "\Dell\")
		Write-Host "Driver package path set to $DriverRepositoryRoot"
		
		# Directory used by SCCM for driver package
		$DriverPackageRoot = ($PackagePath.Trimend("\") + "\Dell\")
		Write-Host "Driver package path set to $DriverPackageRoot"
		
		# ==========================================================
		# =================== INITIATE DOWNLOADS ===================
		# ==========================================================
		
		if ($DownloadType -ne "Drivers")
		{
			
			# ================= BIOS Upgrade Download ==================
			
			Write-Host "Getting download URL for Dell client model: $Model"
			$ModelLink = (Invoke-WebRequest -Uri $DellDownloadList).Links | Where-Object { $_.outerText -eq $Model }
			$ModelURL = (Split-Path $DellDownloadList -Parent) + "/" + ($ModelLink.href)
			
			# Correct slash direction issues
			$ModelURL = $ModelURL.Replace("\", "/")
			$BIOSDownload = (Invoke-WebRequest -Uri $ModelURL -UseBasicParsing).Links | Where-Object { ($_.outerHTML -like "*BIOS*") -and ($_.outerHTML -like "*WINDOWS*") } | select -First 1
			$BIOSFile = $BIOSDownload.href | Split-Path -Leaf
			
			If ($BIOSDownload -ne $null)
			{
				
				# Check for destination directory, create if required and download the BIOS upgrade file
				if ((Test-Path -Path ($DriverRepositoryRoot + $Model + "\BIOS")) -eq $true)
				{
					if ((Test-Path -Path ($DriverRepositoryRoot + $Model + "\BIOS\" + $BIOSFile)) -eq $false)
					{
						Write-Host -ForegroundColor Green "Downloading $($BIOSFile) BIOS update file"
						# Invoke-WebRequest ($DellDownloadBase + $BIOSDownload.href) -OutFile ($DriverRepositoryRoot + $Model + "\BIOS\" + $BIOSFile) -UseBasicParsing
						Start-BitsTransfer ($DellDownloadBase + $BIOSDownload.href) -Destination ($DriverRepositoryRoot + $Model + "\BIOS\" + $BIOSFile)
					}
					else
					{
						Write-Host -ForegroundColor Yellow "Skipping $BIOSFile... File already downloaded..."
					}
				}
				else
				{
					Write-Host -ForegroundColor Green "Creating $Model download folder"
					New-Item -Type dir -Path ($DriverRepositoryRoot + $Model + "\BIOS")
					Write-Host -ForegroundColor Green "Downloading $($BIOSFile) BIOS update file"
					# Invoke-WebRequest ($DellDownloadBase + $BIOSDownload.href) -OutFile ($DriverRepositoryRoot + $Model + "\BIOS\" + $BIOSFile) -UseBasicParsing
					Start-BitsTransfer ($DellDownloadBase + $BIOSDownload.href) -Destination ($DriverRepositoryRoot + $Model + "\BIOS\" + $BIOSFile)
				}
				
				# ================= Create BIOS Update Package ==================
				
				$BIOSUpdatePackage = ("Dell" + " " + $Model + " " + "BIOS UPDATE")
				$BIOSUpdateRoot = ($DriverRepositoryRoot + $Model + "\BIOS\")
				
				Set-Location -Path ($SiteCode + ":")
				if ((Get-CMPackage -name $BIOSUpdatePackage) -eq $null)
				{
					Write-Host -ForegroundColor Green "Creating BIOS Package"
					New-CMPackage -Name "$BIOSUpdatePackage" -Path $BIOSUpdateRoot -Description "Dell $Model BIOS Updates" -Manufacturer "Dell" -Language English
				}
				Set-Location -Path $env:SystemDrive
				$BIOSUpdateScript = ($BIOSUpdateRoot + "BIOSUpdate.ps1")
				$CurrentBIOSFile = Get-ChildItem -Path $BIOSUpdateRoot -Filter *.exe -Recurse | Sort-Object $_.LastWriteTime | select -First 1
				if ((Test-Path -Path $BIOSUpdateScript) -eq $False)
				{
					# Create BIOSUpdate.ps1 Deployment Script
					New-Item -Path ($BIOSUpdateRoot + "BIOSUpdate.ps1") -ItemType File
					$BIOSSwitches = " -noreboot -nopause "
					Add-Content -Path $BIOSUpdateScript ('$CurrentBIOSFile=' + '"' + $($CurrentBIOSFile.name) + '"')
					Add-Content -Path $BIOSUpdateScript ('$BIOSSwitches=' + '"' + $($BIOSSwitches) + '"')
					Add-Content -Path $BIOSUpdateScript ('Start-Process $CurrentBIOSFile -ArgumentList $BIOSSwitches')
				}
				else
				{
					# Check if older BIOS update exists and update BIOSUpdate deployment script
					$BIOSFileCount = (Get-ChildItem -Path $BIOSUpdateRoot -Filter *.exe -Recurse).count
					if ($BIOSFileCount -gt 1)
					{
						$OldBIOSFiles = Get-ChildItem -Path $BIOSUpdateRoot -Filter *.exe -Recurse | Where-Object { $_.Name -ne $CurrentBIOSFile.name }
						
						foreach ($OldBIOS in $OldBIOSFiles)
						{
							(Get-Content -Path $BIOSUpdateScript) -replace $OldBIOS.name, $CurrentBIOSFile.name | Set-Content -Path $BIOSUpdateScript
						}
					}
				}
				
				# =============== Refresh Distribution Points =================
				Set-Location -Path ($SiteCode + ":")
				Get-CMPackage -name $BIOSUpdatePackage | Update-CMDistributionPoint
				Set-Location -Path $env:SystemDrive
			}
			
		}
		
		# =============== SCCM Driver Cab Download =================
		
		Write-Host "Getting SCCM driver pack link for model: $Model"
		$ModelLink = (Invoke-WebRequest -Uri $DellSCCMDriverList -UseBasicParsing).Links | Where-Object { ($_.outerHTML -like "*$Model*") -and ($_.outerHTML -like "*$OperatingSystem*") } | select -First 1
		$ModelURL = $DellSCCMBase + ($ModelLink.href)
		
		If ($ModelURL -ne $null)
		{
			$ModelURL = $ModelURL.Replace("\", "/")
			$SCCMDriverDownload = (Invoke-WebRequest -Uri $ModelURL -UseBasicParsing).Links | Where-Object { $_.href -like "*.cab" }
			$SCCMDriverCab = $SCCMDriverDownload.href | Split-Path -Leaf
			$DriverSourceCab = ($DriverRepositoryRoot + $Model + "\Driver Cab\" + $SCCMDriverCab)
			$DriverPackageDir = ($DriverSourceCab | Split-Path -Leaf)
			$DriverPackageDir = $DriverPackageDir.Substring(0, $DriverPackageDir.length - 4)
			$DriverCabDest = $DriverPackageRoot + $DriverPackageDir
			$DriverRevision = ($DriverPackageDir).Split("-")[2]
			$DriverCategoryName = (('"' + 'Dell ' + $Model + '"') + "," + ("$DriverRevision"))
			$DriverExtractDest = ($DriverRepositoryRoot + $Model + "\" + $DriverRevision)
			
			# Check for destination directory, create if required and download the driver cab
			if ((Test-Path -Path ($DriverRepositoryRoot + $Model + "\Driver Cab\" + $SCCMDriverCab)) -eq $false)
			{
				Write-Host -ForegroundColor Green "Creating $Model download folder"
				New-Item -Type dir -Path ($DriverRepositoryRoot + $Model + "\Driver Cab")
				Write-Host -ForegroundColor Green "Downloading $($SCCMDriverCab) driver cab file"
				Start-BitsTransfer -Source ($SCCMDriverDownload.href) -Destination ($DriverRepositoryRoot + $Model + "\Driver Cab\" + $SCCMDriverCab)
			}
			else
			{
				Write-Host -ForegroundColor Yellow "Skipping $SCCMDriverCab... Driver pack already downloaded..."
				$SkipDriverImport = $True
			}
			
			# =============== Create Driver Package + Import Drivers =================
			
			if ((Test-Path -Path ($DriverCabDest)) -eq $false)
			{
				New-Item -Type dir -Path $DriverExtractDest
				New-Item -Type dir -Path $DriverCabDest
				Set-Location -Path ($SiteCode + ":")
				$CMDDriverPackage = ("Dell " + $Model + " - " + $OperatingSystem + " " + $Architecture)
				Write-Host -ForegroundColor Green "Creating driver package"
				Set-Location -Path $env:SystemDrive
				Expand "$DriverSourceCab" -F:* "$DriverExtractDest"
				$DriverINFFiles = Get-ChildItem -Path $DriverExtractDest -Recurse -Filter "*.inf" | Where-Object { $_.FullName -like "*$Architecture*" }
				Set-Location -Path ($SiteCode + ":")
				if (Get-CMCategory -CategoryType DriverCategories -name $DriverCategoryName)
				{
					Write-Host -ForegroundColor Yellow "Category already exists"
					$DriverCategory = Get-CMCategory -CategoryType DriverCategories -name $DriverCategoryName
				}
				else
				{
					Write-Host -ForegroundColor Green "Creating category"
					$DriverCategory = New-CMCategory -CategoryType DriverCategories -name $DriverCategoryName
				}
				Write-Host -ForegroundColor Green "Creating Driver Package for Dell $Model"
				New-CMDriverPackage -Name $CMDDriverPackage -path ($DriverPackageRoot + $DriverPackageDir + "\" + $Architecture)
				Set-CMDriverPackage -Name $CMDDriverPackage -Version $DriverRevision
				$DriverPackage = Get-CMDriverPackage -Name $CMDDriverPackage
				foreach ($DriverINF in $DriverINFFiles)
				{
					$DriverInfo = Import-CMDriver -UncFileLocation ($DriverINF.FullName) -ImportDuplicateDriverOption AppendCategory -EnableAndAllowInstall $True -AdministrativeCategory $DriverCategory | Select-Object *
					Add-CMDriverToDriverPackage -DriverID $DriverInfo.CI_ID -DriverPackageName "$($CMDDriverPackage)" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
				}
			}
			else
			{
				Write-Host -ForegroundColor Yellow "Driver Package Already Exists.. Skipping"
			}
			Set-Location -Path $env:SystemDrive
		}
		else
		{
			Write-Host -ForegroundColor Red "Operating system driver package download path not found.. Skipping $Model"
		}
		
	}
	
	# Operating System Version
	$OperatingSystem = ("Windows " + $WindowsVersion)
	$TotalModelCount = $DellProducts.Count
	$RemainingModels = $TotalModelCount
	foreach ($Model in $DellProducts)
	{
		Write-Progress -activity "Initiate Driver Download & Driver Package Jobs" -status "Progress:" -percentcomplete (($TotalModelCount - $RemainingModels)/$TotalModelCount * 100)
		$RemainingModels--
		$Check = $false
		while ($Check -eq $false)
		{
			if ((Get-Job -State 'Running').Count -lt $MaxConcurrentJobs)
			{
				Start-Job -ScriptBlock $RunDownloadJob -ArgumentList $Model, $SiteCode, $PackagePath, $RepositoryPath, $OperatingSystem, $Architecture, $DownloadType -Name ($Model + " Download")
				$Check = $true
			}
		}
	}
	Get-Job | Wait-Job | Receive-Job
	Get-Job | Remove-Job
	
	if ($ImportInto -eq "Both")
	{
		# =============== MDT Driver Import ====================
		Write-Host -ForegroundColor Green "Starting MDT Driver Import Process"
		
		# Import MDT Module
		Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
		
		# Detect First MDT PSDrive
		If (!$PSDriveName) { $PSDriveName = (Get-MDTPersistentDrive)[0].name }
		
		# Detect First MDT Deployment Share
		If (!$DeploymentShare) { $DeploymentShare = (Get-MDTPersistentDrive)[0].path }
		
		$MDTDriverPath = $PSDriveName + ':\Out-of-Box Drivers'
		$MDTSelectionProfilePath = $PSDriveName + ':\Selection Profiles'
		
		# Connect to Deployment Share
		If ((Get-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue) -eq $false)
		{
			New-PSDrive -Name $PSDriveName -PSProvider MDTProvider -Root $DeploymentShare
		}
		
		$Make = "Dell"
		$OperatingSystemDir = ("Windows " + $WindowsVersion + " " + $Architecture)
		
		# Get full list of available driver cab folders from downloaded content and import into MDT if not already imported 
		Get-ChildItem ($RepositoryPath + "\" + $Make) -Recurse | Where-Object { ($_.PSIsContainer -eq $true) -and ($_.FullName -like "*Driver Cab*") } | foreach {
			$Model = (($_.FullName | Split-Path -Parent) | Split-Path -Leaf)
			$DriverRevision = ((Get-ChildItem -Path $_.FullName -Filter *.Cab).Name).Split("-")[2]
			if ((Test-Path $MDTDriverPath\$OperatingSystemDir) -eq $false)
			{
				New-Item -path $MDTDriverPath -enable "True" -Name $OperatingSystemDir -ItemType "folder" -Verbose
			}
			
			if (!(Test-Path $MDTSelectionProfilePath"\Drivers - "$OperatingSystemDir))
			{
				New-Item -path $MDTSelectionProfilePath -enable "True" -Name "Drivers - $OperatingSystemDir" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\$OS`" /></SelectionProfile>" -ReadOnly "False" -Verbose
			}
			if ((Test-Path $MDTDriverPath\$OperatingSystemDir\$Make) -eq $false)
			{
				New-Item -path $MDTDriverPath\$OperatingSystemDir -enable "True" -Name $Make -ItemType "folder" -Verbose
			}
			if ((Test-Path $MDTDriverPath\$OperatingSystemDir\$Make\$Model) -eq $false)
			{
				New-Item -path $MDTDriverPath\$OperatingSystemDir\$Make -enable "True" -Name $Model -ItemType "folder" -Verbose
			}
			if ((Test-Path $MDTDriverPath\$OperatingSystemDir\$Make\$Model\$DriverRevision) -eq $false)
			{
				New-Item -path $MDTDriverPath\$OperatingSystemDir\$Make\$Model -enable "True" -Name $DriverRevision -ItemType "folder" -Verbose
				Write-Host -ForegroundColor Green "Importing MDT driver pack for $Make $Model - Revision $DriverRevision"
				Import-MDTDriver -path $MDTDriverPath\$OperatingSystemDir\$Make\$Model\$DriverRevision -Source $_.FullName
			}
			else
			{
				Write-Host -ForegroundColor Yellow "MDT driver pack already exists.. Skipping.."
			}
		}
	}
}

function MDTDownloadAndImport ($RepositoryPath, $DellProducts, $WindowsVersion, $Architecture)
{
	# Import MDT Module
	Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
	
	# Detect First MDT PSDrive
	If (!$PSDriveName) { $PSDriveName = (Get-MDTPersistentDrive)[0].name }
	
	# Detect First MDT Deployment Share
	If (!$DeploymentShare) { $DeploymentShare = (Get-MDTPersistentDrive)[0].path }
	
	$MDTDriverPath = $PSDriveName + ':\Out-of-Box Drivers'
	$MDTSelectionProfilePath = $PSDriveName + ':\Selection Profiles'
	
	# Connect to Deployment Share
	If (!(Get-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue))
	{
		New-PSDrive -Name $PSDriveName -PSProvider MDTProvider -Root $DeploymentShare
	}
	
	$DSDriverPath = $PSDriveName + ':\Out-of-Box Drivers'
	$DSSelectionProfilePath = $PSDriveName + ':\Selection Profiles'
	
	$RunMDTDownloadJob = {
		Param ($Model,
			$RepositoryPath,
			$WindowsVersion,
			$Architecture,
			$DownloadType,
			$PSDriveName,
			$DeploymentShare,
			$DSDriverPath,
			$DSSelectionProfilePath)
		
		# =================== DEFINE VARIABLES =====================
		
		# Define Dell Download Sources
		$DellDownloadList = "http://downloads.dell.com/published/Pages/index.html"
		$DellDownloadBase = "http://downloads.dell.com"
		$DellMDTDriverList = "http://en.community.dell.com/techcenter/enterprise-client/w/wiki/2065.dell-command-deploy-driver-packs-for-enterprise-client-os-deployment"
		$DellMDTBase = "http://en.community.dell.com"
		
		# Directory used for driver downloads
		$DriverRepositoryRoot = ($RepositoryPath.Trimend("\") + "\Dell\")
		Write-Host "Driver package path set to $DriverRepositoryRoot"
		
		# =============== MDT Driver Cab Download =================
		
		Write-Host "Getting MDT driver pack link for model: $Model"
		$ModelLink = (Invoke-WebRequest -Uri $DellMDTDriverList -UseBasicParsing).Links | Where-Object { ($_.outerHTML -like "*$Model*") -and ($_.outerHTML -like "*$OperatingSystem*") } | select -First 1
		$ModelURL = $DellMDTBase + ($ModelLink.href)
		
		If ($ModelURL -ne $null)
		{
			# Correct slash direction issues
			$ModelURL = $ModelURL.Replace("\", "/")
			$MDTDriverDownload = (Invoke-WebRequest -Uri $ModelURL -UseBasicParsing).Links | Where-Object { $_.href -like "*.cab" }
			$MDTDriverCab = $MDTDriverDownload.href | Split-Path -Leaf
			
			# Check for destination directory, create if required and download the driver cab
			if ((Test-Path -Path ($DriverRepositoryRoot + $Model + "\Driver Cab\" + $MDTDriverCab)) -eq $false)
			{
				if ((Test-Path -Path ($DriverRepositoryRoot + $Model + "\Driver Cab\")) -eq $false)
				{
					Write-Host -ForegroundColor Green "Creating $Model download folder"
					New-Item -Type dir -Path ($DriverRepositoryRoot + $Model + "\Driver Cab")
				}
				else
				{
					# Remove previous driver cab revisions
					Get-ChildItem -Path ($DriverRepositoryRoot + $Model + "\Driver Cab\") | Remove-Item
				}
				Write-Host -ForegroundColor Green "Downloading $($MDTDriverCab) driver cab file"
				Start-BitsTransfer -Source ($MDTDriverDownload.href) -Destination ($DriverRepositoryRoot + $Model + "\Driver Cab\" + $MDTDriverCab)
			}
			else
			{
				Write-Host -ForegroundColor Yellow "Skipping $MDTDriverCab... Driver pack already downloaded..."
			}
		}
	}
	
	$TotalModelCount = $DellProducts.Count
	$RemainingModels = $TotalModelCount

	foreach ($Model in $DellProducts)
	{
		Write-Progress -activity "Initiate MDT Driver Download & Driver Package Jobs" -status "Progress:" -percentcomplete (($TotalModelCount - $RemainingModels)/$TotalModelCount * 100)
		$RemainingModels--
		$Check = $false
		while ($Check -eq $false)
		{
			if ((Get-Job -State 'Running').Count -lt $MaxConcurrentJobs)
			{
				Start-Job -ScriptBlock $RunMDTDownloadJob -ArgumentList $Model, $RepositoryPath, $DellProducts, $WindowsVersion, $Architecture, $PSDriveName, $DeploymentShare -Name ($Model + " Driver Import")
				$Check = $true
			}
		}
	}
	Get-Job | Wait-Job | Receive-Job
	Get-Job | Remove-Job
	
	# =============== MDT Driver Import ====================
	
	$Make = "Dell"
	$OperatingSystemDir = ("Windows " + $WindowsVersion + " " + $Architecture)
	
	# Loop through folders and import Drivers
	Get-ChildItem ($RepositoryPath + "\" + $Make) -Recurse | Where-Object { ($_.PSIsContainer -eq $true) -and ($_.FullName -like "*Driver Cab*") } | foreach {
		$Model = (($_.FullName | Split-Path -Parent) | Split-Path -Leaf)
		$DriverRevision = ((Get-ChildItem -Path $_.FullName -Filter *.Cab).Name).Split("-")[2]
		if ((Test-Path $MDTDriverPath\$OperatingSystemDir) -eq $false)
		{
			New-Item -path $MDTDriverPath -enable "True" -Name $OperatingSystemDir -ItemType "folder" -Verbose
		}
		
		if ((Test-Path $MDTSelectionProfilePath"\Drivers - "$OperatingSystemDir) -eq $false)
		{
			New-Item -path $MDTSelectionProfilePath -enable "True" -Name "Drivers - $OperatingSystemDir" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\$OS`" /></SelectionProfile>" -ReadOnly "False" -Verbose
		}
		if ((Test-Path $MDTDriverPath\$OperatingSystemDir\$Make) -eq $false)
		{
			New-Item -path $MDTDriverPath\$OperatingSystemDir -enable "True" -Name $Make -ItemType "folder" -Verbose
		}
		if ((Test-Path $MDTDriverPath\$OperatingSystemDir\$Make\$Model) -eq $false)
		{
			New-Item -path $MDTDriverPath\$OperatingSystemDir\$Make -enable "True" -Name $Model -ItemType "folder" -Verbose
		}
		if ((Test-Path $MDTDriverPath\$OperatingSystemDir\$Make\$Model\$DriverRevision) -eq $false)
		{
			New-Item -path $MDTDriverPath\$OperatingSystemDir\$Make\$Model -enable "True" -Name $DriverRevision -ItemType "folder" -Verbose
			Write-Host -ForegroundColor Green "Importing MDT driver pack for $Make $Model - Revision $DriverRevision"
			Import-MDTDriver -path $MDTDriverPath\$OperatingSystemDir\$Make\$Model\$DriverRevision -Source $_.FullName
		}
		else
		{
			Write-Host -ForegroundColor Yellow "MDT driver pack already exists.. Skipping.."
		}
	}
}

if (($ImportInto -eq "SCCM") -or ($ImportInto -eq "Both"))
{
	if (($PackagePath -eq $null) -or ($SiteServer -eq $null))
	{
		Write-Host -ForegroundColor "A required parameter was not included in the commandline. Please check the Package Path and Site Server variables"
		Break
	}
	
	# Get SCCM Site Code
	$SiteCode = QuerySiteCode ($SiteServer)
	
	Write-Debug $PackagePath
	Write-Debug $RepositoryPath
	
	if ($SiteCode -ne $null)
	{
		# Query Dell Products in SCCM using QueryModels function
		$DellProducts = QueryModels ($SiteCode)
		# Output the members of the ArrayList
		if ($DellProducts.Count -ge 1)
		{
			foreach ($ModelItem in $DellProducts)
			{
				$PSObject = [PSCustomObject]@{
					"Dell Models Found" = $ModelItem
				}
				Write-Output $PSObject
				Write-Debug $PSObject
			}
		}
		# Start download, extract, import and package process
		Write-Host " "
		Write-Host "================================================================================================="
		Write-Host "==   	                                                                                         "
		Write-Host "==    Dell SCCM/MDT Driver Download & Import Script - By Maurice Daly                            "
		Write-Host "==   	                                                                                         "
		Write-Host "==    Running download, extract and import processes with the following variables;               "
		Write-Host "==    1.Import Drivers into:      $($ImportInto)                                                 "
		Write-Host "==    2.Download BIOS or Drivers: $($DownloadType)                                               "
		Write-Host "==    3.SCCM Site Server:         $($SiteServer)                                                 "
		Write-Host "==    4.SCCM Site Code:           $($SiteCode)                                                   "
		Write-Host "==    5.Driver Respository:       $($RepositoryPath)                                             "
		Write-Host "==    6.Package Destination:      $($PackagePath)                                                "
		Write-Host "==    7.Operating System:         Windows $($WindowsVersion) - $($Architecture)                  "
		Write-Host "==   	                                                                                         "
		Write-Host "================================================================================================="
		Write-Host " "
		Write-Host -ForegroundColor Green "Starting download, extract, import and driver package build process.."
		SCCMDownloadAndPackage ($PackagePath) ($RepositoryPath) ($SiteCode) ($DellProducts) ($WindowsVersion) ($Architecture) ($DownloadType) ($ImportInto)
	}
	else
	{
		Write-Host -ForegroundColor Red "SCCM Site Code could not be found"
	}
}
else
{
	if ((Test-Path -Path $ModelCSVSource) -eq $true)
	{
		$DellProducts = New-Object -TypeName System.Collections.ArrayList
		$Models = Import-Csv -Path $ModelCSVSource
		# Add model to ArrayList if not present
		if ($Models -ne $null)
		{
			foreach ($Model in $Models.Model)
			{
				if ($Model -notin $DellProducts)
				{
					$DellProducts.Add($Model) | Out-Null
				}
			}
		}
	}
	else
	{
		Write-Host -ForegroundColor Red "Unable to find the file specified."
		Break
	}
	# Start download, extract, import and package process
	Write-Host " "
	Write-Host "================================================================================================="
	Write-Host "==   	                                                                                         "
	Write-Host "==    Dell SCCM/MDT Driver Download & Import Script - By Maurice Daly                            "
	Write-Host "==   	                                                                                         "
	Write-Host "==    Running MDT only download, extract and import processes with the following variables;      "
	Write-Host "==    1.Model Source File:        $($ModelCSVSource)                                             "
	Write-Host "==    1.Driver Respository:       $($RepositoryPath)                                             "
	Write-Host "==    2.Operating System:         Windows $($WindowsVersion) - $($Architecture)                  "
	Write-Host "==   	                                                                                         "
	Write-Host "================================================================================================="
	Write-Host " "
	Write-Host -ForegroundColor Green "Starting download, extract, import and driver package build process.."
	MDTDownloadAndImport ($RepositoryPath) ($DellProducts) ($WindowsVersion) ($Architecture)	
}