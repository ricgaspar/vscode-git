clear

$column_sysname = 1
$column_confignr = 2	
$column_description = 3
$column_location = 4
$column_environment = 5
$column_PA = 6
$column_RebootSchedule = 7
$column_PatchSchedule = 8
$column_Manufacturer = 9
$column_Type = 10
$column_SerialNr = 11
$column_SerNrHPSIM = 12
$column_ProductNr = 13
$column_Processor = 14
$column_ProcessorSpeed = 15
$column_CPUcount = 16
$column_TotalMemory = 17
$column_OS = 18	
$column_Installed = 19

$rowstart = 4
$rowend = 999
$ShowExcel = $true

function IsComputerWMIAlive {
# ---------------------------------------------------------
# Check the specified system if it is
# accepting WMI connections.
# ---------------------------------------------------------
	param ( 
		[string] $Computer
	)
	if ($Computer.length -eq 0) { return $null } 
	$IsAlive = $false	
	try {
		$wmi = gwmi win32_bios -ComputerName $Computer -ErrorAction SilentlyContinue
		if ($wmi) {	$IsAlive = $true }
	}
	catch {
		$IsAlive = $false	
	}			
	return $IsAlive
}

function Search-AD-Server {
# ---------------------------------------------------------
# Search current domain
# ---------------------------------------------------------
	Param ([string]$ADSearchFilter = "(&(objectCategory=Computer)(OperatingSystem=Windows*Server*))",
         [string]$colProplist = "name"
         )
         
	$objDomain = New-Object System.DirectoryServices.DirectoryEntry
	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objSearcher.SearchRoot = $objDomain
	$objSearcher.PageSize = 5000
	$objSearcher.Filter = $ADSearchFilter      
	foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}
	$colResults = $objSearcher.FindAll()
	return $colResults
}

Function Get-ComputerAdDescription
# ---------------------------------------------------------
# Retrieve computer description from AD
# ---------------------------------------------------------
{
	Param (
		[string]$Computer 		
	)
	if ($Computer.length -eq 0) { return $null }
	# Search computer in AD 
	$colProplist = "adspath"
	$ADSearchFilter = "(&(objectCategory=Computer)(Name=$Computer))"		
	$colResults = Search-AD-Server $ADSearchFilter $colProplist
	$ADDesc = $null
	if  ($colResults.Count -eq 2) {			
		$DN = $colResults.SyncRoot[1].Path		
		$ADComp = [ADSI]$DN				
		$ADDesc = $ADComp.description.value		
	} 
	return $ADDesc.Trim()
}

Function Get-ComputerVMDescription {
# ---------------------------------------------------------
# Retrieve computer description from VCenter
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	$VM = Get-VM -Name $Computer -ErrorAction SilentlyContinue
	$VMDesc = $null
	if ($VM -ne $null) {
		$VMDesc = $VM.Description		
	}
	return $VMDesc.Trim()
}

Function Get-Manufacturer {
# ---------------------------------------------------------
# Retrieve manufacturer from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	$CompInfo = Get-WmiObject -ComputerName $Computer -Class Win32_ComputerSystem
  	foreach($info in $CompInfo) {
    	$Manufacturer = $info.Manufacturer
    	#$Model = $info.Model
  	}
	return $Manufacturer.trim()
}
				
Function Get-TypeModel { 
# ---------------------------------------------------------
# Retrieve model name from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	$CompInfo = Get-WmiObject -ComputerName $Computer -Class Win32_ComputerSystem
  	foreach($info in $CompInfo) {    	
    	$Model = $info.Model
		if ($Model.substring(0,9) -eq "ProLiant ") { $Model = $Model.substring(9) } 
  	}
	return $Model.trim()
}

Function Get-Processor { 
# ---------------------------------------------------------
# Retrieve processor type from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	$CompInfo = Get-WmiObject -ComputerName $Computer -Class Win32_Processor
  	foreach($info in $CompInfo) {
    	$Name = $info.Name
		$Name = $Name.trim()
		$temp = $Name.ToUpper()
		if ($temp.contains("INTEL")) {
			$Name = "Intel(R) "
			if ($temp.Contains("XEON")) { $Name += "Xeon(R)" } 
		}
		if ($temp.contains("AMD")) {
			$Name = "AMD "
			if ($temp.Contains("OPT")) { $Name += "Opteron(tm)" }
		}
  	}	
	return $Name
}

Function Get-ProcessorCount { 
# ---------------------------------------------------------
# Retrieve processor count from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	$count=0
	$CompInfo = Get-WmiObject -ComputerName $Computer -Class  Win32_ComputerSystem	
  	foreach($info in $CompInfo) { $count = $info.NumberOfProcessors }	
	return $count
}

Function Get-ProcessorSpeed {
# ---------------------------------------------------------
# Retrieve processor speed from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	
	$CompInfo = Get-WmiObject -ComputerName $Computer -Class Win32_Processor
  	foreach($info in $CompInfo) {
	 	$Speed = $info.MaxClockSpeed
	}
	$Speed = [math]::round($Speed/1000, 1)
	$Speed = "$Speed GHz"
	return $Speed
}

