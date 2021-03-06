cls

$RefServerName = 'vs047'
$DiffServerName = 'vs046'

$DiffServerPrinters = Get-CimInstance -ComputerName $DiffServerName -Class 'WIN32_PRINTER' -Property 'Name'
$RefServerPrinters = Get-CimInstance -ComputerName $RefServerName -Class 'WIN32_PRINTER' -Property 'Name'

$DiffServerPrinterNames = $DiffServerPrinters | Sort-Object Name | Select -ExpandProperty 'Name'
$RefServerPrinterNames = $RefServerPrinters | Sort-Object Name | Select -ExpandProperty 'Name' 
$DiffObjects = Compare-Object -ReferenceObject $RefServerPrinterNames -DifferenceObject $DiffServerPrinterNames
foreach($PrnObj in $DiffObjects) { 
	$Printername = $PrnObj.InputObject
	$Indicator = $PrnObj.SideIndicator	
	if($Indicator -eq '<=') { Write-Host "Missing printer on $DiffServerName : $Printername" }
	if($Indicator -eq '=>') { Write-Host "Missing printer on $RefServerName : $Printername" }
}

$CimClass = 'WIN32_PRINTERCONFIGURATION'
$RefConfigCSV = "C:\Temp\$RefServerName-printerconfiguration.csv"
$RefPrns = Get-CimInstance -Computername $RefServerName -Query "SELECT * FROM $CimClass" -ErrorAction SilentlyContinue
$RefPrns | Sort-Object -Property 'Name' | Select Caption,Description,SettingID,BitsPerPel,Collate,Color,Copies,DeviceName,DisplayFlags,DisplayFrequency,DitherType,DriverVersion,Duplex,FormName,HorizontalResolution,ICMIntent,ICMMethod,LogPixels,MediaType,Name,Orientation,PaperLength,PaperSize,PaperWidth,PelsHeight,PelsWidth,PrintQuality,Scale,SpecificationVersion,TTOption,VerticalResolution,XResolution,YResolution | Export-Csv $RefConfigCSV -Delimiter ';'

$DifConfigCSV = "C:\Temp\$DiffServerName-printerconfiguration.csv"
$DifPrns = Get-CimInstance -Computername $DiffServerName -Query "SELECT * FROM $CimClass" -ErrorAction SilentlyContinue
$DifPrns | Sort-Object -Property 'Name' | Select Caption,Description,SettingID,BitsPerPel,Collate,Color,Copies,DeviceName,DisplayFlags,DisplayFrequency,DitherType,DriverVersion,Duplex,FormName,HorizontalResolution,ICMIntent,ICMMethod,LogPixels,MediaType,Name,Orientation,PaperLength,PaperSize,PaperWidth,PelsHeight,PelsWidth,PrintQuality,Scale,SpecificationVersion,TTOption,VerticalResolution,XResolution,YResolution| Export-Csv $DifConfigCSV -Delimiter ';'

$DiffObjects = Compare-Object -ReferenceObject (Get-Content $RefConfigCSV) -DifferenceObject (Get-Content $DifConfigCSV)
foreach($PrnObj in $DiffObjects) {
	$CSV = $PrnObj.InputObject
	$ObjectList = $CSV -split ';'
	$ObjectName = $ObjectList[0]	
	$Indicator = $PrnObj.SideIndicator	
	if($Indicator -eq '<=') { Write-Host "Configuration mismatch on $DiffServerName on printer $ObjectName" }
	if($Indicator -eq '=>') { Write-Host "Configuration mismatch on $RefServerName on printer $ObjectName" }
}

$CimClass = 'WIN32_PRINTERDRIVER'
$RefConfigCSV = "C:\Temp\$RefServerName-printerdriver.csv"
$RefPrns = Get-CimInstance -Computername $RefServerName -Query "SELECT * FROM $CimClass" -ErrorAction SilentlyContinue
$RefPrns | Sort-Object -Property 'Name' | Select Caption,Description,InstallDate,Name,Status,CreationClassName,Started,StartMode,SystemCreationClassName,SystemName,ConfigFile,DataFile,DefaultDataType,DependentFiles,DriverPath,FilePath,HelpFile,InfName,MonitorName,OEMUrl,SupportedPlatform,Version | Export-Csv $RefConfigCSV -Delimiter ';'

