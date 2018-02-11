function FindSheet([Object]$workbook, [string]$name)
	{
    	$sheetNumber = 0
    	for ($i=1; $i -le $workbook.Sheets.Count; $i++) {
        	if ($name -eq $workbook.Sheets.Item($i).Name) { $sheetNumber = $i; break }
    	}
    	return $sheetNumber
	}

	function SetActiveSheet([Object]$workbook, [string]$name)
	{
    	if (!$name) { return }
    	$sheetNumber = FindSheet $workbook $name
    	if ($sheetNumber -gt 0) { $workbook.Worksheets.Item($sheetNumber).Activate() }
    	return ($sheetNumber -gt 0)
	}


function Import-Excel([string]$FilePath, [string]$SheetName = "")
{
    $csvFile = Join-Path $env:temp ("{0}.csv" -f (Get-Item -path $FilePath).BaseName)
    if (Test-Path -path $csvFile) { Remove-Item -path $csvFile }

    # convert Excel file to CSV file
    $xlCSVType = 6 # SEE: http://msdn.microsoft.com/en-us/library/bb241279.aspx
    $excelObject = New-Object -ComObject Excel.Application  
    $excelObject.Visible = $false 
    $workbookObject = $excelObject.Workbooks.open($FilePath,1,$false,5,"dombo","dombo")
	
    SetActiveSheet $workbookObject $SheetName | Out-Null
    $workbookObject.SaveAs($csvFile,$xlCSVType) 
    $workbookObject.Saved = $true
    $workbookObject.Close()

    # cleanup 
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbookObject) | Out-Null
    $excelObject.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excelObject) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
	
	$data = Get-Content $csvFile | Select-Object -Skip 2
	$data > $csvfile
	
    # now import and return the data 
    Import-Csv -path $csvFile -Encoding Default -Delimiter ';' | Out-DataTable
}

cls
$FileName = '\\S031\Server documentatie\Overzichten NedCar Servers.xls'
$WorksheetName = 'Nedcar Servers'

$Erase = $true
$ObjectData = Import-Excel $FileName $WorksheetName
$ObjectName = 'VNB_SYSINFO_SERVERDOC'
$UDLConnection = Read-UDLConnectionString $glb_UDL

$Computername = $env:COMPUTERNAME

$new = New-VNBObjectTable -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData
Send-VNBObject -UDLConnection $UDLConnection -ObjectName $ObjectName -ObjectData $ObjectData -Computername $Computername -Erase $Erase