Function Get-Serial { 
# ---------------------------------------------------------
# Retrieve serial number from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }	
	$Serial= (Get-WmiObject Win32_BIOS -ComputerName $Computer).SerialNumber	
	return $Serial.trim()
}

Function Get-Memory {
# ---------------------------------------------------------
# Retrieve physical memory size from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	$strMem = "unknown"
	$CompInfo = Get-WmiObject -ComputerName $Computer -Class Win32_ComputerSystem
	foreach($info in $CompInfo) {
		$mem = $info.TotalPhysicalMemory
		$PhysMem = [math]::round($mem/1Mb)		
		if ($PhysMem -gt 1024) { 
			$PhysMem = [math]::round($mem/1Gb,1)
			$strMem = "$PhysMem" + "Gb"								
		} else {
			$strMem = "$PhysMem" + "Mb"
		}
	}	
	return $strMem
}

Function Get-InstallDate {
	Param (
		[string]$Computer
	)
	if ($Computer.length -eq 0) { return $null }
	([WMI] "").ConvertToDateTime((Get-WmiObject Win32_OperatingSystem -ComputerName $Computer).InstallDate)
}

Function Get-OS {
# ---------------------------------------------------------
# Retrieve OS from WMI
# ---------------------------------------------------------
	Param (
		[string]$Computer
	)
	$result = ""
	$version = $null
	$CompInfo = Get-WmiObject -ComputerName $Computer -Class Win32_OperatingSystem 	
  	foreach($info in $CompInfo) {
		$version = $info.Version	
		[Int64] $OSProductSuite = $info.OSProductSuite
	}
	$OSVer = $version.substring(0,3)	
	switch($OSVer) {
		"5.0" { $result = "W2K" }
		"5.1" { $result = "WinXP" } 
		"5.2" { $result = "W2K3" } 
		"6.0" { $result = "W2K8" } 
		"6.1" { $result = "W2K8 R2" } 
		default { $result = $version }
	}		
		
	$res = (($OSProductSuite -BAND 2) -eq 2)
	if ($res) { 		
		$result += " Ent" 
		if ($OSVer -eq '5.0') { $result = "W2K Adv" } 
	}
	
	$ProcInfo = Get-WmiObject -ComputerName $Computer -Class Win32_Processor
  	foreach ($proc in $ProcInfo) {
    	$Arch = $proc.AddressWidth
    }

	if ($OSVer -eq "5.2") { 
		If ( $Arch -eq "64" ) { $result += " (x64)" }
	}
	
	if ($OSVer -eq "6.0") { 
		If ( $Arch -eq "32" ) { $result += " (x86)" }
		If ( $Arch -eq "64" ) { $result += " (x64)" }
	}
	    	
	return $result
}


# ---------------------------------------------------------
# Open Excel sheet and read its contents
# ---------------------------------------------------------
$Excel = New-Object -com Excel.Application
$Excel.Visible = $ShowExcel
$Excel.DisplayAlerts=$false
# $wbk = "\\S001\ProliantServers\Overzichten NedCar Servers.xls"
$wbk = "D:\Overzichten NedCar Servers.xls"