$DifConfigCSV = "C:\Temp\$DiffServerName-printerdriver.csv"
$DifPrns = Get-CimInstance -Computername $DiffServerName -Query "SELECT * FROM $CimClass" -ErrorAction SilentlyContinue
$DifPrns | Sort-Object -Property 'Name' | Select Caption,Description,InstallDate,Name,Status,CreationClassName,Started,StartMode,SystemCreationClassName,SystemName,ConfigFile,DataFile,DefaultDataType,DependentFiles,DriverPath,FilePath,HelpFile,InfName,MonitorName,OEMUrl,SupportedPlatform,Version | Export-Csv $DifConfigCSV -Delimiter ';'

$DiffObjects = Compare-Object -ReferenceObject (Get-Content $RefConfigCSV) -DifferenceObject (Get-Content $DifConfigCSV)
foreach($PrnObj in $DiffObjects) {
	$CSV = $PrnObj.InputObject
	$ObjectList = $CSV -split ';'
	$ObjectName = $ObjectList[3]	
	$Indicator = $PrnObj.SideIndicator	
	if($Indicator -eq '<=') { Write-Host "Configuration mismatch on $DiffServerName on printer driver $ObjectName"	}
	if($Indicator -eq '=>') { Write-Host "Configuration mismatch on $RefServerName on printer driver $ObjectName"	}
}

$RefDrivers = @()
$DiffDrivers = @()
foreach($Driver in $RefPrns) {
	$DriverPath = $Driver.DriverPath
	$RefDriverPath = $DriverPath -replace 'C:', ('\\'+$RefServerName+'\C$')
	if(Test-path $RefDriverPath) { 
		$RefDriverVersionInfo = (Get-Item $RefDriverPath -ErrorAction SilentlyContinue).VersionInfo 
	} else {
		$RefDriverVersionInfo = $null
	}
	$RefProductVersion = [String]$RefDriverVersionInfo.ProductVersion
	$RefFileVersion = [String]$RefDriverVersionInfo.FileMajorPart + '.' + `
		[String]$RefDriverVersionInfo.FileMinorPart + '.' + `
		[String]$RefDriverVersionInfo.FileBuildPart + '.' + `
		[String]$RefDriverVersionInfo.FilePrivatePart
	
	$object = New-Object PSObject
	Add-Member -InputObject $object –MemberType NoteProperty –Name Name –Value $($Driver.Name)
	Add-Member -InputObject $object –MemberType NoteProperty –Name DriverPath –Value $RefDriverPath
	Add-Member -InputObject $object –MemberType NoteProperty –Name ProductVersion –Value $RefProductVersion
	Add-Member -InputObject $object –MemberType NoteProperty –Name FileVersion –Value $RefFileVersion	
	$RefDrivers += $object
	
	$DiffDriverPath = $DriverPath -replace 'C:', ('\\'+$DiffServerName+'\C$')
	if(Test-path $DiffDriverPath) { 
		$DiffDriverVersionInfo = (Get-Item $DiffDriverPath -ErrorAction SilentlyContinue).VersionInfo
	} else {
		$DiffDriverVersionInfo = $null
	}
	$DiffProductVersion = [String]$DiffDriverVersionInfo.ProductVersion
	$DiffFileVersion = [String]$DiffDriverVersionInfo.FileMajorPart + '.' + `
		[String]$DiffDriverVersionInfo.FileMinorPart + '.' + `
		[String]$DiffDriverVersionInfo.FileBuildPart + '.' + `
		[String]$DiffDriverVersionInfo.FilePrivatePart
	
	$object = New-Object PSObject
	Add-Member -InputObject $object –MemberType NoteProperty –Name Name –Value $($Driver.Name)
	Add-Member -InputObject $object –MemberType NoteProperty –Name DriverPath –Value $DiffDriverPath
	Add-Member -InputObject $object –MemberType NoteProperty –Name ProductVersion –Value $DiffProductVersion
	Add-Member -InputObject $object –MemberType NoteProperty –Name FileVersion –Value $DiffFileVersion	
	$DiffDrivers += $object	
}
$RefDriversCSV = "C:\Temp\$RefServerName-printerdriverversion.csv"
$RefDrivers | Sort-Object -Property 'Name' | Export-Csv $RefDriversCSV -Delimiter ';'
$DiffDriversCSV = "C:\Temp\$DiffServerName-printerdriverversion.csv"
$DiffDrivers | Sort-Object -Property 'Name' | Export-Csv $DiffDriversCSV -Delimiter ';'

$DiffObjects = Compare-Object -ReferenceObject (Get-Content $RefDriversCSV) -DifferenceObject (Get-Content $DiffDriversCSV)
$DiffObjects