if (Test-Path $wbk)
{
	$WorkBook = $Excel.Workbooks.open($wbk,2,$true,5,"dombo","dombo") 
	$WorkSheet = $WorkBook.Worksheets.Item("NedCar Servers") 	
	
	$row = $rowstart 	
	$sysname = $WorkSheet.Cells.Item($row,$column_sysname).Value()	
	$sysconfignr = $WorkSheet.Cells.Item($row,$column_confignr).Value()	
	
	while ($sysname -ne "xxx") {
			
		# Skip disabled systems 		
		if ($sysname -ne $sysconfignr) { 
		
			$sysdescription = $worksheet.Cells.Item($row,$column_description).Value()
			$syslocation = $worksheet.Cells.Item($row,$column_location).Value()
			$sysenvironment = $worksheet.Cells.Item($row,$column_environment).Value()
			$sysPA = $worksheet.Cells.Item($row,$column_PA).Value()
			$sysRebootSchedule = $worksheet.Cells.Item($row,$column_RebootSchedule).Value()
			$sysPatchSchedule = $worksheet.Cells.Item($row,$column_PatchSchedule).Value()
			$sysManufacturer = $worksheet.Cells.Item($row,$column_Manufacturer).Value()
			$sysType = $worksheet.Cells.Item($row,$column_Type).Value()
			$sysSerialNr = $worksheet.Cells.Item($row,$column_SerialNr).Value()
			$sysSerNrHPSIM = $worksheet.Cells.Item($row,$column_SerNrHPSIM).Value()
			$sysProductNr = $worksheet.Cells.Item($row,$column_ProductNr).Value()
			$sysProcessor = $worksheet.Cells.Item($row,$column_Processor).Value()
			$sysProcessorSpeed = $worksheet.Cells.Item($row,$column_ProcessorSpeed).Value()
			$sysCPUcount = $worksheet.Cells.Item($row,$column_CPUcount).Value()
			$sysTotalMemory = $worksheet.Cells.Item($row,$column_TotalMemory).Value()
			$sysOS = $worksheet.Cells.Item($row,$column_OS).Value()
			$sysInstalled = $worksheet.Cells.Item($row,$column_Installed).Value()
		
			Write-Host "Machine ($row) $sysname ($sysconfignr)"													
			$PingAble = IsComputerWMIAlive($sysname)
			
			if ($PingAble) {
				# Check Windows systems 
				if ($sysOS.substring(0,1) -eq 'W') {								
				
					# Check description in Active Directory
					$temp = Get-ComputerAdDescription($sysname)
					if ($temp -ne $sysdescription) { 
						Write-Host "	'$sysdescription' but computer description in AD = '$temp'"
						$worksheet.Cells.Item($row,$column_description) = $temp					
						$worksheet.Cells.Item($row,$column_description).Interior.ColorIndex = 4
					} 
				
					# Check Manufacturer
					$temp = Get-Manufacturer($sysname) 
					if ($temp -ne $sysManufacturer) { 
						Write-Host "	'$sysManufacturer' but WMI manufacturer = '$temp'"
						$worksheet.Cells.Item($row,$column_Manufacturer) = $temp
						$worksheet.Cells.Item($row,$column_Manufacturer).Interior.ColorIndex = 4
					}
				
					# Check model/type 
					$temp = Get-TypeModel($sysname) 
					if ($temp -ne $sysType) { 
						Write-Host "	'$sysType' but WMI type/model = '$temp'"
						$worksheet.Cells.Item($row,$column_Type) = $temp
						$worksheet.Cells.Item($row,$column_Type).Interior.ColorIndex = 4
					}	
				
					# check processor 
					$temp =  Get-Processor($sysname)
					if ($temp -ne $sysProcessor) { 
						Write-Host "	'$sysProcessor' but WMI processor type = '$temp'"
						$worksheet.Cells.Item($row,$column_Processor) = $temp
						$worksheet.Cells.Item($row,$column_Processor).Interior.ColorIndex = 4
					}
					
					$temp = Get-ProcessorCount($sysname)
					if ($temp -ne $sysCPUcount) { 
						Write-Host "	'$sysCPUcount' but WMI processor count = '$temp'"
						$worksheet.Cells.Item($row,$column_CPUcount) = $temp
						$worksheet.Cells.Item($row,$column_CPUcount).Interior.ColorIndex = 4
					}
					
					# check processor speed 
					$temp = Get-ProcessorSpeed($sysname)
					if ($temp -ne $sysProcessorSpeed) {
						Write-Host "	'$sysProcessorSpeed' but WMI processor speed = '$temp'"
						$worksheet.Cells.Item($row,$column_ProcessorSpeed) = $temp
						$worksheet.Cells.Item($row,$column_ProcessorSpeed).Interior.ColorIndex = 4
					}
				
					if ($sysconfignr.Substring(0,3) -ne 'ESX') {
						# Check serial number (physical machines only)
						$temp = Get-Serial($sysname) 
						if ($temp -ne $sysSerialNr) { 
							Write-Host "	'$sysSerialNr' but WMI serial number = '$temp'"
							$worksheet.Cells.Item($row,$column_SerialNr) = $temp
							$worksheet.Cells.Item($row,$column_SerialNr).Interior.ColorIndex = 4
						}						
					}				
				
					$temp = Get-Memory($sysname)
					if ($temp -ne $sysTotalMemory) {
						Write-Host "	'$sysTotalMemory' but WMI memory size = '$temp'"
						$worksheet.Cells.Item($row,$column_TotalMemory) = $temp
						$worksheet.Cells.Item($row,$column_TotalMemory).Interior.ColorIndex = 4
					}
				
					$temp = Get-OS($sysname)
					if ($temp -ne $sysOS) {
						Write-Host "	'$sysOS' but WMI operating system = '$temp'"
						$worksheet.Cells.Item($row,$column_OS) = $temp
						$worksheet.Cells.Item($row,$column_OS).Interior.ColorIndex = 4
					}
					
					# Install Date is niet gebruikt. Bij herinrichting overschrijft dit namelijk ook de aanschaf/plaats datum van fysieke servers.
					# $temp = Get-InstallDate($sysname)
					# if ($temp -ne $sysInstalled) {
					#	Write-Host "	'$sysInstalled' but WMI installed date = '$temp'"
					#	$worksheet.Cells.Item($row,$column_Installed) = $temp
					#	$worksheet.Cells.Item($row,$column_Installed).Interior.ColorIndex = 4
					# }
				}
			} else {
				Write-Host "	Computer is not accepting WMI connections."
			}
		}			
		
		$row++
		$sysname = $WorkSheet.Cells.Item($row,$column_sysname).Value()	
		$sysconfignr = $WorkSheet.Cells.Item($row,$column_confignr).Value()
		
		if ($row -gt $rowend) { $sysname = "xxx" } 
	}		
	
	$WorkBook.SaveAs('D:\Test.xls')
}

$WorkBook = $Null
$WorkSheet = $Null
$Excel = $Null

<# Kill Excel or otherwise it will keep running in the background #>
spps -n excel 


